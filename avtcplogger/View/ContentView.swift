//
// Sejun Ahn
// github: github.com/sejun-ahn
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var avManager = AVManager()
    @ObservedObject var socketManager = SocketManager.shared
    var body: some View {
        ZStack {
            AVManagerView(avManager: avManager)
                .ignoresSafeArea(edges: .all)
                .background(.white)
            VStack {
                SocketBoxView(socketManager: socketManager)
                    .padding(.top, 30)
                Spacer()
                Button(action: {
                    if !avManager.isCapturing {
                        avManager.startCapture()
                    } else {
                        avManager.stopCapture()
                    }
                }, label: {
                    Text(avManager.isCapturing ? "STOP":"START")
                })
                .frame(width:100, height:100)
                .background(!avManager.isCapturing ? Color.red : Color.gray)
                .foregroundColor(.white)
                .clipShape(.circle)
                .padding(.bottom, 30)
                
            }
        }
        .onAppear() {
            SocketManager.shared.addAction(for: "a", action: { time in
                if !avManager.isCapturing {
                    avManager.startCapture()
                    // Todo: add functions to save the time offset
                    // avManager.startCapture(message)
                }
            })
            SocketManager.shared.addAction(for: "b", action: { message in
                if avManager.isCapturing {
                    avManager.stopCapture()
                    // avManager.stopCapture(message)
                }
            })
        }
    }
}

#Preview {
    ContentView()
}
