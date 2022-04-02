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
