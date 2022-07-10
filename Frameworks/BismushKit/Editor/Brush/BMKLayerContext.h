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
    float4 brushColor;
    float brushSize;
    float4x4 textureProjection; // LayerPixelCoordinate -> TextureCoordinate
    float4x4 layerProjection; // LayerPixelCoordinate -> LayerCoordinate
};

#if TARGET_METAL
float4 layer_get_color(const device BMKLayerContext *context,
                       metal::texture2d<float> texture,
                       const float4 point);
template<typename T>
T color_mix(T baseColor, T aditionalColor, float params) {
    return baseColor + (aditionalColor - baseColor) * params;
}
#endif

#endif /* Renderer_h */
