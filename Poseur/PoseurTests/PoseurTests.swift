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
    
    func testSimpleStubbing() {
        subject.stub(function: .bark).andReturn("Meow")
        XCTAssertEqual(subject.bark(), "Meow")
        subject.stub(function: .bark).andReturn("Moo")
        XCTAssertEqual(subject.bark(), "Moo")
    }
    
    func testArgumentListStubbing() {
        subject.stub(function: .rollOntoTummy, withArguments: true).andDo { return "TRY TO BITE" }
        subject.stub(function: .rollOntoTummy, withArguments: false).andDo { return "GROWL" }
        XCTAssertEqual(subject.rollOntoTummy(getARub: true), "TRY TO BITE")
        XCTAssertEqual(subject.rollOntoTummy(getARub: false), "GROWL")
    }
    
    func testArgsCheckStubbing() {
        subject.stub(function: .rollOntoTummy, where: { ($0[0] as? Bool) == false }).andReturn("HOWL")
        subject.stub(function: .rollOntoTummy, where: { ($0[0] as? Bool) == true }).andReturn("GO CRAZY")
        XCTAssertEqual(subject.rollOntoTummy(getARub: false), "HOWL")
        XCTAssertEqual(subject.rollOntoTummy(getARub: true), "GO CRAZY")
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
    }
    
    lazy var faker = Function.faker()

    //MARK: - overrides
    override func bark() -> String {
        return recordAndStub(function: .bark, asType: String.self)
    }

    override func eat(food: DogFood) {
        recordCall(.eat, arguments: food)
    }

    override func digest() -> String? {
        return recordAndStub(function: .digest, asType: String.self)
    }
    
    override func rollOntoTummy(getARub: Bool) -> String {
        return recordAndStub(function: .rollOntoTummy,
                             asType: String.self,
                             arguments: getARub)
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
    
}
