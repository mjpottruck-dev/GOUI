import AVFoundation
import SwiftUI

final class VideoCaptureService: NSObject, ObservableObject {
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var lastError: String? = nil

    private let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "VideoCaptureSessionQueue")
    private var timer: Timer?

    private var currentRecordingID: UUID? = nil
    private var currentRecordingStartDate: Date? = nil
    private weak var clipStore: ClipStore?

    init(clipStore: ClipStore) {
        self.clipStore = clipStore
        super.init()
        configureSession()
    }

    func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard
                let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let videoInput = try? AVCaptureDeviceInput(device: videoDevice)
            else {
                DispatchQueue.main.async {
                    self.lastError = "Camera unavailable."
                }
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }

            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }

            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func startRecording(gameID: UUID) {
        guard !isRecording else { return }
        requestPermissions { [weak self] granted in
            guard let self, granted else { return }
            self.sessionQueue.async {
                guard !self.output.isRecording else { return }
                let fileURL = self.makeRecordingURL(gameID: gameID)
                let startDate = Date()
                let recording = self.clipStore?.startRecording(gameID: gameID, fileURL: fileURL, startDate: startDate)
                self.currentRecordingID = recording?.id
                self.currentRecordingStartDate = startDate
                self.output.startRecording(to: fileURL, recordingDelegate: self)
                DispatchQueue.main.async {
                    self.isRecording = true
                    self.elapsedTime = 0
                    self.startTimer()
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        sessionQueue.async {
            if self.output.isRecording {
                self.output.stopRecording()
            }
        }
        DispatchQueue.main.async {
            self.stopTimer()
            self.isRecording = false
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        if phase == .background || phase == .inactive {
            if isRecording {
                stopRecording()
            }
        }
    }

    func activeRecordingID() -> UUID? {
        currentRecordingID
    }

    func activeRecordingStartDate() -> Date? {
        currentRecordingStartDate
    }

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var videoGranted = false

        group.enter()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            videoGranted = granted
            group.leave()
        }

        group.enter()
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            group.leave()
        }

        group.notify(queue: .main) {
            if !videoGranted {
                self.lastError = "Camera permission is required to record."
            }
            completion(videoGranted)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start = self.currentRecordingStartDate else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
        timer?.tolerance = 0.2
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func makeRecordingURL(gameID: UUID) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = documents.appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let filename = "\(gameID.uuidString)-\(UUID().uuidString).mov"
        return folder.appendingPathComponent(filename)
    }
}

extension VideoCaptureService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        let recordingID = currentRecordingID
        let clipStore = clipStore
        Task {
            let asset = AVURLAsset(url: outputFileURL)
            do {
                let duration = try await asset.load(.duration).seconds
                if let recordingID {
                    clipStore?.finalizeRecording(id: recordingID, duration: duration)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.lastError = error.localizedDescription
                }
            }
        }
        DispatchQueue.main.async {
            if let error {
                self.lastError = error.localizedDescription
            }
            self.currentRecordingID = nil
            self.currentRecordingStartDate = nil
            self.elapsedTime = 0
        }
    }
}
