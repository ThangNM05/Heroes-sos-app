import Foundation

protocol IEmergencyContactsRepository: AnyObject {
    func fetchContacts(accessToken: String) async throws -> [EmergencyContact]
    func createContact(_ draft: EmergencyContactDraft, accessToken: String) async throws -> EmergencyContact
    func updateContact(id: String, draft: EmergencyContactDraft, accessToken: String) async throws -> EmergencyContact
    func deleteContact(id: String, accessToken: String) async throws

    func fetchInvitations(accessToken: String) async throws -> [EmergencyInvitation]
    func acceptInvitation(id: String, accessToken: String) async throws
    func declineInvitation(id: String, accessToken: String) async throws
    func unlinkInvitation(id: String, accessToken: String) async throws

    func acceptInviteCode(_ code: String, accessToken: String) async throws
    func issueInvite(contactId: String, email: String, accessToken: String) async throws -> ContactInviteLink
    func revokeInvite(contactId: String, accessToken: String) async throws
}
