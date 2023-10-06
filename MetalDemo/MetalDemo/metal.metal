//
//  metal.metal
//  MetalDemo
//
//  Created by Saheem Hussain on 26/09/23.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    // This member variable represents the position of a vertex in 3D space.
    /// It is a float4, which typically means it's a 4D vector (x, y, z, w) that holds the position information.
    ///The [[attribute(0)]] syntax indicates that this member is bound to attribute location 0.
    ///In graphics programming, attribute locations are used to specify how vertex data is passed to the shader.
    float4 position [[attribute(0)]];
};

//Shader functions

/// Vertex function - used to manipulate vertex positions
vertex float4 vertex_main(const VertexIn vertex_in [[stage_in]]) {
    return vertex_in.position;
}

/// Fragment function - used to specify the pixel color
fragment float4 fragment_main() {
    return float4(0, 0.4, 0.21, 1);
}

