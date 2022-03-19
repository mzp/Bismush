//
//  Canvas.metal
//  Bismush
//
//  Created by mzp on 3/16/22.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  vector_float2 position;
  vector_float2 textureCoordinate;
};

struct VertexOut {
  float4 position [[position]];
  float2 textureCoordinate;
};

vertex VertexOut canvas_vertex(const device VertexIn *vertices [[buffer(0)]],
                               const device vector_uint2 *viewPortSize [[buffer(1)]],
                               uint vertexID [[vertex_id]]) {
  VertexOut out;

  float2 positionInPixelSpace = vertices[vertexID].position.xy;
  float2 viewportSize = float2(*viewPortSize);

  out.position = vector_float4(0, 0, 0, 1.0);
  out.position.xy = positionInPixelSpace / (viewportSize / 2.0);
  out.textureCoordinate = vertices[vertexID].textureCoordinate;
    
  return out;
}

fragment float4 canvas_fragment(VertexOut in [[stage_in]],
                                texture2d<half> colorTexture [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}
