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
constant constexpr float kCircle = 50;
constant constexpr float kEffect = 0.8;

kernel void water_color_init(device float4 *currentColor
                             [[buffer(0)]] /* out */,
                             texture2d<float> texture [[texture(1)]],
                             device const BMKLayerContext *context
                             [[buffer(2)]],
                             device const BMKStroke &stroke [[buffer(3)]]) {
    const float4 destinationColor =
        layer_get_color(context, texture, float4(stroke.point.xy, 0, 1));
    currentColor->xyz = context->brushColor.xyz;

    if (destinationColor.w > 0) {
        currentColor->xyz +=
            kEffect * (destinationColor.xyz - context->brushColor.xyz);
    }
}

kernel void water_color_mix(device BMKStroke *strokes [[buffer(0)]] /* out */,
                            device const uint &count [[buffer(1)]],
                            device float4 &currentColor [[buffer(2)]] /* out */,
                            texture2d<float> texture [[texture(3)]],
                            device const BMKLayerContext *context
                            [[buffer(4)]]) {

    for (uint i = 0; i < count; i++) {
        const float3 point = strokes[i].point;

        // update
        const float4 destinationColor =
            layer_get_color(context, texture, float4(point.xy, 0, 1));
        float opacity = context->brushColor.w * max(point.z, 0.2);
        strokes[i].color =
            float4(currentColor.xyz, max(opacity, float(destinationColor.w)));

        // mix with around color
        const float cr = max(kCircle * point.z, 1.0);

        const float4 points[] = {float4(point.x - cr, point.y - cr, 0, 1),
                                 float4(point.x - cr, point.y + cr, 0, 1),
                                 float4(point.x + cr, point.y - cr, 0, 1),
                                 float4(point.x + cr, point.y + cr, 0, 1)};

        float3 totalColor = float3(0, 0, 0);
        uint count = 0;
        for (uint i = 0; i < sizeof(points) / sizeof(points[0]); i++) {
            const float4 color = layer_get_color(context, texture, points[i]);
            if (color.w > 0) {
                totalColor += color.xyz;
                count += 1;
            }
        }

        if (count > 0) {
            // Average colors around the point
            const float3 average_color = (float3)(totalColor / count);

            // Provide effects from around colors
            currentColor.xyz += (average_color - currentColor.xyz) * kAround;
        }

        // Provide effects from brush color
        currentColor.xyz +=
            (context->brushColor.xyz - currentColor.xyz) * kBrush;
    }
}
