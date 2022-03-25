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


vertex VertexOut basic_vertex( const VertexIn vertexIn [[stage_in]], constant vector_uint2 *viewportSizePointer [[buffer(1)]]) {
    
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

