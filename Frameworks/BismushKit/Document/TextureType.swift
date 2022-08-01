//
//  TextureType.swift
//  Bismush
//
//  Created by mzp on 7/31/22.
//

import Foundation

protocol TextureType {
    var texture: MTLTexture { get }
    var size: Size<TextureCoordinate> { get }
}
