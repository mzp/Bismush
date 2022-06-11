//
//  BismushColor.swift
//  Bismush
//
//  Created by mzp on 4/24/22.
//

import CoreGraphics
import Foundation

#if os(macOS)
    import AppKit
#endif

public struct BismushColor {
    var rawValue: SIMD4<Float>

    public var red: Float { rawValue.x }
    public var green: Float { rawValue.y }
    public var blue: Float { rawValue.z }
    public var alpha: Float { rawValue.w }

    public init(red: Float, green: Float, blue: Float, alpha: Float) {
        rawValue = SIMD4(red, green, blue, alpha)
    }

    public init(cgColor: CGColor) {
        let components = cgColor.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .perceptual,
            options: nil
        )?.components ?? []
        assert(components.count == 4)
        rawValue = SIMD4(Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]))
    }

    init(rawValue: SIMD4<Float>) {
        self.rawValue = rawValue
    }

    static let black = Self(rawValue: SIMD4(0, 0, 0, 1))

    #if os(macOS)
        public var nsColor: NSColor {
            NSColor(
                red: CGFloat(red),
                green: CGFloat(green),
                blue: CGFloat(blue),
                alpha: CGFloat(alpha)
            )
        }
    #endif
}
