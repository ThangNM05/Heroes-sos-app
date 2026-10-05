import Foundation
import Moya
import Alamofire

final class EmergencyContactsRepository: IEmergencyContactsRepository {
    private let networkClient: INetworkClient

    init(networkClient: INetworkClient) {
        self.networkClient = networkClient
    }

    func fetchContacts(accessToken: String) async throws -> [EmergencyContact] {
        let payload: EmergencyContactsPayload = try await networkClient.requestEnvelope(
            path: "/emergency-contacts",
            headers: APIHeaders.json(accessToken: accessToken)
        )
        return payload.items.map(\.domain)
    }

    func createContact(_ draft: EmergencyContactDraft, accessToken: String) async throws -> EmergencyContact {
        let response: EmergencyContactDTO = try await networkClient.requestEnvelope(
            path: "/emergency-contacts",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: ContactBody(draft: draft)
        )
        return response.domain
    }

    func updateContact(id: String, draft: EmergencyContactDraft, accessToken: String) async throws -> EmergencyContact {
        let response: EmergencyContactDTO = try await networkClient.requestEnvelope(
            path: "/emergency-contacts/\(id.pathComponent)",
            method: .patch,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: ContactBody(draft: draft)
        )
        return response.domain
    }

    func deleteContact(id: String, accessToken: String) async throws {
        let _: DiscardedAPIData = try await networkClient.requestEnvelope(
            path: "/emergency-contacts/\(id.pathComponent)",
            method: .delete,
            headers: APIHeaders.json(accessToken: accessToken)
        )
    }

    func fetchInvitations(accessToken: String) async throws -> [EmergencyInvitation] {
        let payload: EmergencyInvitationsPayload = try await networkClient.requestEnvelope(
            path: "/emergency-contacts/invitations",
            headers: APIHeaders.json(accessToken: accessToken)
        )
        return payload.items.map(\.domain)
    }

    func acceptInvitation(id: String, accessToken: String) async throws {
        try await invitationAction(id: id, action: "accept", method: .post, accessToken: accessToken)
    }

    func declineInvitation(id: String, accessToken: String) async throws {
        try await invitationAction(id: id, action: "decline", method: .post, accessToken: accessToken)
    }

    func unlinkInvitation(id: String, accessToken: String) async throws {
        try await invitationAction(id: id, action: "link", method: .delete, accessToken: accessToken)
    }

    func acceptInviteCode(_ code: String, accessToken: String) async throws {
        let _: DiscardedAPIData = try await networkClient.requestEnvelope(
            path: "/contact-invites/accept",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: AcceptInviteBody(code: code)
        )
    }

    func issueInvite(contactId: String, email: String, accessToken: String) async throws -> ContactInviteLink {
        let response: ContactInviteLinkDTO = try await networkClient.requestEnvelope(
            path: "/contact-invites/\(contactId.pathComponent)",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: IssueInviteBody(email: email)
        )
        return response.domain
    }

    func revokeInvite(contactId: String, accessToken: String) async throws {
        let _: DiscardedAPIData = try await networkClient.requestEnvelope(
            path: "/contact-invites/\(contactId.pathComponent)",
            method: .delete,
            headers: APIHeaders.json(accessToken: accessToken)
        )
    }

    private func invitationAction(
        id: String,
        action: String,
        method: Moya.Method,
        accessToken: String
    ) async throws {
        let _: DiscardedAPIData = try await networkClient.requestEnvelope(
            path: "/emergency-contacts/invitations/\(id.pathComponent)/\(action)",
            method: method,
            headers: APIHeaders.json(accessToken: accessToken)
        )
    }
}

private struct ContactBody: Encodable {
    let name: String
    let phone: String?
    let email: String?
    let relationship: String?
    let priority: Int
    let emailEnabled: Bool
    let pushEnabled: Bool
    let linkedUserEmail: String?

    init(draft: EmergencyContactDraft) {
        name = draft.name.trimmed
        phone = draft.phone.nilIfBlank
        email = draft.email.nilIfBlank
        relationship = draft.relationship.nilIfBlank
        priority = draft.priority
        emailEnabled = draft.emailEnabled
        pushEnabled = draft.pushEnabled
        linkedUserEmail = draft.linkedUserEmail?.nilIfBlank
    }
}

private struct AcceptInviteBody: Encodable { let code: String }
private struct IssueInviteBody: Encodable { let email: String }

private struct EmergencyContactsPayload: Decodable {
    let items: [EmergencyContactDTO]

    private enum CodingKeys: String, CodingKey { case contacts, items }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([EmergencyContactDTO].self) {
            items = array
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([EmergencyContactDTO].self, forKey: .contacts)
            ?? container.decodeIfPresent([EmergencyContactDTO].self, forKey: .items)
            ?? []
    }
}

private struct EmergencyInvitationsPayload: Decodable {
    let items: [EmergencyInvitationDTO]

    private enum CodingKeys: String, CodingKey { case invitations, items }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([EmergencyInvitationDTO].self) {
            items = array
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([EmergencyInvitationDTO].self, forKey: .invitations)
            ?? container.decodeIfPresent([EmergencyInvitationDTO].self, forKey: .items)
            ?? []
    }
}

