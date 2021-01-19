//  ArgumentWrapper.swift
//  Poseur
//  Created by Jacob Hawken on 1/18/21.

import Foundation

struct ArgumentWrapper {
    
    typealias ArgsMatch = (Any?) -> Bool
    private let matchBlock: ArgsMatch
    
    init<T>(_ value: T?) {
        matchBlock = { (input) in
            guard ArgumentWrapper.argTypesMatch(value, rhs: input) else {
                return false
            }
            if let anyEqValue = value as? AnyEquatable {
                return anyEqValue.isEqualTo(input)
            }
            if let anyEqOther = input as? AnyEquatable {
                return anyEqOther.isEqualTo(value)
            }
            if let objValue = value as? AnyClass, let objInput = input as? AnyClass {
                return objValue === objInput
            }
            return String(describing: value) == String(describing: input)
        }
    }
    
    private static func argTypesMatch<T, Q>(_ lhs: T, rhs: Q) -> Bool {
        return T.self == Q.self
    }
    
    func matchesArgument(_ arg: Any?) -> Bool {
        return matchBlock(arg)
    }
    
}
