//
//  Shaders.metal
//  metalTest
//
//  Created by Tom Rudnick on 15.03.22.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float pointSize [[attribute(1)]];
    float4 color [[attribute(2)]];
};


struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};
struct TVertexIn{
    float3 position [[attribute(0)]];
    float2 texturePosition [[attribute(1)]];
};
struct TVertexOut {
    float4 position [[position]];
    float2 texturePosition;
};

vertex VertexOut basic_vertex(const VertexIn vertexIn [[stage_in]], constant vector_uint2 *viewportSizePointer [[buffer(1)]]) {
    
    float2 pixelSpacePosition = vertexIn.position.xy;
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    VertexOut vertexOut;
    
    vertexOut.position = float4(pixelSpacePosition / (viewportSize / 512 * 2.0), vertexIn.position.z, 1.0);
    vertexOut.pointSize = vertexIn.pointSize;
    vertexOut.color = vertexIn.color;
    return vertexOut;
}

fragment half4 basic_fragment(VertexOut fragData [[stage_in]],
                              float2 pointCoord [[point_coord]]){
    
    float dist = length(pointCoord - float2(0.5));
    float4 out_color = fragData.color;
    out_color.a = 1.0 - smoothstep(0.4, 0.5, dist);
    return half4(out_color);
}

fragment float4 fragment_maliang(VertexOut fragData [[stage_in]],
                              float2 pointCoord [[point_coord]]){
    
    float dist = length(pointCoord - float2(0.5));
    if (dist >= 0.5) {
        return float4(0);
    }
    return fragData.color;
}

vertex TVertexOut tvertex(const TVertexIn vertexIn [[stage_in]], constant vector_uint2 *viewportSizePointer [[buffer(1)]]) {
    
    float2 pixelSpacePosition = vertexIn.position.xy;
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    TVertexOut vertexOut;
    
    //vertexOut.position = float4(pixelSpacePosition, vertexIn.position.z, 1.0);
    vertexOut.position = float4(pixelSpacePosition / (viewportSize / 1024 * 0.5), vertexIn.position.z, 1.0);
    vertexOut.texturePosition = vertexIn.texturePosition;
    return vertexOut;
}

fragment half4 tfragment(TVertexOut vertexIn [[ stage_in ]], texture2d<float> texture [[ texture(0)]]){
    constexpr sampler textureSampler(filter::linear, address::repeat);
    float4 color = texture.sample(textureSampler, vertexIn.texturePosition);
    return half4(color.r,color.g,color.b, 1);
}
