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

struct BrushOut {
    float4 position [[position]];
    float size [[point_size]];
    float4 strokePoint;
    float4 color;
    float pressure;
};

vertex BrushOut brush_vertex(const device BMKStroke *vertices [[buffer(0)]],
                             device const BMKLayerContext *context
                             [[buffer(1)]],
                             texture2d<float> texture [[texture(2)]],
                             uint vertexID [[vertex_id]]) {
    BrushOut out;
    float3 v = vertices[vertexID].point;
    float4 point = context->layerProjection * float4(v.xy, 0, 1);
    out.position = point;
    out.size = context->brushSize * v.z;
    out.color = vertices[vertexID].color;
    out.strokePoint = float4(v.xy, 0, 1);
    out.pressure = v.z;
    return out;
}

fragment float4 brush_fragment(BrushOut in [[stage_in]],
                               device const BMKLayerContext *context
                               [[buffer(0)]],
                               texture2d<float> texture [[texture(1)]],
                               float2 pointCoord [[point_coord]]) {
    float distance = length(pointCoord - float2(0.5));
    if (distance > 0.5) {
        discard_fragment();
        return float4(1, 0, 0, 0.0);
    }
    float4 color = in.color;

    float opacity = in.color.w * max(in.pressure, 0.2);
    const float4 destination_color =
        layer_get_color(context, texture, in.strokePoint);
    color.w = max(min(0.8, opacity), destination_color.w);

    float2 point = in.strokePoint.xy;
    const float4 points[] = {float4(point.x - 1, point.y - 1, 0, 1),
                             float4(point.x - 1, point.y + 1, 0, 1),
                             float4(point.x + 1, point.y - 1, 0, 1),
                             float4(point.x + 1, point.y + 1, 0, 1)};

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
        color.xyz = color_mix(color.xyz, average_color, 0.1);
    }

    return color;
}
