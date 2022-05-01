//
//  BMKDefines.h
//  Bismush
//
//  Created by mzp on 4/30/22.
//

#ifndef BMKDefines_h
#define BMKDefines_h

#ifdef __METAL_VERSION__
#define TARGET_METAL 1
#else
#define TARGET_METAL 0
#endif // __METAL_VERSION__

#if TARGET_METAL
#include <metal_stdlib>
typedef metal::float4x4 float4x4;
#else
#import <Metal/Metal.h>
#include <simd/simd.h>
typedef simd_float2 float2;
typedef simd_float3 float3;
typedef simd_float4 float4;
typedef simd_float4x4 float4x4;
#endif // TARGET_METAL

#endif /* BMKDefines_h */
