import SwiftUI

struct EmergencyNetworkView: View {
    enum Mode { case manage, connections }
    let mode: Mode
    @StateObject private var viewModel: SOSSettingsViewModel
    @State private var showingAddContact = false
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var newRelationship = ""

    init(mode: Mode = .manage, viewModel: SOSSettingsViewModel? = nil) {
        self.mode = mode
        _viewModel = StateObject(wrappedValue: viewModel ?? SOSSettingsViewModel(sosService: AppDIContainer.shared.resolve()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        if mode == .manage { encouragementCard }
                        contactsList
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
                            .disabled(viewModel.emergencyContacts.count >= 10)
                    }
                }
            }
            .onAppear { viewModel.loadSettingsAndContacts() }
            .sheet(isPresented: $showingAddContact) { addContactSheet }
        }
    }

    private var encouragementCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.3.fill").foregroundColor(Theme.Colors.primaryColor)
            VStack(alignment: .leading, spacing: 5) {
                Text("\(viewModel.emergencyContacts.count)/10 người đã kết nối").font(Theme.Fonts.bold.swiftUI(size: 14))
                Text("Mời thêm người thân, bạn bè tải HEROS để bạn được hỗ trợ kịp thời hơn khi gặp sự cố.")
                    .font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
            }
        }
        .padding(16).background(Theme.Colors.softPink).cornerRadius(16)
    }

    private var contactsList: some View {
        VStack(spacing: 10) {
            ForEach(displayedContacts) { contact in
                HStack(spacing: 12) {
                    Text(String(contact.name.prefix(1)))
                        .font(Theme.Fonts.bold.swiftUI(size: 16)).foregroundColor(.white)
                        .frame(width: 42, height: 42).background(Theme.Colors.primaryColor).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(contact.name).font(Theme.Fonts.bold.swiftUI(size: 14))
                        Text("\(contact.relationship) • \(contact.phoneNumber)")
                            .font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
                        Text(contact.invitationStatus.rawValue)
                            .font(Theme.Fonts.semiBold.swiftUI(size: 10))
                            .foregroundColor(contact.invitationStatus == .accepted ? Theme.Colors.greenColor : Theme.Colors.amberColor)
                    }
                    Spacer()
                    if mode == .manage {
                        Menu {
                            Button(role: .destructive) { viewModel.deleteContact(id: contact.id) } label: {
                                Label("Hủy kết nối", systemImage: "person.crop.circle.badge.minus")
                            }
                        } label: {
                            Image(systemName: "ellipsis").foregroundColor(Theme.Colors.textSecondaryColor).padding(8)
                        }
                    }
                }
                .padding(14).background(Color.white).cornerRadius(15)
            }
        }
    }

    private var displayedContacts: [EmergencyContact] {
        if mode == .manage { return viewModel.emergencyContacts }
        return [EmergencyContact(id: "OWNER-CONNECTION", name: "Nguyễn Thị An", relationship: "Người thân đã mời bạn", phoneNumber: "0901 234 567", avatarUrl: nil, priorityOrder: 1, isTrusted: true, isNotifiedViaSMS: true, isNotifiedViaCall: true, invitationStatus: .accepted)]
    }

    private var addContactSheet: some View {
        NavigationStack {
            Form {
                Section("Thông tin người thân") {
                    TextField("Họ và tên", text: $newName)
                    TextField("Mối quan hệ", text: $newRelationship)
                    TextField("Số điện thoại", text: $newPhone).keyboardType(.phonePad)
                }
                Section {
                    Text("Người này sẽ nhận lời mời tải HEROS và cần xác nhận trước khi nhận tín hiệu SOS của bạn.")
                }
            }
            .navigationTitle("Mời người thân")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { showingAddContact = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gửi lời mời") {
                        viewModel.addContact(name: newName, relationship: newRelationship, phone: newPhone)
                        showingAddContact = false
                        newName = ""; newRelationship = ""; newPhone = ""
                    }
                    .disabled(newName.isEmpty || newPhone.isEmpty || viewModel.emergencyContacts.count >= 10)
                }
            }
        }
    }
}
