//  AnyEquatable.swift
//  Poseur
//  Created by Jacob Hawken on 1/19/21.

import Foundation

public protocol AnyEquatable {
    func isEqualTo(_ other: Any?) -> Bool
}

public extension AnyEquatable where Self:Equatable {
    
    func isEqualTo(_ other: Any?) -> Bool {
        if let otherAsSelf = other as? Self {
            return otherAsSelf == self
        }
        return false
    }
    
}

extension Optional: AnyEquatable where Wrapped:Equatable {
    
    public func isEqualTo(_ other: Any?) -> Bool {
        guard let otherAsSelf = other as? Self else {
            return false
        }
        switch (self, otherAsSelf) {
        case (.none, .none):
            return true
        case (.some(let value1), .some(let value2)):
            return value1 == value2
        default:
            return false
        }
    }
    
}

extension Bool: AnyEquatable {}
extension String: AnyEquatable {}
extension Int: AnyEquatable {}
extension Float: AnyEquatable {}
extension Double: AnyEquatable {}
extension NSNumber: AnyEquatable {}
