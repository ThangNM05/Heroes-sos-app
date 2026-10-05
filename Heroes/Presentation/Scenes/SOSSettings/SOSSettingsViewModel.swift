import Foundation
import Combine

@MainActor
final class SOSSettingsViewModel: BaseViewModel, ISOSSettingsViewModel {
    @Published var settings: SOSSettings = SOSSettings()
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var invitations: [EmergencyInvitation] = []
    @Published var isSaving: Bool = false
    @Published var saveSuccessToast: Bool = false
    @Published var actionMessage: String?
    @Published var latestInviteLink: ContactInviteLink?

    private let sosService: ISOSService
    private let emergencyContactsRepository: IEmergencyContactsRepository

    init(sosService: ISOSService, emergencyContactsRepository: IEmergencyContactsRepository) {
        self.sosService = sosService
        self.emergencyContactsRepository = emergencyContactsRepository
        super.init()
    }

    convenience init(sosService: ISOSService) {
        self.init(
            sosService: sosService,
            emergencyContactsRepository: EmergencyContactsRepository(networkClient: NetworkClient())
        )
    }

    func loadSettingsAndContacts(session: AppSessionStore, mode: EmergencyNetworkView.Mode = .manage) {
        settings = sosService.getSettings()
        run {
            switch mode {
            case .manage:
                self.emergencyContacts = try await session.performAuthenticatedRequest {
                    try await self.emergencyContactsRepository.fetchContacts(accessToken: $0)
                }
            case .connections:
                self.invitations = try await session.performAuthenticatedRequest {
                    try await self.emergencyContactsRepository.fetchInvitations(accessToken: $0)
                }
            }
        }
    }

    func updateUserRole(_ role: HEROSUserRole) {
        settings.userRole = role
        saveSettings()
    }

    func updateRecipientMode(_ mode: SOSRecipientMode) {
        settings.recipientMode = mode
        saveSettings()
    }

    func createContact(draft: EmergencyContactDraft, shouldIssueLink: Bool, session: AppSessionStore) {
        guard emergencyContacts.count < 10 else {
            errorMessage = "Bạn chỉ có thể thêm tối đa 10 người thân."
            return
        }
        guard !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Vui lòng nhập tên người thân."
            return
        }

        run {
            var contact = try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.createContact(draft, accessToken: $0)
            }
            if shouldIssueLink {
                let email = draft.email.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !email.isEmpty else { throw EmergencyNetworkValidationError.missingInviteEmail }
                let invite = try await session.performAuthenticatedRequest {
                    try await self.emergencyContactsRepository.issueInvite(
                        contactId: contact.id,
                        email: email,
                        accessToken: $0
                    )
                }
                contact.inviteCode = invite.inviteCode
                contact.inviteURL = invite.inviteURL
                contact.inviteExpiresAt = invite.expiresAt
                contact.invitationStatus = .pending
                self.latestInviteLink = invite
            }
            self.emergencyContacts = try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.fetchContacts(accessToken: $0)
            }
            self.actionMessage = shouldIssueLink ? "Đã tạo lời mời. Bạn có thể chia sẻ liên kết ngay." : "Đã gửi lời mời trong ứng dụng."
        }
    }

    func updateContact(id: String, draft: EmergencyContactDraft, session: AppSessionStore) {
        run {
            _ = try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.updateContact(id: id, draft: draft, accessToken: $0)
            }
            self.emergencyContacts = try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.fetchContacts(accessToken: $0)
            }
            self.actionMessage = "Đã cập nhật người thân."
        }
    }

    func deleteContact(id: String, session: AppSessionStore) {
        run {
            try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.deleteContact(id: id, accessToken: $0)
            }
            self.emergencyContacts.removeAll { $0.id == id }
            self.relationshipDidChange()
            self.actionMessage = "Đã hủy liên kết."
        }
    }

    func issueInvite(contact: EmergencyContact, session: AppSessionStore) {
        guard let email = contact.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            errorMessage = "Hãy cập nhật email người thân trước khi tạo liên kết."
            return
        }
        run {
            let invite = try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.issueInvite(
                    contactId: contact.id,
                    email: email,
                    accessToken: $0
                )
            }
            self.latestInviteLink = invite
            if let index = self.emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
                self.emergencyContacts[index].inviteCode = invite.inviteCode
                self.emergencyContacts[index].inviteURL = invite.inviteURL
                self.emergencyContacts[index].inviteExpiresAt = invite.expiresAt
                self.emergencyContacts[index].invitationStatus = .pending
            }
            self.actionMessage = "Đã tạo mã mới; mã lời mời cũ không còn hiệu lực."
        }
    }

    func revokeInvite(contactId: String, session: AppSessionStore) {
        run {
            try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.revokeInvite(contactId: contactId, accessToken: $0)
            }
            if let index = self.emergencyContacts.firstIndex(where: { $0.id == contactId }) {
                self.emergencyContacts[index].invitationStatus = .revoked
                self.emergencyContacts[index].inviteCode = nil
                self.emergencyContacts[index].inviteURL = nil
                self.emergencyContacts[index].inviteExpiresAt = nil
            }
            self.actionMessage = "Đã thu hồi lời mời."
        }
    }

    func acceptInvitation(id: String, session: AppSessionStore) {
        invitationAction(id: id, session: session) { repository, token in
            try await repository.acceptInvitation(id: id, accessToken: token)
        }
    }

    func declineInvitation(id: String, session: AppSessionStore) {
        invitationAction(id: id, session: session) { repository, token in
            try await repository.declineInvitation(id: id, accessToken: token)
        }
    }

    func unlinkInvitation(id: String, session: AppSessionStore) {
        run {
            try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.unlinkInvitation(id: id, accessToken: $0)
            }
            self.invitations.removeAll { $0.id == id }
            self.relationshipDidChange()
            self.actionMessage = "Đã hủy liên kết và thu hồi quyền truy cập SOS."
        }
    }

    func acceptInviteCode(_ value: String, session: AppSessionStore) {
        guard let code = ContactInviteURLParser.normalize(value) else {
            errorMessage = "Mã lời mời phải gồm 32 ký tự hexadecimal."
            return
        }
        run {
            try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.acceptInviteCode(code, accessToken: $0)
            }
            self.invitations = try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.fetchInvitations(accessToken: $0)
            }
            self.relationshipDidChange()
            self.actionMessage = "Đã kết nối với người thân."
        }
    }

    func saveSettings() {
        sosService.updateSettings(settings)
        saveSuccessToast = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            saveSuccessToast = false
        }
    }

    private func invitationAction(
        id: String,
        session: AppSessionStore,
        action: @escaping (IEmergencyContactsRepository, String) async throws -> Void
    ) {
        run {
            try await session.performAuthenticatedRequest {
                try await action(self.emergencyContactsRepository, $0)
            }
            self.invitations = try await session.performAuthenticatedRequest {
                try await self.emergencyContactsRepository.fetchInvitations(accessToken: $0)
            }
            self.relationshipDidChange()
        }
    }

    private func relationshipDidChange() {
        SecureAudioCache.clear()
        NotificationCenter.default.post(name: .emergencyRelationshipsDidChange, object: nil)
    }

    private func run(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                try await operation()
            } catch {
                handleError(error)
            }
        }
    }
}

private enum EmergencyNetworkValidationError: LocalizedError {
    case missingInviteEmail
    var errorDescription: String? { "Vui lòng nhập email để tạo liên kết lời mời." }
}
