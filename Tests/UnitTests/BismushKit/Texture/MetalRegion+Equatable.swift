//
//  MetalRegion+Equatable.swift
//  Bismush
//
//  Created by mzp on 8/27/22.
//

import Foundation
import Metal

extension MTLOrigin : Equatable, CustomStringConvertible {
    public static func == (lhs: MTLOrigin, rhs: MTLOrigin) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
    
    public var description: String {
        "(\(x), \(y))"
    }
}
extension MTLSize: Equatable, CustomStringConvertible {
    public static func == (lhs: MTLSize, rhs: MTLSize) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.depth == rhs.depth
    }
        
    public var description: String {
        "(\(width), \(height))"
    }
}

extension MTLRegion : Equatable, CustomStringConvertible
{
    public static func == (lhs: MTLRegion, rhs: MTLRegion) -> Bool {
        lhs.origin == rhs.origin && lhs.size == rhs.size
    }
    
    
public var description: String {
    "(\(origin.x), \(origin.y), \(size.width), \(size.height)"
}
}

