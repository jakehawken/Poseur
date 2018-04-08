//  JakeFake.swift
//  Created by Jake Hawken on 7/19/17.
//  Copyright © 2017 Geocaching. All rights reserved.

import Foundation


protocol JakeFakeFunction: Hashable {
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
    
    private struct Stub<T> {
        let method: Function
        let execution: (()->T?)?
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
    
    private var methodStubs = [Int:[Stub<Any>]]()
    
    func stub<T>(_ method: Function, andDo block:(()->T?)?) {
        let stub: Stub<T> = Stub(method: method, execution: block)
        if methodStubs[method.hashValue] != nil {
            methodStubs[method.hashValue]?.append(stub as! Stub<Any>)
        } else {
            methodStubs[method.hashValue] = [stub as! Stub<Any>]
        }
    }
    
    func stubbedValue(_ functionName:String = #function, method: Function) -> Any? {
        guard let stubs = methodStubs[method.hashValue],
            let stub = stubs.filter({ $0.method == method}).last else {
                fatalError("Method \(functionName) not stubbed.")
        }
        return stub.execution?()
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
        guard let value = faker.stubbedValue(method: method) as? T else {
            fatalError("\(method) stubbed with the wrong type")
        }
        return value
    }
}


enum DogFood {
    case dry
    case wet
    case tableScraps
    
    var digested: String {
        switch self {
        case .dry:
            return "Moderately stinky"
        case .wet:
            return "Super stinky"
        case .tableScraps:
            return "Troubled"
        }
    }
}

class Dog {
    
    private var stomach = [DogFood]()
    private var shouldPoop = false
    
    func bark() -> String {
        return "woof!"
    }
    
    func eat(food: DogFood) {
        stomach.append(food)
    }
    
    func digest() -> String? {
        if shouldPoop {
            let firstEaten = stomach.removeFirst()
            return firstEaten.digested
        }
        shouldPoop = !shouldPoop
        return nil
    }
}

class FakeDog: Dog, JakeFake {
    enum Function: JakeFakeFunction {
        case bark
        case eat(DogFood)
        case digest
        
        public static func ==(lhs: Function, rhs: Function) -> Bool {
            switch (lhs, rhs) {
            case (.eat(let food1), .eat(let food2)):
                return food1 == food2
            case (.bark, .bark), (.digest, .digest):
                return true
            default:
                return false
            }
        }
        
        public var hashValue: Int {
            switch self {
            case .bark:
                return 0
            case .eat(_):
                return 1
            case .digest:
                return 2
            }
        }
    }
    
    let faker: JakeFaker<Function> = JakeFaker()
    
    //MARK: - overrides
    
    override func bark() -> String {
        recordCall(.bark)
        return stubbedValue(method: .bark, asType: String.self)!
    }
    
    override func eat(food: DogFood) {
        recordCall(.eat(food))
    }
    
    override func digest() -> String? {
        recordCall(.digest)
        return stubbedValue(method: .digest, asType: String.self)
    }
}

let dog = FakeDog()
dog.eat(food: .tableScraps)
dog.received(method: .eat(.tableScraps))

dog.stub(.digest) { () -> Any? in
    return "Upset tummy"
}
dog.digest()
dog.received(method: .digest)

dog.reset()  //THIS CLEARS ALL THE STUBS AND CALLS

dog.eat(food: .dry)
dog.eat(food: .wet)

dog.received(method: .eat(.tableScraps))
dog.callCountFor(method: .eat(.tableScraps))

dog.received(method: .eat(.tableScraps), ignoreArguments: true)
dog.callCountFor(method: .eat(.tableScraps), ignoreArguments: true)
