//
//  SessionCommit.metal
//  Bismush
//
//  Created by Hiro Mizuno on 7/11/22.
//

#include <metal_stdlib>
using namespace metal;

using namespace metal;

struct VertexIn {
    vector_float2 position;
    vector_float2 textureCoordinate;
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

static constexpr sampler textureSampler(mag_filter::nearest,
                                        min_filter::nearest);

vertex VertexOut session_commit_vertex(const device VertexIn *vertices [[buffer(0)]],
                             const device float4x4 &projection [[buffer(1)]],
                             uint vertexID [[vertex_id]]) {
    float2 layerPosition = vertices[vertexID].position.xy;

    VertexOut out;
    out.position = projection * vector_float4(layerPosition.xy, 0, 1.0);
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    return out;
}

fragment float4 layer_fragment(VertexOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    const float4 color = texture.sample(textureSampler, in.textureCoordinate);
    return float4(color);
}
