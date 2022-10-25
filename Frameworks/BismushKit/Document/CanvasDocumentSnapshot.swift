//
//  DocumentSnapshot.swift
//  Bismush
//
//  Created by mzp on 6/20/22.
//

import Foundation

public struct CanvasDocumentSnapshot: Equatable, Codable {
    var canvas: Canvas
    var textures: [CanvasLayer.ID: BismushTexture.Snapshot]
}
