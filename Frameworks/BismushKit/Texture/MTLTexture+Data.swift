//
//  MTLTexture+Data.swift
//  Bismush
//
//  Created by mzp on 6/20/22.
//

import Foundation
import Metal

extension MTLTexture {
    var bmkData: Data {
        get {
            let bytesPerRow = MemoryLayout<Float>.size * 4 * width
            let count = width * height * 4
            var bytes = [Float](repeating: 0, count: count)
            getBytes(
                &bytes,
                bytesPerRow: bytesPerRow,
                from: MTLRegionMake2D(0, 0, width, height),
                mipmapLevel: 0
            )
            return Data(bytes: bytes, count: 4 * count)
        }
        set {
            let bytesPerRow = MemoryLayout<Float>.size * 4 * width
            newValue.withUnsafeBytes { pointer in
                guard let baseAddress = pointer.baseAddress else {
                    return
                }
                replace(
                    region: MTLRegionMake2D(0, 0, width, height),
                    mipmapLevel: 0,
                    withBytes: baseAddress,
                    bytesPerRow: bytesPerRow
                )
            }
        }
    }
}
