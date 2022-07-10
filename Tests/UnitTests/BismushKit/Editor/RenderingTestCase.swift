//
//  RenderingTestCase.swift
//  Bismush
//
//  Created by mzp on 4/10/22.
//

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif
import Vision
import XCTest
@testable import BismushKit

// swiftlint:disable test_case_accessibility
class RenderingTestCase: XCTestCase {
    var renderer: CanvasRenderer!
    var document: CanvasDocument!

    func createDocument() -> CanvasDocument {
        CanvasDocument(canvas: .init(layers: [
            CanvasLayer(name: "test", layerType: .empty, size: .init(width: 800, height: 800)),
        ], size: .init(width: 800, height: 800)))
    }

    var viewSize: Size<ViewCoordinate> {
        Size(document.canvas.size)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        document = createDocument()
        renderer = CanvasRenderer(document: document)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        let attachment = XCTAttachment(image: try XCTUnwrap(image))
        attachment.lifetime = .keepAlways
        attachment.name = "rendered"
        add(attachment)
    }

    func openWithPreview() throws {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)

        let newRep = NSBitmapImageRep(cgImage: cgImage!)
        newRep.size = image.size
        guard let data = newRep.representation(using: .png, properties: [:]) else {
            return
        }
        guard let testName = invocation?.selector.description.replacingOccurrences(of: ":", with: "") else {
            return
        }
        let tempDirectory = URL(filePath: NSTemporaryDirectory()).appending(path: "Bismush")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let outputURL = tempDirectory.appending(path: "\(testName)-\(UUID()).png")

        BismushLogger.testing.info("Saved to \(outputURL)")
        try data.write(to: outputURL)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/open")
        process.arguments = [outputURL.path]

        process.launch()

        process.waitUntilExit()
    }

    func resource(name: String, type: String) -> String? {
        Bundle(for: RenderingTestCase.self).path(forResource: name, ofType: type) ??
            Bundle(for: CanvasRenderer.self).path(forResource: name, ofType: type)
    }

    #if os(macOS)
        func distance(name: String, type: String) throws -> Float {
            let expectImagePath = resource(name: name, type: type)!
            let expectNSImage = NSImage(contentsOfFile: expectImagePath)!
            let expectCGImage = expectNSImage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let actualCGImage = image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let expectFeaturePrint = try featurePrint(expectCGImage)!
            let actualFeaturePrint = try featurePrint(actualCGImage)!
            var distance: Float = .infinity
            try! expectFeaturePrint.computeDistance(&distance, to: actualFeaturePrint)
            return distance
        }
    #else
        func distance(name: String, type: String) throws -> Float {
            let expectImagePath: String = resource(name: name, type: type)!
            let expectImage = UIImage(contentsOfFile: expectImagePath)!

            let expectCGImage = expectImage.cgImage!
            let context = CIContext(options: nil)
            let actualImage = try! XCTUnwrap(image)
            let actualCGImage = context.createCGImage(actualImage.ciImage!, from: actualImage.ciImage!.extent)!
            let expectFeaturePrint = try featurePrint(expectCGImage)!
            let actualFeaturePrint = try featurePrint(actualCGImage)!
            var distance: Float = .infinity
            try! expectFeaturePrint.computeDistance(&distance, to: actualFeaturePrint)
            return distance
        }
    #endif

    #if os(macOS)
        private var image: NSImage!

        func render() {
            let ciImage = CIImage(mtlTexture: document.texture(canvasLayer: document.activeLayer).texture)!
            let rep = NSCIImageRep(ciImage: ciImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            image = nsImage
        }
    #else
        private var image: UIImage!

        func render() {
            let ciImage = CIImage(mtlTexture: document.texture(canvasLayer: document.activeLayer).texture)!
            image = UIImage(ciImage: ciImage)
        }
    #endif

    private func featurePrint(_ image: CGImage) throws -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()

        let requestHandler = VNImageRequestHandler(cgImage: image,
                                                   orientation: .down,
                                                   options: [:])
        try requestHandler.perform([request])
        guard let result = request.results?.first else { return nil }
        return result
    }
}

// swiftlint:enable test_case_accessibility
