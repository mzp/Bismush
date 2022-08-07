//
//  Canvas.metal
//  Bismush
//
//  Created by mzp on 3/16/22.
//

#include <BismushKit/BMKLayerContext.h>
#include <metal_stdlib>
using namespace metal;

struct LayerIn {
    vector_float2 position;
    vector_float2 textureCoordinate;
};

struct LayerOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

static constexpr sampler textureSampler(mag_filter::nearest,
                                        min_filter::nearest);

vertex LayerOut layer_vertex(const device LayerIn *vertices [[buffer(0)]],
                             const device float4x4 &projection [[buffer(1)]],
                             uint vertexID [[vertex_id]]) {
    float2 layerPosition = vertices[vertexID].position.xy;

    LayerOut out;
    out.position = projection * vector_float4(layerPosition.xy, 0, 1.0);
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    return out;
}

fragment float4 layer_blend(LayerIn in [[stage_in]],
                            texture2d<float> texture [[texture(0)]]) {
    const float4 color = texture.sample(textureSampler, in.textureCoordinate);
    if (color.w == 0) {
        discard_fragment();
    }
    return float4(color);
}

fragment float4 layer_copy(LayerIn in [[stage_in]],
                           texture2d<float> source [[texture(0)]],
                           texture2d<float> destination [[texture(1)]]) {
    const float4 sourceColor =
        source.sample(textureSampler, in.textureCoordinate);
    const float4 destinationColor =
        destination.sample(textureSampler, in.textureCoordinate);
    float alpha = destinationColor.w * (1 - sourceColor.w) + sourceColor.w;

    if (alpha == 0) {
        return float4(1, 1, 1, 0);
    } else {
        float3 color = destinationColor.xyz * (1 - sourceColor.w) * alpha +
                       sourceColor.xyz * sourceColor.w;
        return float4(color / alpha, alpha);
    }
}
