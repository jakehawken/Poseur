//
//  FakeHelpers.swift
//  Poseur
//
//  Created by Jake Hawken on 5/20/21.
//

import Foundation

public extension Array where Element==Any? {
    
    /// Method for force-casting arguments in an `andDo(_:)` closure without having to resort to using `!` over and over again.
    /// - parameter ofType: The expected type of the argument. If assigning to an explictly-typed variable, this parameter can be omitted, as the type will be inferred.
    /// - parameter atIndex: The index in the array at which you expect to find the argument.
    /// - returns: The expected argument, if it exists and is of the expected type. If not, then this method will cause a `fatalError` crash with a description of the problem.
    func argument<T>(ofType argType: T.Type = T.self, atIndex index: Int) -> T {
        guard index >= 0 && index < count else {
            fatalError("\(index) is not a valid argument index in \(self).")
        }
        guard let expectedArg = self[index] as? T else {
            fatalError("""
                        Expected argument at index \(index) to be of type \(argType), but got \(type(of: self[index])) instead.
                        Either the recorded arguments in the fake are incorrect or the expectations in the test are incorrect.
                       """)
        }
        return expectedArg
    }
    
}
