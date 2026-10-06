//
//  SOSChatContextView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI
import MapKit

struct SOSChatContextView: View {
    let detail: SOSChatDetail
    @ObservedObject var player: ProtectedAudioPlayer
    let play: (SOSChatRecording) -> Void
    @State private var showMembers = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showMembers = true } label: {
                HStack {
                    Label("\(detail.summary.memberCount) thành viên", systemImage: "person.2")
                    Spacer()
                    Text(detail.summary.status == .closed ? "Đã kết thúc" : "Đang hỗ trợ").font(.caption)
                }
            }
            if detail.summary.status == .active, let location = detail.currentLocation,
               location.coordinates.count == 2 {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))) {
                    Marker(detail.summary.ownerName, coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude, longitude: location.longitude))
                }
                .id(location.recordedAt)
                .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 12))
                Text(detail.currentAddress ?? location.address ??
                     String(format: "%.6f, %.6f", location.latitude, location.longitude))
                    .font(.caption).foregroundStyle(.secondary)
            }
            if detail.summary.status == .active {
                ForEach(detail.recordings.filter { $0.expiresAt > Date() }) { recording in
                    Button { play(recording) } label: {
                        HStack {
                            Image(systemName: player.activeRecordingID == recording.id && player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            Text("Bản ghi \(recording.createdAt.formatted(date: .omitted, time: .shortened))")
                            Spacer()
                            Text(recording.audioRecord(sosId: detail.summary.sosId).formattedDuration)
                        }
                        .font(.callout)
                    }
                }
            }
            if let error = player.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .padding().background(Color(.secondarySystemBackground))
        .sheet(isPresented: $showMembers) {
            NavigationStack {
                List(detail.members) { member in
                    HStack(spacing: 12) {
                        UserAvatarView(urlString: member.avatarUrl,
                                       initials: String(member.name.prefix(1)), size: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                            Text(member.role == "owner" ? "Chủ SOS" :
                                 member.supportMode == .remote ? "Đã xác nhận hỗ trợ" : "Đang đến hỗ trợ")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Thành viên")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Đóng") { showMembers = false } } }
            }
        }
    }
}
