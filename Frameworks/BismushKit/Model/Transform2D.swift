//
//  Matrix.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/25/22.
//
import simd

struct Transform2D<T: Coordinate, S: Coordinate> {
    var matrix: simd_float4x4

    var inverse: Transform2D<S, T> {
        .init(matrix: matrix.inverse)
    }

    static func * <T: Coordinate, M: Coordinate, S: Coordinate>(
        lhs: Transform2D<T, M>,
        rhs: Transform2D<M, S>
    ) -> Transform2D<T, S> {
        Transform2D<T, S>(matrix: lhs.matrix * rhs.matrix)
    }

    static func identity<T: Coordinate, S: Coordinate>() -> Transform2D<T, S> {
        .init(matrix: matrix_identity_float4x4)
    }

    static func translate(x: Float, y: Float) -> simd_float4x4 {
        let rows = [
            simd_float4(1, 0, 0, x),
            simd_float4(0, 1, 0, y),
            simd_float4(0, 0, 1, 0),
            simd_float4(0, 0, 0, 1),
        ]

        return float4x4(rows: rows)
    }

    static func rotate(angle: Float) -> simd_float4x4 {
        let rows = [
            simd_float4(cos(angle), -sin(angle), 0, 0),
            simd_float4(sin(angle), cos(angle), 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(0, 0, 0, 1),
        ]

        return float4x4(rows: rows)
    }

    static func scale(x: Float, y: Float) -> simd_float4x4 {
        let rows = [
            simd_float4(x, 0, 0, 0),
            simd_float4(0, y, 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(0, 0, 0, 1),
        ]

        return float4x4(rows: rows)
    }
}
