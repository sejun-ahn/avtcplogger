//
// Sejun Ahn
// github: github.com/sejun-ahn
//

import Foundation
import Network

class SocketManager: ObservableObject {
    static let shared = SocketManager()
    private let hostKey = "SocketHostKey"
    private let portKey = "SocketPortKey"
    private var connection: NWConnection?
    private var receivedMessage: String = ""
    private var actionCaseManager: [String: (String)->Void] = [:]
    private var txPing: Double = 0.0
    private var txPong: Double = 0.0
    private var rxPong: Double = 0.0
    @Published var messages: [String] = ["", "", ""]
    @Published var isConnected: Bool = false
    @Published var pingPong: Bool = false
    @Published var pingPongOffset: Double = 0.0
    @Published var pingPongLatency: Double = 0.0
    
    
    
    var responseCaseManager: ((String) -> String)?
    
    private var heartbeatTimer: Timer?
    
    var host: String {
        get {
            return UserDefaults.standard.string(forKey: hostKey) ?? "0.0.0.0"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hostKey)
        }
    }
    
    var port: String {
        get {
            return UserDefaults.standard.string(forKey: portKey) ?? "8888"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: portKey)
        }
    }
    
    private init() {}
    
    func connect() {
        guard let port = NWEndpoint.Port(rawValue: UInt16(self.port)!) else {
            print("Invalid port: \(self.port)")
            return
        }
        let host = NWEndpoint.Host(self.host)
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                print("Connected to \(host) on  \(port)")
                self?.updateMessages(with: "Connected")
                self?.startHeartbeat()
                self?.receive()
                DispatchQueue.main.async{
                    self?.isConnected = true
                }
            case .failed(let error):
                print("Failed to connect to \(host) on \(port): \(error)")
                self?.updateMessages(with: "Failed to connect")
                self?.disconnect()
                DispatchQueue.main.async{
                    self?.isConnected = false
                }
            case .cancelled:
                print("Cancelled connection to \(host) on \(port)")
                self?.updateMessages(with: "Cancelled connection")
                self?.disconnect()
                DispatchQueue.main.async{
                    self?.isConnected = false
                }
            default:
                break
            }
        }
        connection?.start(queue: .global())
    }
    func disconnect() {
        stopHeartbeat()
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async{
            self.isConnected = false
        }
        print("Disconnected from server")
    }
    func send(_ message: String) {
        guard let connection = connection else { return }
        let data = message.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send data: \(error)")
            } else {
                print("[TX]\(getTimeString()) \(message)")
                if message != "ping" {
                    self.updateMessages(with: "[TX]\(getTimeString()) \(message)")
                }
            }
        }))
    }
    func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024, completion: {data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                DispatchQueue.main.async {
                    self.receivedMessage = String(data: data, encoding: .utf8) ?? ""
                    if let parsedMessage = parseMessage(self.receivedMessage) {
                        print(parsedMessage.flag, parsedMessage.message)
                        if parsedMessage.flag == "pong" {
                            self.updateMessages(with: "[RX]\(getTimeString()) pong \(convertTimeString(date: parsedMessage.message))")
                            self.txPong = convertTimeDouble(date: parsedMessage.message)
                            self.rxPong = Date().timeIntervalSince1970
                            self.pingPongOffset = (self.rxPong + self.txPing)/2 - self.txPong
                            self.pingPongLatency = (self.rxPong - self.txPing)/2
                            self.pingPong.toggle()
                        }
                        if let responseMessage = self.responseCaseManager?(parsedMessage.flag) {
                            self.send(responseMessage)
                        }
                        self.callAction(for: self.receivedMessage)
                    }
                    
                        
                }
            }
            if isComplete {
                print("Connection closed by the server")
                self.stopHeartbeat()
                DispatchQueue.main.async {
                    self.connection?.cancel()
                    self.connection = nil
                }
            } else if let error = error {
                print("Receiving failed with error: \(error)")
            } else {
                self.receive()
            }
        })
    }
    
    private func updateMessages(with message: String) {
        DispatchQueue.main.async {
            if self.messages.count >= 3 {
                self.messages.removeFirst()
            }
            self.messages.append(message)
        }
    }
    
    func startHeartbeat() {
        DispatchQueue.main.async {
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { _ in
                self.send("ping")
                self.txPing = Date().timeIntervalSince1970
            })
        }
    }
    
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    func addAction(for flag: String, action: @escaping (String) -> Void) {
        actionCaseManager[flag] = action
    }
    
    func callAction(for message: String) {
        if let parsedMessage = parseMessage(message) {
            if let action = actionCaseManager[parsedMessage.flag] {
                action(parsedMessage.message)
            }
            else {
                print("Action for flag \(parsedMessage.flag) not found")
            }
        }
    }
}

func parseMessage(_ message: String) -> (flag: String, message: String)? {
    let parts = message.components(separatedBy: ";")
    guard parts.count == 2 else {
        return nil
    }
    return (flag: parts[0], message: parts[1])
}
