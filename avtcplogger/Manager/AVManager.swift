//
// Sejun Ahn
// github: github.com/sejun-ahn
//

import Foundation
import AVFoundation
import SwiftUI
import AudioToolbox

class AVManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var videoLayer: AVCaptureVideoPreviewLayer!

    @Published var isCapturing: Bool = false
    var startTime: Date?
    
    func setupCaptureSession(in view: UIView) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.captureSession = AVCaptureSession()
            self.captureSession.sessionPreset = .hd1920x1080
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            self.setShutterSpeed(session: self.captureSession, shutterSpeed: 0.001)
            guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
            
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            }
            self.videoOutput = AVCaptureMovieFileOutput()
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .landscapeRight
                }
            }
            DispatchQueue.main.async {
                self.videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.videoLayer.videoGravity = .resizeAspectFill
                self.videoLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
                view.layer.addSublayer(self.videoLayer)
            }
            self.captureSession.startRunning()
        }
    }
    func startCapture() {
        let directoryName = createDirectoryName()
        let directoryURL = getDirectoryURL(directoryName: directoryName)
        let fileURL = directoryURL.absoluteURL.appendingPathComponent("video.mov", isDirectory: false)
        self.videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        self.isCapturing = true
        playShutterSound()
    }
    func stopCapture() {
        self.videoOutput.stopRecording()
        self.isCapturing = false
    }
}

extension AVManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("AV Recording Started")
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let error = error {
            print("Can't Record AV: \(error.localizedDescription)")
        } else {
            print("AV Recording Finished Successfully")
        }
    }
}

extension AVManager {
    func setShutterSpeed(session: AVCaptureSession, shutterSpeed: Double) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            
            if device.isExposureModeSupported(.custom) {
                device.exposureMode = .custom
                let exposureDuration = CMTimeMakeWithSeconds(shutterSpeed, preferredTimescale: Int32(NSEC_PER_SEC))
                device.setExposureModeCustom(duration: exposureDuration, iso: AVCaptureDevice.currentISO, completionHandler: nil)
            } else {
                print("Manual exposure mode is not supported")
            }
            device.unlockForConfiguration()
        } catch {
            print("Error lock configuration: \(error.localizedDescription)")
        }
    }
}
func createDirectoryName() -> String {
    let format = DateFormatter()
    format.dateFormat = "yyMMdd_HHmmss"
    return format.string(from: Date())
}

func getDirectoryURL(directoryName: String) -> URL {
    let directoryName = directoryName
    let fileManager = FileManager.default
    let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let directoryURL = documentURL.absoluteURL.appending(path: directoryName)
    
    do {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    } catch let error {
        print(error)
    }
    
    return directoryURL
}

struct AVManagerView: UIViewControllerRepresentable {
    @ObservedObject var avManager: AVManager
    func makeUIViewController(context: Context) -> AVManagerViewController {
        let controller = AVManagerViewController()
        controller.avManager = avManager
        return controller
    }
    func updateUIViewController(_ uiViewController: AVManagerViewController, context: Context) { }
}

class AVManagerViewController: UIViewController {
    var avManager: AVManager!
    override func viewDidLoad() {
        super.viewDidLoad()
        avManager.setupCaptureSession(in: view)
    }
}

func playShutterSound() {
    AudioServicesPlaySystemSound(1052)
}
