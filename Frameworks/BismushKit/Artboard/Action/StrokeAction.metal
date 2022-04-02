//
//  ActionShader.metal
//  Bismush
//
//  Created by Hiro Mizuno on 3/27/22.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;
using namespace raytracing;

typedef struct StrokeTip {
    float2 point;
} StrokeTip;

struct StrokeIn {
    vector_float2 position;
};

struct StrokeOut {
    float4 position [[position]];
};

kernel void stroke_point(uint2 tid [[thread_position_in_grid]],
                         primitive_acceleration_structure accelerationStructure
                         [[buffer(0)]],
                         device StrokeTip &result [[buffer(1)]],
                         device const float2 &position [[buffer(2)]],
                         device const float2 &size [[buffer(3)]],
                         const device float4x4 &inverseProjection [[buffer(4)]],
                         const device float4x4 &inverseModelView
                         [[buffer(5)]]) {
    intersector<triangle_data> i;

    i.accept_any_intersection(true);
    struct ray r;
    float4 pos = float4(0, 0, 0, 1);
    pos.xy = position / (size / 2) - 1;
    float4 origin = inverseProjection * pos;
    r.origin = origin.xyz / origin.w;
    r.direction = float3(0, 0, 1);
    r.min_distance = 0.0;
    r.max_distance = 1.0;

    typename intersector<triangle_data>::result_type intersection =
        i.intersect(r, accelerationStructure);
    float4 point = float4(0, 0, 0, 1);
    point.xyz = r.origin + r.direction * intersection.distance;
    float4 pointInCanvas = inverseModelView * point;
    result.point = pointInCanvas.xy / pointInCanvas.w;
}

vertex StrokeOut stroke_vertex(const device StrokeIn *vertices [[buffer(0)]],
                               const device float4x4 &projection [[buffer(1)]],
                               uint vertexID [[vertex_id]]) {
    StrokeOut out;
    float2 position = vertices[vertexID].position.xy;
    out.position = projection * vector_float4(position.x, position.y, 0, 1);
    return out;
}

fragment float4 stroke_fragment(StrokeOut in [[stage_in]]) {
    return float4(1, 1, 1, 1);
}
