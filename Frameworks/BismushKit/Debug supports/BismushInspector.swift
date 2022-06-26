//
//  TextureDump.swift
//  Bismush
//
//  Created by mzp on 6/19/22.
//

import CoreGraphics
import Foundation

public class BismushInspector {
    public class func image(_ data: Data, width: Int, height: Int) -> CGImage? {
        let bitCount = 8
        guard let provider = CGDataProvider(data: data as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitCount,
            bitsPerPixel: bitCount * 4,
            bytesPerRow: MemoryLayout<Float>.size * 4 * width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: [CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)],
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    public class func dump<T>(buffer: MTLBuffer, type: T.Type, count: Int) -> [T] {
        Array(
            UnsafeBufferPointer(start: buffer.contents().bindMemory(to: type, capacity: count),
                                count: count)
        )
    }

    class func dump<T>(array: MetalMutableArray<T>) -> [T] {
        guard let content = array.content else {
            return []
        }
        return dump(buffer: content, type: T.self, count: array.count)
    }
}

extension LayerTexture {
    var inspectImage: CGImage? {
        let size = canvasLayer.size
        return BismushInspector.image(texture.bmkData, width: Int(size.width), height: Int(size.height))
    }
}
