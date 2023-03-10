typedef struct {
    float4 color;     // color,0,0,0,0.25
} ShadowUniforms;

fragment float4 shadowFragment
(
    VertexData in [[stage_in]],
    // inject shadow fragment args
    constant ShadowUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]]
)
{
    float4 outColor = 0.0;
    // inject shadow fragment calc
    outColor = uniforms.color;
    outColor.a *= 1.0 - shadow;
    return outColor;
}