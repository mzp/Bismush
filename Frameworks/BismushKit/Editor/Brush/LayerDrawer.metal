//
//  Brush.metal
//  Bismush
//
//  Created by Hiro Mizuno on 4/29/22.
//

#include <BismushKit/BMKLayerContext.h>
#include <BismushKit/BMKStroke.h>
#include <metal_stdlib>

using namespace metal;

// TODO: App should provide this.
constant constexpr float kAround = 0.5;
constant constexpr float kBrush = 0.07;
constant constexpr float kEffect = 0.8;

static constexpr sampler textureSampler(mag_filter::nearest,
                                        min_filter::nearest);

struct BrushOut {
    float4 position [[position]];
    float size [[point_size]];
    float4 color;
};

vertex BrushOut brush_vertex(const device BMKStroke *vertices [[buffer(0)]],
                             const device BMKLayerContext *context
                             [[buffer(1)]],
                             texture2d<float> texture [[texture(2)]],
                             uint vertexID [[vertex_id]]) {
    /*
     // Current colorを更新する
     currentColor->xyz +=

     */
    //    context->currentColor.xyz = kEffect * (destinationColor.xyz -
    //    context->brushColor.xyz);

    BrushOut out;
    float3 v = vertices[vertexID].point;
    float4 point = context->layerProjection * float4(v.xy, 1, 1);
    out.position = point;
    out.size = context->brushSize * v.z;
    out.color = context->currentColor;

    float opacity = context->brushColor.w * max(v.z, 0.2);
    out.color.w = opacity;
    return out;
}

fragment float4 brush_fragment(BrushOut in [[stage_in]],
                               const device BMKLayerContext *context
                               [[buffer(0)]],
                               texture2d<float> texture [[texture(1)]],
                               float2 pointCoord [[point_coord]]) {
    float distance = length(pointCoord - float2(0.5));
    if (distance > 0.5) {
        discard_fragment();
        return float4(1, 1, 1, 0);
    }
    float4 color = in.color;

    // mix with around color
    const float cr = max(0.8 * context->brushSize / 2, 1.0);

    float2 point = in.position.xy;
    const float4 points[] = {float4(point.x - cr, point.y - cr, 0, 1),
                             float4(point.x - cr, point.y + cr, 0, 1),
                             float4(point.x + cr, point.y - cr, 0, 1),
                             float4(point.x + cr, point.y + cr, 0, 1)};

    float4 totalColor = float4(0, 0, 0, 0);
    uint count = 0;
    for (uint i = 0; i < sizeof(points) / sizeof(points[0]); i++) {
        const float4 color = layer_get_color(context, texture, points[i]);
        if (color.w > 0) {
            totalColor += color;
            count += 1;
        }
    }

    if (count > 0) {
        // Average colors around the point
        const float4 average_color = (totalColor / count);

        // Provide effects from around colors
        color.xyz += (average_color.xyz - color.xyz) * kAround;
        color.w = max(color.w, average_color.w);
    }

    /*
     // mix with around color
     const float cr = max(0.8 * context->brushSize * point.z / 2, 1.0);

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
     */

    return color;
}
