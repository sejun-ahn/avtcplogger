//
// Sejun Ahn
// github: github.com/sejun-ahn
//

import SwiftUI

func getTimeString() -> String {
    let formatter = DateFormatter()
    let date = Date()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: date)
}

func convertTimeString(date: String) -> String {
    guard let dateDouble = Double(date) else { return " " }
    let formatter = DateFormatter()
    let date = Date(timeIntervalSince1970: dateDouble)
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: date)
}

struct SocketBoxView: View {
    @ObservedObject var socketManager: SocketManager
    @State private var hostText: String = SocketManager.shared.host
    @State private var portText: String = SocketManager.shared.port
    @State var toSend: String = ""
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                VStack(spacing: 5) {
                    Text("Host IP Address")
                        .mediumStyle()
                    TextField("Host", text: $hostText)
                        .mediumStyle()
                        .textFieldStyle(flag: socketManager.isConnected)
                        
                }
                VStack(spacing: 5) {
                    Text("Port")
                        .smallStyle()
                    TextField("Port", text: $portText)
                        .smallStyle()
                        .textFieldStyle(flag: socketManager.isConnected)
                }
                
                VStack(spacing: 5) {
                    Image(systemName: "heart.fill")
                        .frame(width: 30, height: 30)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .foregroundColor(socketManager.isConnected ? (socketManager.pingPong ? .red : .black) : .gray)
                    
                    Button(action: {
                        if !socketManager.isConnected {
                            SocketManager.shared.host = hostText
                            SocketManager.shared.port = portText
                            SocketManager.shared.connect()
                        } else {
                            SocketManager.shared.disconnect()
                        }
                    }) {
                        Text(socketManager.isConnected ? "DSCNCT" : "CNCT")
                            .smallStyle()
                            .toggleButtonStyle(flag: socketManager.isConnected)
                    }
                }
            }
            
            HStack(spacing: 5) {
                Text("Messages")
                    .mediumStyle()
                Button(action: {
                    print("Delay Check")
                }, label: {
                    Text("Delay Check")
                })
                .mediumStyle()
                .buttonStyle(flag: socketManager.isConnected)
            }
                VStack(spacing: 5) {
                    ForEach(socketManager.messages, id: \.self) { message in
                        Text(message)
                            .padding(10)
                            .frame(width: 335, height: 30, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(6)
                    }
                }
                .frame(width: 345, height: 110)
                .background(Color.gray)
                .cornerRadius(6)
                
                
    
            HStack(spacing: 5) {
                TextField("Text to send", text: $toSend)
                    .largeStyle()
                    .textFieldStyle(flag: !socketManager.isConnected)
                Button(action: {
                    SocketManager.shared.send(toSend)
                }, label: {
                    Text("Send")
                })
                .smallStyle()
                .buttonStyle(flag: socketManager.isConnected)
            }
        }
        //.padding(20)
        .frame(width: 345, height: 260, alignment: .center)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(6)
        .shadow(radius: 1)
        //.padding()
    }
}
