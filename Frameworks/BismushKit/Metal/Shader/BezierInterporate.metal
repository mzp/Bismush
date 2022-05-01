//
//  BezierInterporate.metal
//  Bismush
//
//  Created by mzp on 4/30/22.
//

#import <BismushKit/BMKStroke.h>
#include <metal_stdlib>
using namespace metal;

kernel void bezier_interpolation(uint2 tid [[threadgroup_position_in_grid]],
                                 device BMKStroke *strokes [[buffer(0)]],
                                 device const float3 &p0 [[buffer(1)]],
                                 device const float3 &p1 [[buffer(2)]],
                                 device const float3 &p2 [[buffer(3)]],
                                 device const float3 &p3 [[buffer(4)]],
                                 device const float &delta [[buffer(5)]]) {
    const int i = tid.x;
    const float t = i * delta;
    const float3 x1 = pow(1.0 - t, 3) * p0;
    const float3 x2 = 3 * t * pow(1.0 - t, 2) * p1;
    const float3 x3 = 3 * pow(t, 2) * (1 - t) * p2;
    const float3 x4 = pow(t, 3) * p3;
    strokes[i].point = x1 + x2 + x3 + x4;
}
