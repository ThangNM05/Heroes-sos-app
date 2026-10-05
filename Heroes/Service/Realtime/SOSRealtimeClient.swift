import Foundation
import Combine
import SocketIO

enum SOSRealtimeEvent: Equatable {
    case ready
    case chatMessage(SOSChatMessage)
    case chatMemberJoined(chatId: String)
    case chatClosed(chatId: String)
    case created(sosId: String?)
    case location(sosId: String?)
    case acknowledged(sosId: String?)
    case recording(sosId: String?)
    case resolved(sosId: String?)
    case cancelled(sosId: String?)
}

protocol ISOSRealtimeClient: AnyObject {
    var events: AnyPublisher<SOSRealtimeEvent, Never> { get }
    func connect(accessToken: String)
    func disconnect()
}

final class SOSRealtimeClient: ISOSRealtimeClient {
    private let subject = PassthroughSubject<SOSRealtimeEvent, Never>()
    var events: AnyPublisher<SOSRealtimeEvent, Never> { subject.eraseToAnyPublisher() }
    private var accessToken: String?

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    func connect(accessToken: String) {
        guard self.accessToken != accessToken || socket == nil else { return }
        disconnect()
        self.accessToken = accessToken
        guard let serverURL = Self.serverURL else { return }

        let manager = SocketManager(
            socketURL: serverURL,
            config: [
                .path("/socket.io"),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),
                .reconnectWait(2)
            ]
        )
        let socket = manager.socket(forNamespace: "/sos")
        self.manager = manager
        self.socket = socket

        bind("sos.ready", socket: socket) { _ in .ready }
        bind("sos.chat.member_joined", socket: socket) { .chatMemberJoined(chatId: Self.sosId(from: $0) ?? "") }
        bind("sos.chat.closed", socket: socket) { .chatClosed(chatId: Self.sosId(from: $0) ?? "") }
        socket.on("sos.chat.message") { [weak self] data, _ in
            guard let payload = data.first as? [String: Any],
                  let message = payload["message"],
                  let json = try? JSONSerialization.data(withJSONObject: message),
                  let decoded = try? APICoding.makeDecoder().decode(SOSChatMessage.self, from: json) else { return }
            self?.subject.send(.chatMessage(decoded))
        }
        bind("sos.created", socket: socket) { .created(sosId: Self.sosId(from: $0)) }
        bind("sos.location", socket: socket) { .location(sosId: Self.sosId(from: $0)) }
        bind("sos.acknowledged", socket: socket) { .acknowledged(sosId: Self.sosId(from: $0)) }
        bind("sos.recording", socket: socket) { .recording(sosId: Self.sosId(from: $0)) }
        bind("sos.resolved", socket: socket) { .resolved(sosId: Self.sosId(from: $0)) }
        bind("sos.cancelled", socket: socket) { .cancelled(sosId: Self.sosId(from: $0)) }

        // Socket.IO v3/v4 sends this payload as namespace handshake auth.
        socket.connect(withPayload: ["token": accessToken])
    }

    func disconnect() {
        socket?.removeAllHandlers()
        socket?.disconnect()
        manager?.disconnect()
        socket = nil
        manager = nil
        accessToken = nil
    }

    private func bind(
        _ name: String,
        socket: SocketIOClient,
        event: @escaping ([Any]) -> SOSRealtimeEvent
    ) {
        socket.on(name) { [weak self] data, _ in
            self?.subject.send(event(data))
        }
    }

    private static func sosId(from data: [Any]) -> String? {
        guard let payload = data.first as? [String: Any] else { return nil }
        return payload["sosId"] as? String ?? payload["chatId"] as? String ?? payload["id"] as? String ?? payload["_id"] as? String
    }

    private static var serverURL: URL? {
        guard var components = URLComponents(string: Configs.Network.baseURL) else { return nil }
        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.url
    }
}
