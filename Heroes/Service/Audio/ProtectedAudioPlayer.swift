import Foundation
import AVFoundation
import Combine

@MainActor
final class ProtectedAudioPlayer: ObservableObject {
    @Published private(set) var activeRecordingID: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: ISOSAPIRepository
    private var player: AVPlayer?
    private var endCancellable: AnyCancellable?
    private var downloadTask: Task<Void, Never>?
    private var generation = UUID()

    init(repository: ISOSAPIRepository) {
        self.repository = repository
    }

    func play(record: AudioRecord, sosId: String, session: AppSessionStore) {
        if activeRecordingID == record.id, let player {
            if isPlaying {
                player.pause()
                isPlaying = false
            } else {
                player.play()
                isPlaying = true
            }
            return
        }

        stop()
        isLoading = true
        errorMessage = nil
        let epoch = generation
        downloadTask = Task {
            defer { if epoch == generation { isLoading = false } }
            do {
                let localURL: URL
                if session.currentRole == .deviceOwner,
                   let cached = SecureAudioCache.cachedURL(recordingId: record.id, mimeType: record.mimeType) {
                    localURL = cached
                } else {
                    let download = try await session.performAuthenticatedRequest {
                        try await self.repository.downloadRecording(
                            sosId: sosId,
                            recordingId: record.id,
                            accessToken: $0
                        )
                    }
                    guard epoch == generation, !Task.isCancelled, session.isAuthenticated else { return }
                    localURL = try SecureAudioCache.store(
                        download.data,
                        recordingId: record.id,
                        mimeType: download.mimeType ?? record.mimeType
                    )
                }
                guard epoch == generation, !Task.isCancelled, session.isAuthenticated else { return }
                try configureAudioSession()
                startPlayer(url: localURL, recordingId: record.id)
            } catch {
                guard epoch == generation, !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                stop()
            }
        }
    }

    func stop() {
        generation = UUID()
        downloadTask?.cancel()
        downloadTask = nil
        isLoading = false
        player?.pause()
        endCancellable?.cancel()
        endCancellable = nil
        player = nil
        activeRecordingID = nil
        isPlaying = false
    }

    func clearAndStop() {
        stop()
        SecureAudioCache.clear()
    }

    private func startPlayer(url: URL, recordingId: String) {
        let item = AVPlayerItem(url: url)
        let nextPlayer = AVPlayer(playerItem: item)
        player = nextPlayer
        activeRecordingID = recordingId
        isPlaying = true
        endCancellable = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.stop() }
        nextPlayer.play()
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
        try audioSession.setActive(true)
    }
}
