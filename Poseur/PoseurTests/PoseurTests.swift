//
//  PoseurTests.swift
//  PoseurTests
//
//  Created by Jacob Hawken on 1/17/21.
//

import Poseur
import XCTest

class FakeTests: XCTestCase {
    
    var subject: FakeDog!

    override func setUpWithError() throws {
        subject = FakeDog()
    }

    override func tearDownWithError() throws {
        subject = nil
    }
    
    func testSimpleSpying() {
        subject.eat(food: .canned)
        subject.eat(food: .canned)
        subject.eat(food: .canned)
        XCTAssertTrue(subject.receivedCall(to: .eat))
        XCTAssertEqual(subject.callCountFor(function: .eat), 3)
        XCTAssertFalse(subject.receivedCall(to: .bark))
        XCTAssertEqual(subject.callCountFor(function: .bark), 0)
    }
    
    func testArgsCheckSpying() {
        subject.stub(function: .rollOntoTummy).andReturn("Tail wag")
        _ = subject.rollOntoTummy(getARub: true)
        _ = subject.rollOntoTummy(getARub: false)
        _ = subject.rollOntoTummy(getARub: true)
        
        let receivedWithTrue = subject.receivedCall(to: .rollOntoTummy) { (arguments) -> Bool in
            (arguments[0] as? Bool) == true
        }
        XCTAssertTrue(receivedWithTrue)
        
        let callCountForTrue = subject.callCountFor(function: .rollOntoTummy) { (arguments) -> Bool in
            (arguments[0] as? Bool) == true
        }
        XCTAssertEqual(callCountForTrue, 2)
        
        let receivedWithFalse = subject.receivedCall(to: .rollOntoTummy) { (arguments) -> Bool in
            (arguments[0] as? Bool) == false
        }
        XCTAssertTrue(receivedWithFalse)
        
        let callCountForFalse = subject.callCountFor(function: .rollOntoTummy) { (arguments) -> Bool in
            (arguments[0] as? Bool) == false
        }
        XCTAssertEqual(callCountForFalse, 1)
    }
    
    func testArgumentListSpying() {
        subject.stub(function: .shouldFetch).andReturn(false)
        _ = subject.shouldFetch(.slippers, for: .parent)
        XCTAssertTrue(subject.receivedCall(to: .shouldFetch, withArguments: FetchableItem.slippers, FamilyMember.parent))
        XCTAssertFalse(subject.receivedCall(to: .shouldFetch, withArguments: FetchableItem.ball, FamilyMember.kid))
    }
    
    func testSimpleStubbing() {
        subject.stub(function: .bark).andReturn("Meow")
        XCTAssertEqual(subject.bark(), "Meow")
        subject.stub(function: .bark).andReturn("Moo")
        XCTAssertEqual(subject.bark(), "Moo")
    }
    
    func testArgsCheckStubbing() {
        subject.stub(function: .rollOntoTummy, where: { ($0[0] as? Bool) == false }).andReturn("HOWL")
        subject.stub(function: .rollOntoTummy, where: { ($0[0] as? Bool) == true }).andReturn("GO CRAZY")
        XCTAssertEqual(subject.rollOntoTummy(getARub: false), "HOWL")
        XCTAssertEqual(subject.rollOntoTummy(getARub: true), "GO CRAZY")
    }
    
    func testAndDoStubbing() {
        subject.stub(function: .shouldFetch).andDo { (arguments) -> Bool in
            let fetchableItem = arguments[0] as! FetchableItem
            let familyMember = arguments[1] as! FamilyMember
            switch (fetchableItem, familyMember) {
            case (.slippers, .kid):
                return true
            default:
                return false
            }
        }
        XCTAssertTrue(subject.shouldFetch(.slippers, for: .kid))
        XCTAssertFalse(subject.shouldFetch(.slippers, for: .parent))
    }
    
    func testArgumentListStubbing() {
        subject.stub(function: .shouldFetch, withArguments: FetchableItem.slippers, FamilyMember.kid).andReturn(true)
        subject.stub(function: .shouldFetch, withArguments: FetchableItem.ball, FamilyMember.parent).andReturn(false)
        subject.stub(function: .shouldFetch, withArguments: FetchableItem.ball, FamilyMember.kid).andReturn(true)
        XCTAssertEqual(subject.shouldFetch(.slippers, for: .kid), true)
        XCTAssertEqual(subject.shouldFetch(.ball, for: .parent), false)
        XCTAssertEqual(subject.shouldFetch(.ball, for: .kid), true)
    }
    
    func testGenericStubOverridesSpecificStub() {
        subject.stub(function: .rollOntoTummy).andReturn("Good dog")
        subject.stub(function: .rollOntoTummy, withArguments: true).andReturn("Bad dog.")
        XCTAssertEqual(subject.rollOntoTummy(getARub: true), "Good dog")
    }

}

// Types

class FakeDog: Dog, Fake {
    
    enum Function: String, PoseurFunction {
        case bark
        case eat
        case digest
        case rollOntoTummy
        case shouldFetch
    }
    
    lazy var faker = Function.faker()

    //MARK: - overrides
    
    override func bark() -> String {
        return recordAndStub(function: .bark)
    }

    override func eat(food: DogFood) {
        recordCall(.eat, arguments: food)
    }

    override func digest() -> String? {
        return recordAndStub(function: .digest)
    }
    
    override func rollOntoTummy(getARub: Bool) -> String {
        return recordAndStub(function: .rollOntoTummy,
                             arguments: getARub)
    }
    
    override func shouldFetch(_ item: FetchableItem, for familyMember: FamilyMember) -> Bool {
        return recordAndStub(function: .shouldFetch, arguments: item, familyMember)
    }
    
}

enum DogFood: Equatable, Hashable {
    case kibble
    case canned
    case tableScraps
    
    var digested: String {
        self == .tableScraps ? "Sick puppy." : "Poop."
    }
}

enum FetchableItem: Equatable {
    case ball
    case slippers
}

enum FamilyMember: Equatable, AnyEquatable {
    case parent
    case kid
}

class Dog {

    private var stomach = [DogFood]()
    private var shouldPoop = false
    private static let barks = ["woof!", "bork!", "yip!"]

    func bark() -> String {
        return Dog.barks.randomElement() ?? "glorf?"
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
    
    func rollOntoTummy(getARub: Bool) -> String {
        if getARub {
            return "Panting sounds..."
        }
        return "Whimpering"
    }
    
    func shouldFetch(_ item: FetchableItem, for familyMember: FamilyMember) -> Bool {
        switch (item, familyMember) {
        case (.slippers, .kid):
            return false
        default:
            return true
        }
    }
    
}
