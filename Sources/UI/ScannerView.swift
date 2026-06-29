import SwiftUI
import AVFoundation
import Combine

/// Scan mode: full-bleed back-camera feed, centered scan band, on-device OCR within the
/// band, live multi-currency readout (FR-11..17). Started on appear, stopped on disappear
/// / background (NFR-5 / EC-5).
struct ScannerView: View {
    let readCode: String
    let showCodes: [String]
    var onCorrect: (Double) -> Void = { _ in }

    @StateObject private var scanner = PriceScanner()
    @ObservedObject private var rates = RatesStore.shared
    @Environment(\.scenePhase) private var scenePhase

    // Tap-to-focus indicator (view-space point + a pulse id to retrigger the animation).
    @State private var focusPoint: CGPoint?
    @State private var focusPulse = 0

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
                // Tap anywhere on the feed to focus there, like a camera app.
                CameraPreview(session: scanner.session) { viewPoint, devicePoint in
                    scanner.focus(at: devicePoint)
                    showFocus(at: viewPoint)
                }
                .frame(width: w, height: h)

                // Non-interactive overlays — taps pass through to the camera for focusing.
                Group {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Tokens.primary, lineWidth: 3)
                        .frame(width: w * 0.88, height: h * 0.20)
                        .position(x: w * 0.5, y: h * 0.50)

                    if let d = scanner.detected {
                        Readout(conversions: shownConversions(amount: d, from: readCode, showCodes: showCodes))
                            .frame(width: w)
                            .position(x: w * 0.5, y: h * 0.72)
                    }

                    OutlinedText.label(Copy.hintScan, font: .petal(13), color: Tokens.overlayText, radius: 1)
                        .position(x: w * 0.5, y: h - 22)
                }
                .allowsHitTesting(false)

                // The scanned price IS tappable: tap to fix an OCR mis-read (e.g. superscript
                // cents read as whole digits) in Type mode, pre-filled with these digits.
                if let d = scanner.detected {
                    Button { onCorrect(d) } label: {
                        VStack(spacing: 1) {
                            OutlinedText.label(
                                "\(Currencies.symbol(readCode))\(formatGrouped(d)) \(readCode)",
                                font: .petal(15, .medium), color: Tokens.overlayText, radius: 1.2
                            )
                            OutlinedText.label(
                                Copy.tapToEdit,
                                font: .petal(11), color: Tokens.overlayText.opacity(0.9), radius: 1
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .offset(y: -h * 0.145)
                }

                if let fp = focusPoint {
                    FocusRing().id(focusPulse).position(fp).allowsHitTesting(false)
                }
            }
        }
        .background(Tokens.appBg)
        .clipped()
    }

    private func showFocus(at point: CGPoint) {
        focusPoint = point
        focusPulse += 1
        let token = focusPulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if focusPulse == token { focusPoint = nil }
        }
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

/// A camera-app style focus square that pops in at the tapped point and fades out.
private struct FocusRing: View {
    @State private var scale: CGFloat = 1.35
    @State private var opacity: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Tokens.primary, lineWidth: 2)
            .frame(width: 76, height: 76)
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(color: Tokens.halo.opacity(0.6), radius: 3)
            .onAppear {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { scale = 1; opacity = 1 }
                withAnimation(.easeIn(duration: 0.35).delay(0.5)) { opacity = 0 }
            }
    }
}

/// SwiftUI host for the AVCaptureVideoPreviewLayer (FR-11 full-bleed feed). Reports taps
/// as (view point, device point) so the caller can focus and show an indicator.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var onFocusTap: ((CGPoint, CGPoint) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(onFocusTap: onFocusTap) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        context.coordinator.view = view
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.onFocusTap = onFocusTap
    }

    final class Coordinator: NSObject {
        var onFocusTap: ((CGPoint, CGPoint) -> Void)?
        weak var view: PreviewView?
        init(onFocusTap: ((CGPoint, CGPoint) -> Void)?) { self.onFocusTap = onFocusTap }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view else { return }
            let viewPoint = gesture.location(in: view)
            // Map the tap to the camera's normalised point-of-interest (accounts for aspectFill).
            let devicePoint = view.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
            onFocusTap?(viewPoint, devicePoint)
        }
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
