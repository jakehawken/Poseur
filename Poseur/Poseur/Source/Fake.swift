//  Fake.swift
//  Poseur
//  Created by Jacob Hawken on 1/17/21.

import Foundation

/// Protocol that the `Function` type on `Fake` must conform to.
public protocol PoseurFunction: Hashable, RawRepresentable where RawValue == String {
}

// MARK: - Fake protocol

public protocol Fake {
    
    /// A closure used to validate arguments passed to a function.
    typealias ArgsCheck = ([Any?]) -> Bool
    
    /// A closure which can be used to represent a function call.
    typealias FunctionCall = ([Any?]) -> Any?
    
    /// A type used to enumerate the functions that are stubbable by this fake.
    ///
    /// It is recommended that be an enum:
    ///
    /// `enum Function: String, PoseurFunction`
    associatedtype Function: PoseurFunction
    
    /// This object to which the default implementation of `Fake` passes through. Each method called passes
    /// through to an identical method on the `faker`.
    ///
    /// The simplest way to implement this is to call the static builder on `Function`
    /// as demonstrated here:
    ///
    /// `let faker = Function.faker()`
    var faker: Faker<Function> { get }
    
    // MARK: Resetting
    
    /// Removes all recorded method calls and method stubs.
    func reset()
    /// Removes all stubs and recorded method calls for a given function.
    func resetFunction(_ function: Function)
    /// Removes all recorded method calls for a given function.
    func removeMethodCalls(for function: Function)
    /// Removes all stubs for a given function.
    func removeAllStubs(for function: Function)
    /// Removes the universal stub, if one exists, for a given function.
    func removeUniversalStub(for function: Function)
    
    // MARK: Spying
    
    /// Records that the method was called and the arguments it was passed.
    func recordCall(_ function: Function, arguments: Any?...)
    
    /// Returns the total number of calls made to a given function.
    func callCountFor(function: Function) -> Int
    
    /// Returns the number of calls made to a given function for which the `ArgsCheck` closure evaulates to `true`.
    func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int
    
    /// Returns the number of calls made to a given function for which the `faker` is able to automatically determine
    /// that the arguments match.
    ///
    /// This is the most elegant-looking and easy-to-read of the `receivedCall` methods to call, but relies heavily on the types of
    /// the arguments passed. It is recommended, if you use this method, that as many arguments as possible conform to `Equatable`
    /// and `AnyEquatable`. (A small, starting list of conforming types exists in `AnyEquatable.swift`)
    ///
    /// The default implementation evaluates the arguments in the following priority order:
    /// 1. The types are checked, and if the arguments are two diffrent types, it return `false`.
    /// 2. If the argument in the recorded call conforms to `AnyEquatable`, it evaluates equality based on that.
    /// 3. If the arguments are both classes, pointer comparison (`===`) is employed.
    /// 4. Both arguments are interpolated into strings and the strings are compared to one another.
    ///
    /// - parameter function: The `Function` to get the call count for.
    /// - parameter withArguments: The array of expected arguments to check for.
    /// - returns: The number of times that function was called with the given arguments.
    func callCountFor(function: Function, withArguments args: Any?...) -> Int
    
    /// Returns `true` if any calls have been made to the given function. Agnostic to the arguments passed.
    func receivedCall(to function: Function) -> Bool
    
    /// Returns `true` if any calls have been made to the given function for which the `ArgsCheck` closure evaulates to `true`.
    func receivedCall(to function: Function, where argsMatch: ArgsCheck) -> Bool
    
    /// Returns `true` if any calls have been made to the given function for which the `faker` is able to automatically
    /// determine that the arguments match.
    ///
    /// This is the most elegant-looking and easy-to-read of the `receivedCall` methods to call, but relies heavily on the types of
    /// the arguments passed. It is recommended, if you use this method, that as many arguments as possible conform to `Equatable`
    /// and `AnyEquatable`. (A small, starting list of conforming types exists in `AnyEquatable.swift`)
    ///
    /// The default implementation evaluates the arguments in the following priority order:
    /// 1. The types are checked, and if the arguments are two diffrent types, it return `false`.
    /// 2. If the argument in the recorded call conforms to `AnyEquatable`, it evaluates equality based on that.
    /// 3. If the arguments are both classes, pointer comparison (`===`) is employed.
    /// 4. Both arguments are interpolated into strings and the strings are compared to one another.
    ///
    /// - parameter function: The `Function` we're checking has been called.
    /// - parameter withArguments: The array of expected arguments to check for.
    /// - returns: A boolean representing whether or not the function has been called with the given arguments.
    func receivedCall(to function: Function, withArguments args: Any?...) -> Bool
    
    // MARK: Stubbing
    
    /// A "universal stub," which means that the stubbed value will be returned, regardless of the arguments passed to the function.
    /// - parameter function: The function to stub.
    /// - returns: An item conforming to `Stubbable`, to which a stubbed return value can be provided.
    func stub(function: Function) -> Stubbable
    
