import AVFoundation
import Vision
import Combine
import UIKit

/// Camera state for the Scan screen.
enum CameraState: Equatable {
    case unknown
    case denied      // permission refused (FR-17)
    case noCamera    // no usable back camera (§8)
    case ready
}

/// Drives the live camera feed and on-device Vision OCR within the scan band.
/// - Script/languages follow the selected currency (FR-14 / EC-4).
/// - Throttled by frame-skip (NFR-3); region-of-interest = band (FR-12/13).
/// - Camera runs only while started; the view stops it on disappear/background (NFR-5/EC-5).
final class PriceScanner: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var detected: Double?
    @Published private(set) var state: CameraState = .unknown

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.pocketpricereader.ocr")

    // Band region (§8): left 6%, top 40%, width 88%, height 20%.
    // Vision ROI is normalized, origin bottom-left, so y = 1 - (0.40 + 0.20) = 0.40.
    private let regionOfInterest = CGRect(x: 0.06, y: 0.40, width: 0.88, height: 0.20)

    private let frameSkip = 8
    private var frameCount = 0
    private var processing = false
    private var lastSeen = Date.distantPast
    private var readCode: String = "JPY"

    func setReadCurrency(_ code: String) { readCode = code }

    /// Request permission if needed, then configure + start (FR-17).
    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configureAndRun() } else { self?.state = .denied }
                }
            }
        default:
            state = .denied
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configureAndRun() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.inputs.isEmpty {
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input) else {
                    DispatchQueue.main.async { self.state = .noCamera }
                    return
                }
                self.session.beginConfiguration()
                self.session.sessionPreset = .hd1280x720
                self.session.addInput(input)
                self.videoOutput.videoSettings =
                    [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.queue)
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                }
                self.session.commitConfiguration()
            }
            DispatchQueue.main.async { self.state = .ready }
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    // MARK: - Frame processing

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        frameCount &+= 1
        if frameCount % frameSkip != 0 || processing { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processing = true

        let request = VNRecognizeTextRequest { [weak self] req, _ in
            guard let self else { return }
            let text = (req.results as? [VNRecognizedTextObservation] ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            self.handle(text: text)
            self.processing = false
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false           // numbers, not prose
        request.recognitionLanguages = recognitionLanguages(forRead: readCode)
        request.regionOfInterest = regionOfInterest

        // Back camera in portrait: rotate the buffer upright for recognition.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            processing = false
        }
    }

    private func handle(text: String) {
        let price = parsePrice(text)
        let now = Date()
        if let price {
            lastSeen = now
            DispatchQueue.main.async { self.detected = price }
        } else if now.timeIntervalSince(lastSeen) > 1.5 { // FR-16
            DispatchQueue.main.async { self.detected = nil }
        }
    }
}
