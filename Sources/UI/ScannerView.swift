import SwiftUI
import AVFoundation

/// Scan mode: full-bleed back-camera feed, centered scan band, on-device OCR within
/// the band, live multi-currency readout (FR-11..17). The scanner is started on appear
/// and stopped on disappear (NFR-5 / EC-5).
struct ScannerView: View {
    let readCode: String
    let showCodes: [String]

    @StateObject private var scanner = PriceScanner()
    // Observe rates so the readout re-renders when a live refresh lands (FR-5/FR-21).
    @ObservedObject private var rates = RatesStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        content
            .onAppear {
                scanner.setReadCurrency(readCode)
                scanner.start()
            }
            .onDisappear { scanner.stop() }
            .onChange(of: readCode) { _, newCode in scanner.setReadCurrency(newCode) } // EC-4
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { scanner.start() } else { scanner.stop() }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch scanner.state {
        case .denied:
            Centered(title: "Camera permission needed") {
                Text("Allow camera access to read prices. Type mode works without it.")
                    .font(.system(size: 14))
                    .foregroundColor(Tokens.paperDim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                Button(action: openSettings) {
                    Text("Open Settings")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Tokens.onAmber)
                        .padding(.horizontal, 20).padding(.vertical, 11)
                        .background(Tokens.amber)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        case .noCamera:
            Centered(title: "No camera found") {
                Text("This device has no usable back camera.")
                    .font(.system(size: 14))
                    .foregroundColor(Tokens.paperDim)
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
                CameraPreview(session: scanner.session)
                    .frame(width: w, height: h)

                // Scan band (§8): centered, left/right 6%, top 40%, height 20%.
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Tokens.amber, lineWidth: 2)
                    .frame(width: w * 0.88, height: h * 0.20)
                    .position(x: w * 0.5, y: h * 0.50)

                if let d = scanner.detected {
                    // Detected price (read currency) sits just above the band…
                    Text("\(Currencies.symbol(readCode))\(formatGrouped(d)) \(readCode)")
                        .font(.system(size: 15))
                        .tracking(0.5)
                        .foregroundColor(Tokens.paperDim)
                        .monospacedDigit()
                        .shadow(color: Color.black.opacity(0.9), radius: 5, x: 0, y: 1)
                        .frame(width: w)
                        .position(x: w * 0.5, y: h * 0.355)

                    // …and the conversions drop into the dead space below the band.
                    Readout(conversions: shownConversions(amount: d, from: readCode, showCodes: showCodes))
                        .frame(width: w)
                        .position(x: w * 0.5, y: h * 0.72)
                }

                Text("Point the band at a price")
                    .font(.system(size: 13))
                    .foregroundColor(Tokens.paperDim)
                    .position(x: w * 0.5, y: h - 24)
            }
        }
        .background(Tokens.stage)
        .clipped()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

private struct Centered<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Tokens.stage.ignoresSafeArea()
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Tokens.paper)
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
