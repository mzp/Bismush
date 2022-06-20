//
//  RendererTestCase.swift
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

class TestDataContext: DataContext {
    func layer(id _: String) -> Data {
        Data()
    }
}

// swiftlint:disable test_case_accessibility
class RendererTestCase: XCTestCase {
    var store: ArtboardStore!

    var canvasSize: Size<CanvasPixelCoordinate> = .init(width: 100, height: 100)

    override func setUpWithError() throws {
        try super.setUpWithError()
        store = ArtboardStore(canvas: Canvas(layers: [
            CanvasLayer(name: "test", layerType: .empty, size: canvasSize),
        ], size: canvasSize), dataContext: TestDataContext())
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        let attachment = XCTAttachment(image: try XCTUnwrap(image))
        attachment.lifetime = .keepAlways
        attachment.name = "rendered"
        add(attachment)
    }

    #if os(macOS)
        func distance(name: String, type: String) -> Float {
            let expectImagePath = Bundle(for: RendererTestCase.self).path(forResource: name, ofType: type)!
            let expectNSImage = NSImage(contentsOfFile: expectImagePath)!
            let expectCGImage = expectNSImage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let actualCGImage = image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let expectFeaturePrint = featurePrint(expectCGImage)!
            let actualFeaturePrint = featurePrint(actualCGImage)!
            var distance: Float = .infinity
            try! expectFeaturePrint.computeDistance(&distance, to: actualFeaturePrint)
            return distance
        }
    #else
        func distance(name: String, type: String) -> Float {
            let expectImagePath: String = Bundle(for: RendererTestCase.self).path(forResource: name, ofType: type)!
            let expectImage = UIImage(contentsOfFile: expectImagePath)!

            let expectCGImage = expectImage.cgImage!
            let context = CIContext(options: nil)
            let actualImage = try! XCTUnwrap(image)
            let actualCGImage = context.createCGImage(actualImage.ciImage!, from: actualImage.ciImage!.extent)!
            let expectFeaturePrint = featurePrint(expectCGImage)!
            let actualFeaturePrint = featurePrint(actualCGImage)!
            var distance: Float = .infinity
            try! expectFeaturePrint.computeDistance(&distance, to: actualFeaturePrint)
            return distance
        }
    #endif

    #if os(macOS)
        private var image: NSImage? {
            let ciImage = CIImage(mtlTexture: store.activeLayer.texture)!
            let rep = NSCIImageRep(ciImage: ciImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)

            return nsImage
        }
    #else
        private var image: UIImage? {
            let ciImage = CIImage(mtlTexture: store.activeLayer.texture)!
            return UIImage(ciImage: ciImage)
        }
    #endif

    private func featurePrint(_ image: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()

        let requestHandler = VNImageRequestHandler(cgImage: image,
                                                   orientation: .down,
                                                   options: [:])
        try! requestHandler.perform([request])
        guard let result = request.results?.first else { return nil }
        return result
    }
}

// swiftlint:enable test_case_accessibility
