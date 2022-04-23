//
//  Canvas.metal
//  Bismush
//
//  Created by mzp on 3/16/22.
//

#include <metal_stdlib>
using namespace metal;

struct LayerVertexIn {
    vector_float2 position;
    vector_float2 textureCoordinate;
};

struct LayerVertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex LayerVertexOut layer_vertex(const device LayerVertexIn *vertices
                                   [[buffer(0)]],
                                   const device float4x4 &projection
                                   [[buffer(1)]],
                                   uint vertexID [[vertex_id]]) {
    float2 layerPosition = vertices[vertexID].position.xy;

    LayerVertexOut out;
    out.position =
        projection * vector_float4(layerPosition.x, layerPosition.y, 0, 1.0);
    out.textureCoordinate = vertices[vertexID].textureCoordinate;

    return out;
}

fragment float4 layer_fragment(LayerVertexIn in [[stage_in]],
                               texture2d<half> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    const half4 color = texture.sample(textureSampler, in.textureCoordinate);
    return float4(color);
}

kernel void bezier_interpolation(uint2 tid [[threadgroup_position_in_grid]],
                                 device const float3 &p0 [[buffer(0)]],
                                 device const float3 &p1 [[buffer(1)]],
                                 device const float3 &p2 [[buffer(2)]],
                                 device const float3 &p3 [[buffer(3)]],
                                 device const float &delta [[buffer(4)]],
                                 device float3 *buffer [[buffer(5)]]) {
    int i = tid.x;
    float t = i * delta;
    float3 x1 = pow(1.0 - t, 3) * p0;
    float3 x2 = 3 * t * pow(1.0 - t, 2) * p1;
    float3 x3 = 3 * pow(t, 2) * (1 - t) * p2;
    float3 x4 = pow(t, 3) * p3;
    buffer[i] = x1 + x2 + x3 + x4;
}

struct StrokeOut {
    float4 position [[position]];
    float size [[point_size]];
};

vertex StrokeOut brush_vertex(const device float3 *vertices [[buffer(0)]],
                              const device float4x4 &projection [[buffer(1)]],
                              uint vertexID [[vertex_id]]) {
    StrokeOut out;
    float3 v = vertices[vertexID];
    float4 point = projection * float4(v.xy, 1, 1);
    out.position = point;
    out.size = v.z * 10;
    return out;
}

fragment float4 brush_fragment(StrokeOut in [[stage_in]],
                               float2 pointCoord [[point_coord]]) {

    if (length(pointCoord - float2(0.5)) > 0.5) {
        discard_fragment();
    }
    float4 out_color = float4(1, 1, 1, 1);
    return out_color;
}
