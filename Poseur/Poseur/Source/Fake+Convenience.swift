//
//  Fake+Convenience.swift
//  Poseur
//
//  Created by Jake Hawken on 5/19/21.
//

import Foundation

public extension Fake {
    
    /// A convenience method which calls both `recordCall(_:)` and `stubbedValue(forFunction:asType:arguments:)`
    func recordAndStub<T>(function: Function, stubbedType: T.Type = T.self, arguments: Any?...) -> T {
        recordCall(function, argumentsArray: arguments)
        return stubbedValue(forFunction: function, asType: stubbedType, arguments: arguments)
    }
    
    /// A convenience method similar to `recordAndStub<T>(function:stubbedType:arguments:)` for use only when the
    /// raw value for the enum is a 1:1 with the stringified method signature (the value that would be returned by `#function`).
    func recordAndStub<T>(_ functionName: String = #function, stubbedType: T.Type = T.self, arguments: Any?...) -> T {
        guard let function = Function(rawValue: functionName) else {
            fatalError("Function string did not match an existing method.")
        }
        recordCall(function, argumentsArray: arguments)
        return stubbedValue(forFunction: function, asType: stubbedType, arguments: arguments)
    }
    
    /// Exists only to avoid confusing conflicts between arguments passed as an array, and arguments passed variadically.
    private func recordCall(_ function: Function, argumentsArray: [Any?]) {
        faker.recordCall(function, arguments: argumentsArray)
    }
    
}
