//  Faker.swift
//  Poseur
//  Created by Jacob Hawken on 1/17/21.

import Foundation

public extension PoseurFunction {
    static func faker() -> Faker<Self> {
        return Faker<Self>()
    }
}

public class Faker<Function: PoseurFunction> {
    typealias ArgsCheck = ([Any?]) -> Bool
    
    func reset() {
        methodCalls.removeAll()
        argsAgnosticStubs.removeAll()
        argsSpecificStubs.removeAll()
    }
    
    //MARK: Spying
    
    private struct RecordedCall {
        let function: Function
        let arguments: [Any?]
    }
    
    private var methodCalls = [RecordedCall]()
    
    internal func recordCall(_ method: Function, arguments: [Any?]) {
        let call = RecordedCall(function: method, arguments: arguments)
        methodCalls.append(call)
    }
    
    func callCountFor(function: Function) -> Int {
        return methodCalls.filter { (call) -> Bool in
            call.function == function
        }.count
    }
    
    func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int {
        return methodCalls.filter { (call) -> Bool in
            call.function == function && argsMatch(call.arguments)
        }.count
    }
    
    func callCountForFunction(_ function: Function, withArguments args: Any?...) -> Int {
        let argsCheck = argumentWrapperCheck(fromArgs: args)
        return callCountFor(function: function, where: argsCheck)
    }
    
    func received(function: Function) -> Bool {
        return callCountFor(function: function) > 0
    }
    
    func received(function: Function, where argsMatch: ArgsCheck) -> Bool {
        return callCountFor(function: function, where: argsMatch) > 0
    }
    
    func receivedCall(toFunction function: Function, withArguments args: Any?...) -> Bool {
        return callCountForFunction(function, withArguments: args) > 0
    }
    
    //MARK: Stubbing
    
    private struct Stub {
        let function: Function
        let argsCheck: ArgsCheck?
        let execution: (()->Any?)
    }
    
    private var argsAgnosticStubs = [Function: Stub]()
    private var argsSpecificStubs = [Function: [Stub]]()
    
    func stub(function: Function) -> StubMaker {
        return StubMaker { [weak self] (stubbedAction) in
            let stub = Stub(function: function, argsCheck: nil, execution: stubbedAction)
            self?.argsAgnosticStubs[function] = stub
        }
    }
    
    func stub(function: Function, where argsCheck: @escaping ArgsCheck) -> StubMaker {
        return StubMaker { [weak self] (stubbedAction) in
            let stub = Stub(function: function,
                            argsCheck: argsCheck,
                            execution: stubbedAction)
            if self?.argsSpecificStubs[function] != nil {
                self?.argsSpecificStubs[function]?.append(stub)
            }
            else {
                self?.argsSpecificStubs[function] = [stub]
            }
        }
    }
    
    func stub(function: Function, withArgs args: [Any?]) -> StubMaker {
        let argsCheck = argumentWrapperCheck(fromArgs: args)
        return StubMaker { [weak self] (stubbedAction) in
            let stub = Stub(function: function,
                            argsCheck: argsCheck,
                            execution: stubbedAction)
            if self?.argsSpecificStubs[function] != nil {
                self?.argsSpecificStubs[function]?.append(stub)
            }
            else {
                self?.argsSpecificStubs[function] = [stub]
            }
        }
    }
    
    func stubbedValue(forFunction function: Function, arguments: [Any?]) -> Any? {
        if let godStub = argsAgnosticStubs[function] {
            return godStub.execution()
        }
        let specificStubs = argsSpecificStubs[function]
        let firstMatch = specificStubs?.first { (stub) -> Bool in
            stub.argsCheck?(arguments) ?? true
        }
        guard let specificStub = firstMatch else {
            fatalError("No stubs found for \(function).")
        }
        return specificStub.execution()
    }
    
}

private extension Faker {
    
    func argumentWrapperCheck(fromArgs args: [Any?]) -> ArgsCheck {
        let wrappers = args.map { ArgumentWrapper($0) }
        return { (arguments) -> Bool in
            guard arguments.count == wrappers.count else {
                fatalError("Wrong number of stubbed arguments. Expected \(wrappers.count). Received \(arguments.count).")
            }
            let zipped = zip(arguments, wrappers)
            return zipped.allSatisfy { (argPair) -> Bool in
                argPair.1.matchesArgument(argPair.0)
            }
        }
    }
    
}

public struct StubMaker {
    
    private(set) var actionAdded = false
    private let callback: (@escaping () -> Any?) -> ()
    
    fileprivate init(_ callback: @escaping (@escaping () -> Any?) -> ()) {
        self.callback = callback
    }
    
    public func andDo(_ action: @escaping () -> Any?) {
        if actionAdded {
            fatalError("A callback has already beed added for this stub.")
        }
        callback(action)
    }
    
    public func andReturn(_ value: Any?) {
        andDo { () -> Any? in
            return value
        }
    }
    
}
