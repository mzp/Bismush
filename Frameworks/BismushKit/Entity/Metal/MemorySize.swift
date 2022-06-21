//
//  MemorySize.swift
//  Bismush
//
//  Created by mzp on 4/30/22.
//

import Foundation

enum MemorySize {
    static let float = MemoryLayout<Float>.size
    static let float3 = MemoryLayout<SIMD3<Float>>.size
    static let float4 = MemoryLayout<SIMD4<Float>>.size
    static let uint32 = MemoryLayout<UInt32>.size
}
