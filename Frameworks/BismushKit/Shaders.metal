//
//  Canvas.metal
//  Bismush
//
//  Created by mzp on 3/16/22.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  float3 position;
  float4 color;
};

struct VertexOut {
  float4 position [[position]];
  float4 color;
};

vertex VertexOut canvas_vertex(const device VertexIn *vertices [[buffer(0)]],
                               uint vertexID [[vertex_id]]) {
  VertexOut out;
  out.position = float4(vertices[vertexID].position, 1);
  out.color = vertices[vertexID].color;
  return out;
}

fragment float4 canvas_fragment(VertexOut in [[stage_in]]) { return in.color; }
