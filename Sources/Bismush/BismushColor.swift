//
//  BismushKit+appKit.swift
//  Bismush
//
//  Created by mzp on 5/28/22.
//

import AppKit
import BismushKit

extension BismushColor {
    var nsColor: NSColor {
        NSColor(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }
}
