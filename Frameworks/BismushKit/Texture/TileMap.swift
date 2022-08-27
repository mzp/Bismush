//
//  SparseTextureMap.swift
//  Bismush
//
//  Created by mzp on 8/27/22.
//

// https://developer.apple.com/documentation/metal/textures/assigning_memory_to_sparse_textures
// https://developer.apple.com/documentation/metal/textures/reading_and_writing_to_sparse_textures

import Foundation

struct SparseTextureMap {
    var size: Size<TextureCoordinate>
    var tileSize: Size<TextureCoordinate>
    var mapping: [[MTLSparseTextureMappingMode]]

    init(size: Size<TextureCoordinate>, tileSize: Size<TextureCoordinate>) {
        self.size = size
        self.tileSize = tileSize
        mapping = []
    }

    func tileRegion(for _: [Point<TextureCoordinate>]) -> [MTLRegion] {
        []
    }

    func updateMapping(in _: [MTLRegion], mode _: MTLSparseTextureMappingMode) {}
}
