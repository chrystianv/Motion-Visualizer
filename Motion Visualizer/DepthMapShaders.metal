//
//  DepthMapShaders.metal
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/16/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    const float2 vertices[] = {
        float2(-1, -1),
        float2( 1, -1),
        float2(-1,  1),
        float2( 1,  1)
    };
    
    const float2 texCoords[] = {
        float2(0, 1),
        float2(1, 1),
        float2(0, 0),
        float2(1, 0)
    };
    
    VertexOut out;
    out.position = float4(vertices[vertexID], 0, 1);
    out.texCoord = texCoords[vertexID];
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> depthTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    // Rotate and flip the texture coordinates
    float2 rotatedCoords = float2(in.texCoord.y, 1.0 - in.texCoord.x);
    
    float depth = depthTexture.sample(textureSampler, rotatedCoords).r;
    
    // Adjust these values to change the visualization
    float minDepth = 0.0;
    float maxDepth = 5.0;
    
    float normalizedDepth = 1.0 - (depth - minDepth) / (maxDepth - minDepth);
    normalizedDepth = clamp(normalizedDepth, 0.0, 1.0);
    
    return float4(normalizedDepth, normalizedDepth, normalizedDepth, 1.0);
}
