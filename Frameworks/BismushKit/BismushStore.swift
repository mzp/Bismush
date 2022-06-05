//
//  BismushStore.swift
//  Bismush
//
//  Created by Hiro Mizuno on 6/4/22.
//

import Foundation
import SwiftUI

public class BismushStore: ObservableObject {
    public let artboard: ArtboardStore
    public let brush: Brush

    public init() {
        artboard = ArtboardStore.makeSample()
        brush = Brush(store: artboard)
    }
}
