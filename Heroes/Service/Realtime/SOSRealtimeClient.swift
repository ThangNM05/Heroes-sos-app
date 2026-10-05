import Foundation
import SocketIO

enum SOSRealtimeEvent: Equatable {
    case created(sosId: String?)
    case location(sosId: String?)
    case acknowledged(sosId: String?)
    case recording(sosId: String?)
    case resolved(sosId: String?)
    case cancelled(sosId: String?)
}

protocol ISOSRealtimeClient: AnyObject {
    var onConnected: (() -> Void)? { get set }
    var onEvent: ((SOSRealtimeEvent) -> Void)? { get set }
    func connect(accessToken: String)
    func disconnect()
}

final class SOSRealtimeClient: ISOSRealtimeClient {
    var onConnected: (() -> Void)?
    var onEvent: ((SOSRealtimeEvent) -> Void)?

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    func connect(accessToken: String) {
        disconnect()
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

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.onConnected?()
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
    }

    private func bind(
        _ name: String,
        socket: SocketIOClient,
        event: @escaping ([Any]) -> SOSRealtimeEvent
    ) {
        socket.on(name) { [weak self] data, _ in
            self?.onEvent?(event(data))
        }
    }

    private static func sosId(from data: [Any]) -> String? {
        guard let payload = data.first as? [String: Any] else { return nil }
        return payload["sosId"] as? String ?? payload["id"] as? String ?? payload["_id"] as? String
    }

    private static var serverURL: URL? {
        guard var components = URLComponents(string: Configs.Network.baseURL) else { return nil }
        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.url
    }
}
