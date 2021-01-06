//  JakeFake.swift
//  Created by Jake Hawken on 7/19/17.
//  Copyright © 2017 Geocaching. All rights reserved.

import Foundation

// EXAMPLE:

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
}

class FakeDog: Dog, JakeFake {
    
    enum Function: String, JakeFakeFunction {
        case bark
        case eat
        case digest
    }
    
    lazy var faker = JakeFaker<Function>()

    //MARK: - overrides
    override func bark() -> String {
        recordCall(.bark)
        return stubbedValue(forFunction: .bark, asType: String.self)
    }

    override func eat(food: DogFood) {
        recordCall(.eat, arguments: food)
    }

    override func digest() -> String? {
        return recordAndStub(function: .digest, asType: String.self)
    }
    
}


let dog = FakeDog()
dog.eat(food: .tableScraps)
print(dog.received(function: .eat))                                                 // Should return true
print(dog.received(function: .eat, where: { $0[0] as? DogFood == .kibble }))        // Should return false
var receivedTableScraps = dog.received(function: .eat, where: { $0[0] as? DogFood == .tableScraps })
print(receivedTableScraps)   // Should return true

dog.stub(function: .digest) { () -> Any? in
    return "Upset tummy"
}
let returnedValue = dog.digest()!
print(returnedValue) // Should equal "Upset tummy"
print(dog.received(function: .digest)) // Should return true

dog.reset()

dog.eat(food: .kibble)
dog.eat(food: .canned)

receivedTableScraps = dog.received(function: .eat, where: { $0[0] as? DogFood == .tableScraps })
print(receivedTableScraps)       // Should return false
let callCountForTableScraps = dog.callCountFor(function: .eat, where: { $0[0] as? DogFood == .tableScraps })
print(callCountForTableScraps)   // Should return 0

print(dog.received(function: .eat))                             // SHOULD evaluate to true
print(dog.callCountFor(function: .eat))                         // SHOULD evaluate to 2
