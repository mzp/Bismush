//
//  BMKLayerContext.h
//  Bismush
//
//  Created by mzp on 4/28/22.
//

#ifndef Renderer_h
#define Renderer_h

#include <BismushKit/BMKDefines.h>

struct BMKLayerContext {
    /// original brush color
    float4 brushColor;

    /// brush color mixed with around color
    float4 currentColor;
    float brushSize;
    float4x4 textureProjection; // LayerPixelCoordinate -> TextureCoordinate
    float4x4 layerProjection; // LayerPixelCoordinate -> LayerCoordinate
};

#if TARGET_METAL
float4 layer_get_color(const device BMKLayerContext *context,
                       metal::texture2d<float> texture,
                       const float4 point);
#endif

#endif /* Renderer_h */
