# Poseur

When writing unit tests, we want to test specific units of code, decoupled from the actual state of our application. To do this, we simulate the other units of code with which the subject communicates. Doing this is referred to as putting the subject into a “test harness.”

These simulated units of code are what we generally call “fakes.” They allow the test code to change the conditions around the subject to replicate known app states/conditions, such as the success or failure of a network call, or a specific state on a helper class. Changing how these fakes respond to being interacted with by the subject is called “stubbing” and recording whether or methods or properties have on the fake have been accessed is called “spying.”

Poseur is a bare-bones class and protocol for creating test fakes for stubbing/spying in Swift, inspired by the (more fully-featured framework) [Spry](https://github.com/Rivukis/Spry) framework.

## The Cast of Characters

Poseur has two main components:

#### 1. The `Faker<Function>` object

This object encapsulates most of the JakeFake functionality. It works as a helper object to manage the spying and stubbing for a given fake. It has a generic *Function* type which allows the user to implement any kind of object to define their method captures as long as that object conforms to `PoseurFunction` which simply is a bundling of the *Equatable* and *Hashable* protocols.

#### 2. The `Fake` protocol

This protocol is what your fake objects will actually conform to. It's designed to closely mirror the `Faker<Function>` object, so that in tests you can inspect the fake itself rather than having to inspect its `.faker` property. Since the majority of the protocol is intended to be passthrough to the faker, I have included a protocol extension which does exactly that. And thanks to that, all one needs to do to conform to the *JakeFake* is to define their `Function` type, and implement the ```faker``` property, which will include that type as its generic. I've even created a convenience extension method to `Function` so that all one need to do to implement that property is add this line: `let faker = Function.faker()`

A bit of advice: When you define your `Function` type, I recommend using an enum, as it gives you a finite set of cases, each corresponding to a given method.

# How to Use

Imagine, if you will, that you have a class called `Dog`:

```swift
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
```

## Conforming to Fake

Now imagine that `Dog` is a depency in a class, `HappyFamily`, that you're testing. As such, you want to generate a fake so that you can control `Dog`'s behavior in your tests. Poseur allows you to create a fake simply by creating a subclass of `Dog` that conforms to the `Fake` protocol, and then overriding its methods. Check it out!

```swift
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
```

Wasn't that easy?!

Notes:
- In `digest()`, `bark()`, and `rollOntoTummy(getARub:)`, we call `recordAndStub<T>(function:asType:arguments:)` which is a convenience method that calls both `recordCall(_:)` and `stubbedValue(forFunction:asType:arguments:)`. Ultimately allowing us to spy on arguments called 
- Since `eat(food:)` is a void method, and we're not wanting to trigger any special behavior for now, `recordCall(_:)` is all we need.

## The three approaches

Now, when interacting with Fakes, there are three main ways to access their fake-specific functionality.

1. Simple: ignoring the arguments passed to the function
2. `ArgsCheck`: using a custom block to respond to arguments
3. Argument List: providing a list of arguments

You'll see what I mean by these as you read on.

# Spying

Let's start take a `FakeDog`

```swift
let fakeDog = FakeDog()
```

and keep tabs on it!

## 1. Simple

Sometimes we just want to know if a method was called at all.

```swift
fakeDog.eat(food: .canned)
fakeDog.eat(food: .canned)
fakeDog.eat(food: .canned)

fakeDog.receivedCall(to: .eat) // returns true
fakeDog.callCountFor(function: .eat) // returns 3
```

Both `receivedCall(to:)` and `callCountFor(function:)` use the "simple" approach. That means that these methods are reporting on raw number of calls to this method, rather than calls with a specific set of arguments.

## 2. ArgsCheck

Sometimes we want to know what arguments are being passed.

```swift
_ = fakeDog.rollOntoTummy(getARub: true)
_ = fakeDog.rollOntoTummy(getARub: false)
_ = fakeDog.rollOntoTummy(getARub: true)

fakeDog.receivedCall(to: .rollOntoTummy) { (arguments) -> Bool in
    (arguments[0] as? Bool) == true
} // returns true

//or, written in a more compact form:
fakeDog.receivedCall(to: .rollOntoTummy, where: { ($0[0] as? Bool) == true })
```

This approach allows us to pass in a custom validation block that validates the arguments.

## 3. Argument List

This is the "automagic" option. Since arguments are passed to Poseur as `[Any?]` arrays, type checking can be very challenging. The argument list approach (for both spying and stubbing) does the following steps:

1. If the two arguments are diffrent types, return false
2. If the argument in the recorded call conforms to `AnyEquatable`, it uses that. (More on this in a bit.)
3. If the arguments are both classes, pointer comparison (`===`) is employed.

And finally, if none of that works,

4. The two arguments are interpolated into strings, and the strings are compared to one another.

`AnyEquatable` has one method: `func isEqualTo(_ other: Any?) -> Bool` allowing it to be compared to anything. It has a default implementation if the conforming type is already `Equatable`, which means that all you have to do to get an `Equatbale` type to conform to `AnyEquatable` is to tell it to, like so:

```swift
extension Bool: AnyEquatable {}
```

Poseur conforms several common types right out of the box, namely: `Bool`, `String`, `Int`, `Float`, `Double`, and `NSNumber`. The more you add to that list, the more automagic the argument list approach will be.

If nothing else, the argument list is certainly more beautiful looking than the ArgsCheck approach:

```swift
fakeDog.shouldFetch(.slippers, for: .parent)
fakeDog.receivedCall(to: .shouldFetch, 
                     withArguments: FetchableItem.slippers, FamilyMember.parent)
// returns true
fakeDog.receivedCall(to: .shouldFetch, 
                     withArguments: FetchableItem.ball, FamilyMember.kid)
// returns false
```

# Stubbing

----------[THIS SECTION COMING SOON]----------

# Thanks!
And that's about it! Feel free to ask me all about it, and report any bugs you find.

And in the meantime, if you want a more stable, strongly-typed, fully-featured stubbing/spying framework that integrates seamlessly with Quick & Nimble, be sure to try the [Spry framework](https://github.com/Rivukis/Spry) on your next Swift project.
