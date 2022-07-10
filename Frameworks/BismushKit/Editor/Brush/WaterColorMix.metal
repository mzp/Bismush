//
//  WaterColor.metal
//  Bismush
//
//  Created by Hiro Mizuno on 4/29/22.
//

#include <BismushKit/BMKLayerContext.h>
#include <BismushKit/BMKStroke.h>
#include <metal_stdlib>
using namespace metal;

constant constexpr float kAround = 0.1;
constant constexpr float kBrush = 0.07;
constant constexpr float kEffect = 0.8;

kernel void water_color_init(device float4 &currentColor
                             [[buffer(0)]] /* out */,
                             texture2d<float> texture [[texture(1)]],
                             device const BMKLayerContext *context
                             [[buffer(2)]],
                             device const BMKStroke &stroke [[buffer(3)]]) {
    const float4 destinationColor =
        layer_get_color(context, texture, float4(stroke.point.xy, 0, 1));
    currentColor = context->brushColor;

    if (destinationColor.w > 0) {
        currentColor = color_mix(currentColor, destinationColor, kEffect);
    }
}

kernel void water_color_mix(device BMKStroke *strokes [[buffer(0)]] /* out */,
                            device const uint &count [[buffer(1)]],
                            device float4 &currentColor [[buffer(2)]] /* out */,
                            texture2d<float> texture [[texture(3)]],
                            device const BMKLayerContext *context
                            [[buffer(4)]]) {

    for (uint i = 0; i < count; i++) {
        strokes[i].color = currentColor;
        const float3 point = strokes[i].point;
        const float4 destinationColor =
            layer_get_color(context, texture, float4(point.xy, 0, 1));
        if (destinationColor.w > 0) {
            currentColor = color_mix(currentColor, destinationColor, kAround);
        }
        currentColor = color_mix(currentColor, context->brushColor, kBrush);
    }
}