private struct EmergencyContactDTO: Decodable {
    let id: String
    let name: String
    let relationship: String?
    let phone: String?
    let email: String?
    let avatarUrl: String?
    let priority: Int?
    let emailEnabled: Bool?
    let pushEnabled: Bool?
    let linkedUserEmail: String?
    let invitationStatus: String?
    let inviteCode: String?
    let inviteUrl: String?
    let expiresAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, mongoID = "_id", name, relationship, phone, phoneNumber, email, avatarUrl
        case priority, priorityOrder, emailEnabled, pushEnabled, linkedUserEmail, invitationStatus
        case inviteCode, inviteUrl, expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoID)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Người thân"
        relationship = try container.decodeIfPresent(String.self, forKey: .relationship)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
            ?? container.decodeIfPresent(String.self, forKey: .phoneNumber)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)
            ?? container.decodeIfPresent(Int.self, forKey: .priorityOrder)
        emailEnabled = try container.decodeIfPresent(Bool.self, forKey: .emailEnabled)
        pushEnabled = try container.decodeIfPresent(Bool.self, forKey: .pushEnabled)
        linkedUserEmail = try container.decodeIfPresent(String.self, forKey: .linkedUserEmail)
        invitationStatus = try container.decodeIfPresent(String.self, forKey: .invitationStatus)
        inviteCode = try container.decodeIfPresent(String.self, forKey: .inviteCode)
        inviteUrl = try container.decodeIfPresent(String.self, forKey: .inviteUrl)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    var domain: EmergencyContact {
        EmergencyContact(
            id: id,
            name: name,
            relationship: relationship?.nilIfBlank ?? "Người thân",
            phoneNumber: phone ?? email ?? "Chưa có số điện thoại",
            avatarUrl: avatarUrl,
            priorityOrder: priority ?? 0,
            isTrusted: invitationStatus?.lowercased() == "accepted",
            isNotifiedViaSMS: emailEnabled ?? true,
            isNotifiedViaCall: pushEnabled ?? true,
            invitationStatus: EmergencyContact.InvitationStatus(apiValue: invitationStatus),
            email: email,
            linkedUserEmail: linkedUserEmail,
            inviteCode: inviteCode,
            inviteURL: inviteUrl,
            inviteExpiresAt: expiresAt
        )
    }
}

private struct EmergencyInvitationDTO: Decodable {
    let id: String
    let ownerName: String?
    let ownerEmail: String?
    let ownerAvatarURL: String?
    let name: String?
    let relationship: String?
    let invitationStatus: String?
    let createdAt: Date?

    private struct Owner: Decodable {
        let fullName: String?
        let name: String?
        let email: String?
        let avatarUrl: String?
    }

    private enum CodingKeys: String, CodingKey {
        case id, mongoID = "_id", owner, ownerId, ownerName, ownerEmail, ownerAvatarURL = "ownerAvatarUrl"
        case name, relationship, invitationStatus, status, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let owner = try container.decodeIfPresent(Owner.self, forKey: .owner)
            ?? container.decodeIfPresent(Owner.self, forKey: .ownerId)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoID)
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName)
            ?? owner?.fullName ?? owner?.name
        ownerEmail = try container.decodeIfPresent(String.self, forKey: .ownerEmail) ?? owner?.email
        ownerAvatarURL = try container.decodeIfPresent(String.self, forKey: .ownerAvatarURL) ?? owner?.avatarUrl
        name = try container.decodeIfPresent(String.self, forKey: .name)
        relationship = try container.decodeIfPresent(String.self, forKey: .relationship)
        invitationStatus = try container.decodeIfPresent(String.self, forKey: .invitationStatus)
            ?? container.decodeIfPresent(String.self, forKey: .status)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    var domain: EmergencyInvitation {
        EmergencyInvitation(
            id: id,
            ownerName: ownerName ?? name ?? "Người dùng HEROS",
            ownerEmail: ownerEmail,
            ownerAvatarURL: ownerAvatarURL,
            relationship: relationship?.nilIfBlank ?? "Người thân",
            status: EmergencyContact.InvitationStatus(apiValue: invitationStatus),
            createdAt: createdAt
        )
    }
}

private struct ContactInviteLinkDTO: Decodable {
    let contactId: String
    let inviteCode: String
    let inviteUrl: String
    let expiresAt: Date

    var domain: ContactInviteLink {
        ContactInviteLink(contactId: contactId, inviteCode: inviteCode, inviteURL: inviteUrl, expiresAt: expiresAt)
    }
}

private struct DiscardedAPIData: Decodable {
    init(from decoder: Decoder) throws {}
}

private extension EmergencyContact.InvitationStatus {
    init(apiValue: String?) {
        switch apiValue?.lowercased() {
        case "pending", "invited", "unlinked": self = .pending
        case "expired": self = .expired
        case "revoked": self = .revoked
        case "declined": self = .declined
        default: self = .accepted
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfBlank: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
    var pathComponent: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
}
