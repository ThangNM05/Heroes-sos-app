import SwiftUI

struct EmergencyNetworkView: View {
    enum Mode { case manage, connections }

    @EnvironmentObject private var session: AppSessionStore
    let mode: Mode
    @StateObject private var viewModel: SOSSettingsViewModel
    @State private var showingAddContact = false
    @State private var editingContact: EmergencyContact?
    @State private var inviteCode = ""

    init(mode: Mode = .manage, viewModel: SOSSettingsViewModel? = nil) {
        self.mode = mode
        _viewModel = StateObject(
            wrappedValue: viewModel ?? SOSSettingsViewModel(
                sosService: AppDIContainer.shared.resolve(),
                emergencyContactsRepository: AppDIContainer.shared.resolve()
            )
        )
    }

    var body: some View {
        Group {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        if mode == .manage {
                            ownerSummary
                            if let invite = viewModel.latestInviteLink { shareInviteCard(invite) }
                            ownerContacts
                        } else {
                            manualCodeCard
                            incomingInvitations
                        }

                        if viewModel.isLoading { ProgressView().tint(Theme.Colors.primaryColor).padding() }
                        messageArea
                    }
                    .padding(18)
                }
            }
            .navigationTitle(mode == .manage ? "Mạng lưới khẩn cấp" : "Người thân của tôi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if mode == .manage {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAddContact = true } label: { Image(systemName: "person.badge.plus") }
                            .disabled(viewModel.emergencyContacts.count >= 10 || viewModel.isLoading)
                    }
                }
            }
            .refreshable { viewModel.loadSettingsAndContacts(session: session, mode: mode) }
            .onAppear { viewModel.loadSettingsAndContacts(session: session, mode: mode) }
            .sheet(isPresented: $showingAddContact) {
                ContactEditorView(mode: .create) { draft, issueLink in
                    viewModel.createContact(draft: draft, shouldIssueLink: issueLink, session: session)
                }
            }
            .sheet(item: $editingContact) { contact in
                ContactEditorView(mode: .edit(contact)) { draft, _ in
                    viewModel.updateContact(id: contact.id, draft: draft, session: session)
                }
            }
        }
    }

    private var ownerSummary: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .foregroundColor(Theme.Colors.primaryColor)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.softPink)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("\(viewModel.emergencyContacts.count)/10 người")
                    .font(Theme.Fonts.bold.swiftUI(size: 15))
                Text("Thêm người thân để được hỗ trợ kịp thời hơn.")
                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
            }
            Spacer()
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var ownerContacts: some View {
        VStack(spacing: 10) {
            if viewModel.emergencyContacts.isEmpty && !viewModel.isLoading {
                emptyState(icon: "person.badge.plus", text: "Chưa có người thân trong mạng lưới")
            }
            ForEach(viewModel.emergencyContacts) { contact in
                contactRow(contact)
            }
        }
    }

    private func contactRow(_ contact: EmergencyContact) -> some View {
        HStack(spacing: 12) {
            UserAvatarView(urlString: contact.avatarUrl, initials: String(contact.name.prefix(1)), size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(contact.name).font(Theme.Fonts.bold.swiftUI(size: 14))
                Text(contact.relationship + " • " + (contact.email ?? contact.phoneNumber))
                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
                    .lineLimit(1)
                Text(contact.invitationStatus.rawValue)
                    .font(Theme.Fonts.semiBold.swiftUI(size: 10))
                    .foregroundColor(contact.invitationStatus == .accepted ? Theme.Colors.greenColor : Theme.Colors.amberColor)
            }
            Spacer()
            Menu {
                Button { editingContact = contact } label: { Label("Chỉnh sửa", systemImage: "pencil") }

                if let value = contact.inviteURL, let url = URL(string: value) {
                    ShareLink(item: url) { Label("Chia sẻ lời mời", systemImage: "square.and.arrow.up") }
                } else if contact.invitationStatus != .accepted {
                    Button { viewModel.issueInvite(contact: contact, session: session) } label: {
                        Label("Tạo lại lời mời", systemImage: "arrow.clockwise")
                    }
                }

                if contact.invitationStatus == .pending {
                    Button(role: .destructive) { viewModel.revokeInvite(contactId: contact.id, session: session) } label: {
                        Label("Thu hồi lời mời", systemImage: "xmark.circle")
                    }
                }

                Button(role: .destructive) { viewModel.deleteContact(id: contact.id, session: session) } label: {
                    Label("Hủy liên kết", systemImage: "person.crop.circle.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis").foregroundColor(Theme.Colors.textSecondaryColor).padding(8)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(15)
    }

    private func shareInviteCard(_ invite: ContactInviteLink) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Lời mời đã sẵn sàng", systemImage: "link")
                .font(Theme.Fonts.bold.swiftUI(size: 14))
            Text("Hết hạn \(invite.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                .font(Theme.Fonts.regular.swiftUI(size: 11))
                .foregroundColor(Theme.Colors.textSecondaryColor)
            if let url = URL(string: invite.inviteURL) {
                ShareLink(item: url, message: Text("Mời bạn tham gia mạng lưới khẩn cấp HEROS của tôi.")) {
                    Label("Chia sẻ liên kết", systemImage: "square.and.arrow.up")
                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Theme.Colors.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(15)
        .background(Theme.Colors.softPink)
        .cornerRadius(16)
    }

    private var manualCodeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nhập mã lời mời").font(Theme.Fonts.bold.swiftUI(size: 14))
            HStack(spacing: 8) {
                TextField("32 ký tự", text: $inviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 12, design: .monospaced))
                    .padding(11)
                    .background(Color(Theme.Colors.bgColor))
                    .cornerRadius(10)
                Button("Xác nhận") {
                    viewModel.acceptInviteCode(inviteCode, session: session)
                    inviteCode = ""
                }
                .font(Theme.Fonts.bold.swiftUI(size: 12))
                .disabled(ContactInviteURLParser.normalize(inviteCode) == nil || viewModel.isLoading)
            }
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var incomingInvitations: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lời mời trong ứng dụng").font(Theme.Fonts.bold.swiftUI(size: 15))
            if viewModel.invitations.isEmpty && !viewModel.isLoading {
                emptyState(icon: "tray", text: "Không có lời mời mới")
            }
            ForEach(viewModel.invitations) { invitation in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 11) {
                        UserAvatarView(
                            urlString: invitation.ownerAvatarURL,
                            initials: String(invitation.ownerName.prefix(1)),
                            size: 42
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(invitation.ownerName).font(Theme.Fonts.bold.swiftUI(size: 14))
                            Text(invitation.relationship).font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
                        }
                        Spacer()
                    }

                    if invitation.status == .pending {
                        HStack(spacing: 8) {
                            Button("Từ chối") { viewModel.declineInvitation(id: invitation.id, session: session) }
                                .buttonStyle(.bordered)
                            Button("Chấp nhận") { viewModel.acceptInvitation(id: invitation.id, session: session) }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.Colors.primaryColor)
                        }
                        .font(Theme.Fonts.semiBold.swiftUI(size: 12))
                    } else if invitation.status == .accepted {
                        Button("Hủy liên kết", role: .destructive) {
                            viewModel.unlinkInvitation(id: invitation.id, session: session)
                        }
                        .font(Theme.Fonts.semiBold.swiftUI(size: 12))
                    }
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(15)
            }
        }
    }

    @ViewBuilder
    private var messageArea: some View {
        if let error = viewModel.errorMessage {
            Text(error).font(Theme.Fonts.medium.swiftUI(size: 11)).foregroundColor(Theme.Colors.redColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let message = viewModel.actionMessage {
            Text(message).font(Theme.Fonts.medium.swiftUI(size: 11)).foregroundColor(Theme.Colors.greenColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 24)).foregroundColor(Theme.Colors.textSecondaryColor)
            Text(text).font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(15)
    }
}

private struct ContactEditorView: View {
    enum EditorMode {
        case create
        case edit(EmergencyContact)
    }

    @Environment(\.dismiss) private var dismiss
    let mode: EditorMode
    let onSave: (EmergencyContactDraft, Bool) -> Void

    @State private var name: String
    @State private var relationship: String
    @State private var phone: String
    @State private var email: String
    @State private var directInAppInvitation = false

    init(mode: EditorMode, onSave: @escaping (EmergencyContactDraft, Bool) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .edit(let contact) = mode {
            _name = State(initialValue: contact.name)
            _relationship = State(initialValue: contact.relationship)
            _phone = State(initialValue: contact.phoneNumber)
            _email = State(initialValue: contact.email ?? "")
            _directInAppInvitation = State(initialValue: contact.linkedUserEmail != nil)
        } else {
            _name = State(initialValue: "")
            _relationship = State(initialValue: "")
            _phone = State(initialValue: "")
            _email = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin") {
                    TextField("Họ và tên", text: $name)
                    TextField("Mối quan hệ", text: $relationship)
                    TextField("Số điện thoại", text: $phone).keyboardType(.phonePad)
                    TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                }
                if case .create = mode {
                    Section {
                        Toggle("Người này đã có tài khoản HEROS", isOn: $directInAppInvitation)
                    } footer: {
                        Text(directInAppInvitation ? "Lời mời sẽ xuất hiện trực tiếp trong ứng dụng." : "HEROS sẽ tạo liên kết để bạn tự chia sẻ qua Messages, Zalo hoặc ứng dụng khác.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Sửa người thân" : "Thêm người thân")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        let draft = EmergencyContactDraft(
                            name: name,
                            phone: phone,
                            email: email,
                            relationship: relationship,
                            priority: 0,
                            emailEnabled: true,
                            pushEnabled: true,
                            linkedUserEmail: directInAppInvitation ? email : nil
                        )
                        onSave(draft, !isEditing && !directInAppInvitation)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
}
