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
    float4 color;
};

vertex BrushOut brush_vertex(const device BMKStroke *vertices [[buffer(0)]],
                             device const BMKLayerContext *context
                             [[buffer(1)]],
                             texture2d<float> texture [[texture(2)]],
                             uint vertexID [[vertex_id]]) {
    BrushOut out;
    float3 v = vertices[vertexID].point;
    float4 point = context->layerProjection * float4(v.xy, 1, 1);
    out.position = point;
    out.size = context->brushSize * v.z;
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 brush_fragment(BrushOut in [[stage_in]],
                               float2 pointCoord [[point_coord]]) {

    if (length(pointCoord - float2(0.5)) > 0.5) {
        discard_fragment();
    }
    return in.color;
}
