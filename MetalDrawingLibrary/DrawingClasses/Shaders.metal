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
};


struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
};


vertex VertexOut basic_vertex( const VertexIn vertexIn [[stage_in]], constant vector_uint2 *viewportSizePointer [[buffer(1)]]) {
    
    float2 pixelSpacePosition = vertexIn.position.xy;
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    VertexOut vertexOut;
    
    vertexOut.position = float4(pixelSpacePosition / (viewportSize / 512 * 2.0), vertexIn.position.z, 1.0);
    vertexOut.pointSize = vertexIn.pointSize;
    //return float4(vertex_array[vid], 1.0);*/
    /*VertexOut vertexOut;
    vertexOut.position = float4(vertexIn.position, 1.0);
    vertexOut.pointSize = vertexIn.pointSize;*/
    //vertexOut.pointSize = vertexIn.pointSize;
    return vertexOut;
}

fragment half4 basic_fragment(VertexOut fragData [[stage_in]],
                              float2 pointCoord [[point_coord]]){
    
    float dist = length(pointCoord - float2(0.5));
    float4 out_color = float4(0.5, 0.3, 0.2, 1.0);
    out_color.a = 1.0 - smoothstep(0.4, 0.5, dist);
    return half4(out_color);
}