    /// Stubs a given function for all calls for which the `ArgsCheck` closure evaulates to `true`.
    ///
    /// It is important that implementations of the `ArgsCheck` closure be as unique as possible, since the first stub found
    /// for which the closure evaluates to `true` will be used, regardless of whether others exist.
    /// - parameter function: The function to stub.
    /// - parameter where: An `ArgsCheck` closure for determining which call to the method
    /// - returns: An item conforming to `Stubbable`, to which a stubbed return value can be provided.
    func stub(function: Function, where argsCheck: @escaping ArgsCheck) -> Stubbable
    
    /// Stubs a given function for all calls for which the `faker` is able to automatically determine that the arguments match.
    ///
    /// This is the most elegant-looking and easy-to-read of the `receivedCall` methods to call, but relies heavily on the types of
    /// the arguments passed. It is recommended, if you use this method, that as many arguments as possible conform to `Equatable`
    /// and `AnyEquatable`. (A small, starting list of conforming types exists in `AnyEquatable.swift`)
    ///
    /// The default implementation evaluates the arguments in the following priority order:
    /// 1. The types are checked, and if the arguments are two diffrent types, it return `false`.
    /// 2. If the argument in the recorded call conforms to `AnyEquatable`, it evaluates equality based on that.
    /// 3. If the arguments are both classes, pointer comparison (`===`) is employed.
    /// 4. Both arguments are interpolated into strings and the strings are compared to one another.
    ///
    /// - parameter function: The `Function` for the method we want to stub.
    /// - parameter withArguments: The array of expected arguments to check for.
    /// - returns: An item conforming to `Stubbable`, to which a stubbed return value can be provided.
    func stub(function: Function, withArguments args: Any?...) -> Stubbable
    
    /// Retrieves the stubbed value for a given function.
    ///
    /// - parameter function: The function to stub.
    /// - parameter asType: The expected return type. Most of the time, this argument can be removed, as it will be inferred.
    /// - parameter arguments: The arguments passed to the function.
    /// - returns: The stubbed value if there is one. A `fatalError` with a detailed error message will be thrown if there is not one.
    func stubbedValue<T>(forFunction function: Function, asType: T.Type, arguments: [Any?]) -> T
}

/// Interface for stubs that can have a single return value, or a closure which is calculated at the time method is invoked.
public protocol Stubbable {
    /// Stubbing method for setting a single return value for the stubbed method.
    func andReturn(_ value: Any?)
    
    /// Stubbing method for defining a closure to be executed at the time the stubbed method is invoked. If the method
    /// is non-void, this closure will have the responsibility of returning the correct type.
    func andDo(_ action: @escaping Fake.FunctionCall)
}

// MARK: - Default implementation of Fake

public extension Fake {
    
    func reset() {
        faker.reset()
    }
    
    func resetFunction(_ function: Function) {
        faker.resetFunction(function)
    }
    
    func removeMethodCalls(for function: Function) {
        faker.removeMethodCalls(for: function)
    }

    func removeAllStubs(for function: Function) {
        faker.removeAllStubs(for: function)
    }

    func removeUniversalStub(for function: Function) {
        faker.removeUniversalStub(for: function)
    }
    
    func recordCall(_ function: Function, arguments: Any?...) {
        faker.recordCall(function, arguments: arguments)
    }
    
    func receivedCall(to function: Function) -> Bool {
        return faker.receivedCall(to: function)
    }
    
    func receivedCall(to function: Function, where argsMatch: ArgsCheck) -> Bool {
        return faker.receivedCall(to: function, where: argsMatch)
    }
    
    func receivedCall(to function: Function, withArguments args: Any?...) -> Bool {
        return faker.receivedCall(to: function, withArguments: args)
    }
    
    func callCountFor(function: Function) -> Int {
        return faker.callCountFor(function: function)
    }
    
    func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int {
        return faker.callCountFor(function: function, where: argsMatch)
    }
    
    func callCountFor(function: Function, withArguments args: Any?...) -> Int {
        return faker.callCountForFunction(function, withArguments: args)
    }
    
    func stub(function: Function) -> Stubbable {
        faker.stub(function: function)
    }
    
    func stub(function: Function, where argsCheck: @escaping ArgsCheck) -> Stubbable {
        faker.stub(function: function, where: argsCheck)
    }
    
    func stub(function: Function, withArguments args: Any?...) -> Stubbable {
        faker.stub(function: function, withArgs: args)
    }
    
    func stubbedValue<T>(forFunction function: Function, asType: T.Type = T.self, arguments: [Any?]) -> T {
        guard let value = faker.stubbedValue(forFunction: function, arguments: arguments) as? T else {
            fatalError("\(function) stubbed with the wrong type")
        }
        return value
    }
    
}
