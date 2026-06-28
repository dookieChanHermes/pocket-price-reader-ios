import SwiftUI
import AVFoundation
import Combine

/// Scan mode: full-bleed back-camera feed, centered scan band, on-device OCR within the
/// band, live multi-currency readout (FR-11..17). Started on appear, stopped on disappear
/// / background (NFR-5 / EC-5).
struct ScannerView: View {
    let readCode: String
    let showCodes: [String]

    @StateObject private var scanner = PriceScanner()
    @ObservedObject private var rates = RatesStore.shared
    @Environment(\.scenePhase) private var scenePhase

    // Poll to hide the overlay 1.5s after the last read even if frames stall (FR-16).
    private let staleTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        content
            .onAppear { scanner.setReadCurrency(readCode); scanner.start() }
            .onDisappear { scanner.stop() }
            .onChange(of: readCode) { _, newCode in scanner.setReadCurrency(newCode) } // EC-4
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { scanner.start() } else { scanner.stop() }
            }
            .onReceive(staleTimer) { _ in scanner.clearIfStale() }
    }

    @ViewBuilder
    private var content: some View {
        switch scanner.state {
        case .denied:
            Centered(title: Copy.permTitle) {
                Text(Copy.permBody)
                    .font(.petal(14))
                    .foregroundColor(Tokens.overlayText.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 290)
                Button(action: openSettings) {
                    Text(Copy.permButton)
                        .font(.petal(15, .medium))
                        .foregroundColor(Tokens.onPrimary)
                        .padding(.horizontal, 22).padding(.vertical, 12)
                        .background(Tokens.primary)
                        .clipShape(Capsule())
                }
            }
        case .noCamera:
            Centered(title: "🌸") {
                Text(Copy.noCamera)
                    .font(.petal(15))
                    .foregroundColor(Tokens.overlayText.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        default:
            stage
        }
    }

    private var stage: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                CameraPreview(session: scanner.session).frame(width: w, height: h)

                RoundedRectangle(cornerRadius: 18)
                    .stroke(Tokens.primary, lineWidth: 3)
                    .frame(width: w * 0.88, height: h * 0.20)
                    .position(x: w * 0.5, y: h * 0.50)

                if let d = scanner.detected {
                    OutlinedText.label(
                        "\(Currencies.symbol(readCode))\(formatGrouped(d)) \(readCode)",
                        font: .petal(15, .medium), color: Tokens.overlayText, radius: 1.2
                    )
                    .frame(width: w)
                    .position(x: w * 0.5, y: h * 0.355)

                    Readout(conversions: shownConversions(amount: d, from: readCode, showCodes: showCodes))
                        .frame(width: w)
                        .position(x: w * 0.5, y: h * 0.72)
                }

                OutlinedText.label(Copy.hintScan, font: .petal(13), color: Tokens.overlayText, radius: 1)
                    .position(x: w * 0.5, y: h - 22)
            }
        }
        .background(Tokens.appBg)
        .clipped()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}

private struct Centered<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Tokens.appBg.ignoresSafeArea()
            VStack(spacing: 12) {
                Text(title).font(.petal(20, .medium)).foregroundColor(Tokens.overlayText)
                content
            }
            .padding(30)
        }
    }
}

/// SwiftUI host for the AVCaptureVideoPreviewLayer (FR-11 full-bleed feed).
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
