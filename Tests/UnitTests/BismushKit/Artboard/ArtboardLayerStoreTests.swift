//
//  ArtboardLayerStoreTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by Hiro Mizuno on 6/11/22.
//

import CoreGraphics
import XCTest
@testable import BismushKit

class DummyContext: CanvasContext {
    var device: GPUDevice { .default }

    var modelViewMatrix: Transform2D<WorldCoordinate, CanvasPixelCoordinate> {
        .identity()
    }
}

class ArtboardLayerStoreTests: XCTestCase {
    private var context: DummyContext!
    override func setUp() {
        super.setUp()
        context = DummyContext()
    }

    func testData() throws {
        let layer = CanvasLayer(
            name: "#yosemite",
            layerType: .empty,
            size: .init(width: 800, height: 800)
        )
        let store = ArtboardLayerStore(canvasLayer: layer, context: context)
        let data = store.data

        let dataLayer = CanvasLayer(
            name: "#yosemite",
            layerType: .data(data),
            size: .init(width: 800, height: 800)
        )
        let restoredStore = ArtboardLayerStore(canvasLayer: dataLayer, context: context)
        let restoredData = restoredStore.data

        let attachment = XCTAttachment(image: try XCTUnwrap(image(data, width: 800, height: 800)))
        attachment.name = "data"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(data, restoredData)
    }

    func image(_ data: Data, width: Int, height: Int) -> NSImage? {
        var data = data
        let bitCount = 1 + Float.significandBitCount + Float.exponentBitCount
        // 128 bpp, 32 bpc, kCGImageAlphaNoneSkipLast |kCGBitmapFloatComponents
        let pointer = UnsafeMutableRawPointer(mutating: &data)
        let context = CGContext(data: pointer,
                                width: width,
                                height: height,
                                bitsPerComponent: bitCount,
                                bytesPerRow: MemoryLayout<Float>.size * 4 * width,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.floatComponents.rawValue)
        let cgImage = context?.makeImage()
        return nil
        /*        guard let provider = CGDataProvider(data: data as CFData) else {
             return nil
         }

         let cgImage = CGImage(
             width: width,
             height: height,
             bitsPerComponent: bitCount,
             bitsPerPixel: bitCount * 4,
             bytesPerRow: MemoryLayout<Float>.size * 4 * width,
             space: CGColorSpaceCreateDeviceRGB(),
             bitmapInfo: [.floatComponents, CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)],
             provider: provider,
             decode: nil,
             shouldInterpolate: false,
             intent: .defaultIntent
         )

         if let cgImage = cgImage {
             return NSImage(cgImage: cgImage, size: .init(width: width, height: height))
         } else {
             return nil
         }*/
        /*
         size_t
         CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, bufferLength, NULL);
         size_t bitsPerComponent = 8;
         size_t bitsPerPixel = 32;
         size_t bytesPerRow = 4 * width;
         CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
         CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
         CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

         CGImageRef iref = CGImageCreate(width,
                                         height,
                                         bitsPerComponent,
                                         bitsPerPixel,
                                         bytesPerRow,
                                         colorSpaceRef,
                                         bitmapInfo,
                                         provider,   // data provider
                                         NULL,       // decode
                                         YES,        // should interpolate
                                         renderingIntent);

         _image = [[NSImage alloc] initWithCGImage:iref size:NSMakeSize(width, height)];
         */
    }
}
