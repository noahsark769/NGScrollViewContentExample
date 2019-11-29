//
//  Shaders.metal
//  MetalBoilerplate Shared
//
//  Created by Noah Gilmore on 11/18/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Vertex {
    float3 position [[attribute(0)]];
};

struct ColorInOut {
    float4 position [[position]];
};

struct Uniforms {
    float4x4 projectionMatrix;
};

vertex ColorInOut vertexShader(device Vertex *vertices [[buffer(0)]],
                               constant Uniforms *uniforms [[ buffer(1) ]],
                               uint vertexId [[vertex_id]])
{
    ColorInOut out;

    float4 position = float4(vertices[vertexId].position, 1.0);
    out.position = uniforms->projectionMatrix * position;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(0) ]])
{
    return float4(1, 0, 0, 1);
}
