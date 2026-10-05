import AVFoundation
import Foundation

struct SOSAudioClip {
    let data: Data
    let durationSeconds: Int
    let fileName: String
    let mimeType: String
}

enum SOSAudioRecorderError: LocalizedError {
    case permissionDenied
    case cannotStart
    case noActiveRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "HEROS cần quyền Micro để ghi âm bằng chứng. Bạn có thể cấp quyền trong Cài đặt."
        case .cannotStart:
            return "Không thể bắt đầu ghi âm trên thiết bị này."
        case .noActiveRecording:
            return "Không có bản ghi âm đang hoạt động."
        }
    }
}

@MainActor
final class SOSAudioRecorder {
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    var isRecording: Bool { recorder?.isRecording == true }

    func normalizedPowerLevel() -> CGFloat {
        guard let recorder, recorder.isRecording else { return 0.08 }
        recorder.updateMeters()
        let decibels = recorder.averagePower(forChannel: 0)
        let minimumDecibels: Float = -50
        guard decibels > minimumDecibels else { return 0.08 }
        return CGFloat(min(max((decibels - minimumDecibels) / -minimumDecibels, 0.08), 1))
    }

    func start() async throws {
        guard !isRecording else { return }
        guard await requestPermission() else { throw SOSAudioRecorderError.permissionDenied }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try audioSession.setActive(true)

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("HEROS-Recordings", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        let url = directory.appendingPathComponent(UUID().uuidString.lowercased()).appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 96_000
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        guard recorder.prepareToRecord(), recorder.record() else {
            throw SOSAudioRecorderError.cannotStart
        }
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var protectedURL = url
        try protectedURL.setResourceValues(values)
        self.recorder = recorder
        self.recordingURL = url
    }

    func stop() throws -> SOSAudioClip {
        guard let recorder, let url = recordingURL else { throw SOSAudioRecorderError.noActiveRecording }
        let duration = max(1, Int(ceil(recorder.currentTime)))
        recorder.stop()
        self.recorder = nil
        self.recordingURL = nil

        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        try? FileManager.default.removeItem(at: url)
        return SOSAudioClip(data: data, durationSeconds: min(duration, 120), fileName: url.lastPathComponent, mimeType: "audio/mp4")
    }

    func cancel() {
        recorder?.stop()
        if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
        recorder = nil
        recordingURL = nil
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
