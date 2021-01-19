//  Fake.swift
//  Poseur
//  Created by Jacob Hawken on 1/17/21.

import Foundation

public protocol PoseurFunction: Hashable, RawRepresentable where RawValue == String {
}

public protocol Fake {
    typealias ArgsCheck = ([Any?]) -> Bool
    typealias MethodExecution = () -> Any?
    
    associatedtype Function: PoseurFunction
    var faker: Faker<Function> {get}
    func reset()
    
    // Spying
    func recordCall(_ method: Function, arguments: Any?...)
    func callCountFor(function: Function) -> Int
    func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int
    func received(function: Function) -> Bool
    func received(function: Function, where argsMatch: ArgsCheck) -> Bool
    
    // Stubbing
    func stub(function: Function) -> StubMaker
    func stub(function: Function, where argsCheck: @escaping ArgsCheck) -> StubMaker
    func stubbedValue<T>(forFunction function: Function, asType: T.Type, arguments: [Any?]) -> T
}

public extension Fake {
    
    func reset() {
        faker.reset()
    }
    
    // Spying
    
    func recordCall(_ method: Function, arguments: Any?...) {
        faker.recordCall(method, arguments: arguments)
    }
    
    func received(function: Function) -> Bool {
        return faker.received(function: function)
    }
    
    func received(function: Function, where argsMatch: ArgsCheck) -> Bool {
        return faker.received(function: function, where: argsMatch)
    }
    
    func receivedCall(toFunction function: Function, withArguments args: Any?...) -> Bool {
        return faker.receivedCall(toFunction: function, withArguments: args)
    }
    
    func callCountFor(function: Function) -> Int {
        return faker.callCountFor(function: function)
    }
    
    func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int {
        return faker.callCountFor(function: function, where: argsMatch)
    }
    
    func callCountForFunction(_ function: Function, withArguments args: Any?...) -> Int {
        return faker.callCountForFunction(function, withArguments: args)
    }
    
    func stub(function: Function) -> StubMaker {
        faker.stub(function: function)
    }
    
    func stub(function: Function, where argsCheck: @escaping ArgsCheck) -> StubMaker {
        faker.stub(function: function, where: argsCheck)
    }
    
    func stub(function: Function, withArguments args: Any?...) -> StubMaker {
        faker.stub(function: function, withArgs: args)
    }
    
    func stubbedValue<T>(forFunction function: Function, asType: T.Type = T.self, arguments: [Any?]) -> T {
        guard let value = faker.stubbedValue(forFunction: function, arguments: arguments) as? T else {
            fatalError("\(function) stubbed with the wrong type")
        }
        return value
    }
    
}

public extension Fake {
    
    /// A convenience method which calls both `recordCall(_:)` and `stubbedValue(forFunction:asType:arguments:)`
    func recordAndStub<T>(function: Function, asType: T.Type = T.self, arguments: Any?...) -> T {
        recordCall(function)
        return stubbedValue(forFunction: function, asType: T.self, arguments: arguments)
    }
    
}
