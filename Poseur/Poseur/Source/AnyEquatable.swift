//  AnyEquatable.swift
//  Poseur
//  Created by Jacob Hawken on 1/19/21.

import Foundation

public protocol AnyEquatable {
    func isEqualTo(_ other: Any?) -> Bool
}

public extension AnyEquatable where Self: Equatable {
    
    func isEqualTo(_ other: Any?) -> Bool {
        if let otherAsSelf = other as? Self {
            return otherAsSelf == self
        }
        return false
    }
    
}

extension Optional: AnyEquatable where Wrapped: Equatable {
    
    public func isEqualTo(_ other: Any?) -> Bool {
        switch (self, other) {
        case (.none, .none):
            // If self is nil, accept any nil as correct.
            return true
        case (.some(let wrappedValue), .some(let anyValue)):
            guard type(of: anyValue) == Wrapped.self,
                  let otherAsWrappedValue = anyValue as? Wrapped else {
                // Reject if the wrapped value of other is not the same as Wrapped on self
                return false
            }
            // If the Wrapped types match, compare them
            return wrappedValue == otherAsWrappedValue
        default:
            // Mismatched .some and .none cases should always fail.
            return false
        }
    }
    
}

// MARK: - Out-of-the-box Conforming types

extension Bool: AnyEquatable {}
extension String: AnyEquatable {}
extension Int: AnyEquatable {}
extension Float: AnyEquatable {}
extension Double: AnyEquatable {}
extension NSNumber: AnyEquatable {}
