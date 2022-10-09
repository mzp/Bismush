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

    public class func array<T>(buffer: MTLBuffer, type: T.Type, count: Int) -> [T] {
        Array(
            UnsafeBufferPointer(start: buffer.contents().bindMemory(to: type, capacity: count),
                                count: count)
        )
    }
}
