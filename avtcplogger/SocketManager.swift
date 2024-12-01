//
//  SocketManager.swift
//  avtcplogger
//
//  Created by mpilmini on 11/14/24.
//


import Foundation
import Network

class SocketManager: ObservableObject {
    static let shared = SocketManager()
    private let hostKey = "SocketHostKey"
    private let portKey = "SocketPortKey"
    private var connection: NWConnection?
    private var receivedMessage: String = ""
    private var actionCaseManager: [String: ()->Void] = [:]
    @Published var messages: [String] = ["", "", ""]
    @Published var isConnected: Bool = false
    @Published var pingPong: Bool = false
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
                    print("[RX]\(getTimeString()) \(self.receivedMessage)")
                    if self.receivedMessage != "pong" {
                        self.updateMessages(with: "[RX]\(getTimeString()) \(self.receivedMessage)")
                    } else {
                        self.pingPong.toggle()
                    }
                    if let message = self.responseCaseManager?(self.receivedMessage) {
                        self.send(message)
                        
                    }
                    self.callAction(for: self.receivedMessage)
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
            })
        }
    }
    
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendHeartbeat() {
        let ping = "ping"
        send(ping)
    }
    
    func addAction(for message: String, action: @escaping () -> Void) {
        actionCaseManager[message] = action
    }
    func callAction(for message: String) {
        if let action = actionCaseManager[message] {
            action()
        } else {
            print("Action for message \(message) not found")
        }
    }
}
