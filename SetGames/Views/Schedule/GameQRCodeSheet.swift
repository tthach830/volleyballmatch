import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

public struct GameQRCodeSheet: View {
    let game: SetGame
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard: Bool = false
    
    private var shareURLString: String {
        "https://runwildlovestronglivefree.org/volleyballmatch/?gameId=\(game.id.uuidString)"
    }
    
    public init(game: SetGame) {
        self.game = game
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Game summary card
                    VStack(spacing: 6) {
                        Text(game.title)
                            .font(.system(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.orange)
                            Text(game.courtLocation)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(game.formattedDate)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 12)
                    
                    // QR Code Card
                    VStack(spacing: 16) {
                        if let qrImage = generateQRCodeImage(from: shareURLString) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 220, height: 220)
                                .overlay(Text("Unable to generate QR code").font(.caption).foregroundColor(.secondary))
                        }
                        
                        // Instructions
                        VStack(spacing: 6) {
                            Text("Point your camera to join")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("iPhone users will open the Volleyball Match app. Non-iOS (Android/Web) users will be directed to the web link.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    
                    // Direct Share & Copy Controls
                    VStack(spacing: 10) {
                        // Copy Link Button
                        Button {
                            UIPasteboard.general.string = shareURLString
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            withAnimation {
                                copiedToClipboard = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    copiedToClipboard = false
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                Text(copiedToClipboard ? "Link Copied!" : "Copy Share Link")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(copiedToClipboard ? Color.green.opacity(0.15) : Color(UIColor.secondarySystemFill))
                            .foregroundColor(copiedToClipboard ? .green : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Native iOS Share Sheet
                        if let url = URL(string: shareURLString) {
                            ShareLink(
                                item: url,
                                subject: Text("Join my Volleyball Game: \(game.title)"),
                                message: Text("Scan or tap the link to join our beach volleyball player pool on \(game.courtLocation)!")
                            ) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Game Link...")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Direct URL preview
                    Text(shareURLString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Game QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
