//  JakeFake.swift
//  Created by Jake Hawken on 7/19/17.
//  Copyright © 2017 Geocaching. All rights reserved.

import Foundation

protocol JakeFakeFunction: Hashable, Equatable {
}

protocol JakeFake {
    associatedtype Function: JakeFakeFunction
    var faker: JakeFaker<Function> {get}
    func reset()
    func recordCall(_ method: Function)
    func received(method: Function, ignoreArguments: Bool) -> Bool
    func callCountFor(method: Function, ignoreArguments: Bool) -> Int
    func stub(_ method: Function, andDo block: (()->Any?)?)
    func stubbedValue<T>(method: Function, asType: T.Type) -> T?
}

class JakeFaker<Function: JakeFakeFunction> {

    typealias Execution = (()->Any?)

    private struct Stub {
        let method: Function
        let execution: Execution
    }

    func reset() {
        methodCalls.removeAll()
        methodStubs.removeAll()
    }

    //MARK: Spying

    private var methodCalls = [Int:[Function]]()

    internal func recordCall(_ method: Function) {
        if methodCalls[method.hashValue] != nil {
            methodCalls[method.hashValue]?.append(method)
        } else {
            methodCalls[method.hashValue] = [method]
        }
    }
    func received(method: Function, ignoreArguments:Bool=false) -> Bool {
        return callCountFor(method: method, ignoreArguments: ignoreArguments) > 0
    }
    func callCountFor(method: Function, ignoreArguments:Bool=false) -> Int {
        guard let calls = methodCalls[method.hashValue] else {
            return 0
        }
        if ignoreArguments {
            return calls.count
        }
        return calls.filter({ $0 == method}).count
    }

    //MARK: Stubbing

    private var methodStubs = [Int:[Stub]]()
    func stub(_ method: Function, andDo block:Execution?) {
        let execution: Execution = block ?? { _ in return Void() }
        let stub = Stub(method: method, execution: execution)
        if methodStubs[method.hashValue] != nil {
            methodStubs[method.hashValue]?.append(stub)
        } else {
            methodStubs[method.hashValue] = [stub]
        }
    }
    func stubbedValue(_ functionName:String = #function, method: Function) -> Any? {
        guard let stubs = methodStubs[method.hashValue],
            let stub = stubs.filter({ $0.method == method}).last else {
                fatalError("Method \(functionName) not stubbed.")
        }
        return stub.execution()
    }
}


extension JakeFake {
    func reset() {
        faker.reset()
    }
    func recordCall(_ method: Function) {
        faker.recordCall(method)
    }
    func received(method: Function, ignoreArguments:Bool=false) -> Bool {
        return faker.received(method: method, ignoreArguments: ignoreArguments)
    }
    func callCountFor(method: Function, ignoreArguments:Bool=false) -> Int {
        return faker.callCountFor(method: method, ignoreArguments: ignoreArguments)
    }
    func stub(_ method: Function, andDo block: (()->Any?)?) {
        faker.stub(method, andDo: block)
    }
    func stubbedValue<T>(method: Function, asType: T.Type) -> T? {
        if let value = faker.stubbedValue(method: method) as? T {
            return value
        }
        fatalError("\(method) stubbed with the wrong type")
    }
}
