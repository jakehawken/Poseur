import Foundation

public protocol JakeFakeFunction: Hashable, RawRepresentable where RawValue == String {
}

public protocol JakeFake {
    
    typealias ArgsCheck = ([Any?]) -> Bool
    
    associatedtype Function: JakeFakeFunction
    var faker: JakeFaker<Function> {get}
    func reset()
    
    // Spying
    func recordCall(_ method: Function, arguments: Any?...)
    func callCountFor(function: Function) -> Int
    func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int
    func received(function: Function) -> Bool
    func received(function: Function, where argsMatch: ArgsCheck) -> Bool
    
    // Stubbing
    func stub(function: Function, andDo stubbedAction: @escaping (()->Any?))
    func stub(function: Function, where argsCheck: @escaping ArgsCheck, andDo stubbedAction: @escaping (()->Any?))
    func stubbedValue<T>(forFunction function: Function, asType: T.Type, arguments: Any?...) -> T
}

public class JakeFaker<Function: JakeFakeFunction> {
    public typealias ArgsCheck = ([Any?]) -> Bool
    
    public init() {}
    
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
    
    public func recordCall(_ method: Function, arguments: [Any?]) {
        let call = RecordedCall(function: method, arguments: arguments)
        methodCalls.append(call)
    }
    
    public func callCountFor(function: Function) -> Int {
        return methodCalls.filter { (call) -> Bool in
            call.function == function
        }.count
    }
    
    public func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int {
        return methodCalls.filter { (call) -> Bool in
            call.function == function && argsMatch(call.arguments)
        }.count
    }
    
    public func received(function: Function) -> Bool {
        return callCountFor(function: function) > 0
    }
    
    public func received(function: Function, where argsMatch: ArgsCheck) -> Bool {
        return callCountFor(function: function, where: argsMatch) > 0
    }
    
    //MARK: Stubbing
    
    private enum Arguments {
        case any
        case specific([Any?])
    }
    
    private struct Stub {
        let function: Function
        let argsCheck: ArgsCheck?
        let execution: (()->Any?)
    }
    
    private var argsAgnosticStubs = [Function: Stub]()
    private var argsSpecificStubs = [Function: [Stub]]()
    
    public func stub(function: Function, andDo stubbedAction: @escaping (()->Any?)) {
        let stub = Stub(function: function, argsCheck: nil, execution: stubbedAction)
        argsAgnosticStubs[function] = stub
    }
    
    public func stub(function: Function, where argsCheck: @escaping ArgsCheck, andDo stubbedAction: @escaping (()->Any?)) {
        let stub: Stub = Stub(function: function, argsCheck: argsCheck, execution: stubbedAction)
        if argsSpecificStubs[function] != nil {
            argsSpecificStubs[function]?.append(stub)
        } else {
            argsSpecificStubs[function] = [stub]
        }
    }
    
    public func stubbedValue(forFunction function: Function, arguments: Any?...) -> Any? {
        if let godStub = argsAgnosticStubs[function] {
            return godStub.execution()
        }
        let specificStubs = argsSpecificStubs[function]
        let firstMatch = specificStubs?.first {
            $0.argsCheck?(arguments) ?? false
        }
        guard let specificStub = firstMatch else {
            fatalError("No stubs found for \(function).")
        }
        return specificStub.execution()
    }
    
}

public extension JakeFake {
    
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
    
    func callCountFor(function: Function) -> Int {
        return faker.callCountFor(function: function)
    }
    
    func callCountFor(function: Function, where argsMatch: ArgsCheck) -> Int {
        return faker.callCountFor(function: function, where: argsMatch)
    }
    
    func stub(function: Function, andDo stubbedAction: @escaping (()->Any?)) {
        faker.stub(function: function, andDo: stubbedAction)
    }
    
    func stub(function: Function, where argsCheck: @escaping ArgsCheck, andDo stubbedAction: @escaping (()->Any?)) {
        faker.stub(function: function, where: argsCheck, andDo: stubbedAction)
    }
    
    func stubbedValue<T>(forFunction function: Function, asType: T.Type = T.self, arguments: Any?...) -> T {
        guard let value = faker.stubbedValue(forFunction: function, arguments: arguments) as? T else {
            fatalError("\(function) stubbed with the wrong type")
        }
        return value
    }
    
}

public extension JakeFake {
    
    /// A convenience method which calls both `recordCall(_:)` and `stubbedValue(method:asType:)`
    func recordAndStub<T>(function: Function, asType: T.Type, arguments: Any?...) -> T? {
        recordCall(function)
        return stubbedValue(forFunction: function, asType: T.self, arguments: arguments)
    }
    
}
