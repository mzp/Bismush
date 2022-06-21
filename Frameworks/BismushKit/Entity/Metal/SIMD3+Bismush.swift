//
//  SIMD3+Bismush.swift
//  Bismush
//
//  Created by mzp on 4/23/22.
//

import simd

extension SIMD3 {
    // swiftlint:disable:next identifier_name
    var xy: SIMD2<Scalar> {
        .init(x: x, y: y)
    }
}
