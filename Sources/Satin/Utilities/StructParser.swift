//
//  StructParser.swift
//  Satin
//
//  Created by Reza Ali on 3/18/22.
//

import Metal

public func parseParameters(bufferStruct: MTLStructType) -> ParameterGroup {
    let params = ParameterGroup()
    for member in bufferStruct.members {
        let name = member.name.titleCase
        switch member.dataType {
        case .float:
            params.append(FloatParameter(name, 0.0, 0.0, 1.0))
        case .float2:
            params.append(Float2Parameter(name, .zero, .zero, .one))
        case .float3:
            params.append(Float3Parameter(name, .zero, .zero, .one))
        case .float4:
            params.append(Float4Parameter(name, .zero, .zero, .one))
        case .int:
            params.append(IntParameter(name, 0, 0, 1))
        case .int2:
            params.append(Int2Parameter(name, .zero, .zero, .one))
        case .int3:
            params.append(Int3Parameter(name, .zero, .zero, .one))
        case .int4:
            params.append(Int4Parameter(name, .zero, .zero, .one))
        case .bool:
            params.append(BoolParameter(name, false))
        default:
            break
        }
    }
    return params
}
