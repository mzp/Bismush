//
//  BMKLayerContext.metal
//  Bismush
//
//  Created by mzp on 7/2/22.
//

#include <BismushKit/BMKLayerContext.h>
#include <metal_stdlib>
using namespace metal;

static constexpr sampler textureSampler(mag_filter::nearest,
                                        min_filter::nearest);

float4 layer_get_color(const device BMKLayerContext *context,
                       texture2d<float> texture, float4 point) {
    const float4 p = context->textureProjection * point;
    const float4 color = texture.sample(textureSampler, p.xy / p.w);
    return (float4)color;
}
