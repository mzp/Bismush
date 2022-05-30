//
//  ColorSliderViewModelTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by mzp on 5/15/22.
//

import AppKit
import Foundation
import XCTest
@testable import Bismush

class RGBColorViewModelTests: XCTestCase {
    func testColor() throws {
        let colorVM = RGBColorViewModel(color: .constant(NSColor(red: 0, green: 0, blue: 0, alpha: 1)))
        colorVM.red = 1
        XCTAssertEqual(colorVM.currentColor, NSColor(red: 1, green: 0, blue: 0, alpha: 1))

        colorVM.green = 1
        XCTAssertEqual(colorVM.currentColor, NSColor(red: 1, green: 1, blue: 0, alpha: 1))

        colorVM.blue = 1
        XCTAssertEqual(colorVM.currentColor, NSColor(red: 1, green: 1, blue: 1, alpha: 1))

        colorVM.alpha = 0
        XCTAssertEqual(colorVM.currentColor, NSColor(red: 1, green: 1, blue: 1, alpha: 0))
    }
}
