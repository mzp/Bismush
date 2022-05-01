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

fragment float4 layer_fragment(LayerIn in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    const float4 color = texture.sample(textureSampler, in.textureCoordinate);
    return float4(color);
}

float4 layer_get_color(const device BMKLayerContext *context,
                       texture2d<float> texture, float4 point) {
    const float4 p = context->textureProjection * point;
    const float4 color = texture.sample(textureSampler, p.xy / p.w);
    return (float4)color;
}
