# Poseur

When writing unit tests, we want to test specific units of code, decoupled from the actual state of our application. To do this, we simulate the other units of code with which the test subject communicates. Doing this is referred to as putting the subject into a “test harness.”

These simulated units of code are what we generally call “fakes.” They allow the test code to change the conditions around the subject to replicate known app states/conditions, such as the success or failure of a network call, or a specific state on a helper class. Changing how these fakes respond to being interacted with by the subject is called “stubbing” and recording whether or methods or properties have on the fake have been accessed is called “spying.”

Poseur is a class and protocol for creating test fakes for stubbing/spying in Swift, inspired by the (more fully-featured framework) [Spry](https://github.com/Rivukis/Spry) framework.

## The Cast of Characters

Poseur has two main components:

#### 1. The `Faker<Function>` object

This object encapsulates most of the `Fake` functionality. It works as a helper object to manage the spying and stubbing for a given fake. It has a generic *Function* type which allows the user to implement any kind of object to define their method captures as long as that object conforms to `PoseurFunction` which simply is a bundling of the *Equatable* and *Hashable* protocols.

#### 2. The `Fake` protocol

This protocol is what your fake objects will actually conform to. It's designed to closely mirror the `Faker<Function>` object, so that in tests you can inspect the fake itself rather than having to inspect its `.faker` property. Since the majority of the protocol is intended to be passthrough to the faker, I have included a protocol extension which does exactly that. And thanks to that, all one needs to do to conform to `Fake` is to define the `Function` type, and implement the `faker` property, which will include that type as its generic. I've even created a convenience extension method to `Function` so that all one need to do to implement that property is add this line: `let faker = Function.faker()`

A bit of advice: When you define your `Function` type, I recommend using an enum, as it gives you a finite set of cases, each corresponding to a given function/method.

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

Sometimes we just want to know if a function was called at all.

```swift
fakeDog.eat(food: .canned)
fakeDog.eat(food: .canned)
fakeDog.eat(food: .canned)

fakeDog.receivedCall(to: .eat) // returns true
fakeDog.callCountFor(function: .eat) // returns 3
```

Both `receivedCall(to:)` and `callCountFor(function:)` use the "simple" approach. That means that these methods are reporting on raw number of calls to this function, rather than calls with a specific set of arguments.

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

Spying on what is being communicated to our dependencies is one half of the harness we put our test subjects into. The other half is controlling the behavior of those dependencies to simulate specific scenarios/states. This is is where stubbing enters the picture. Poseur provies a handful of tools for stubbing your functions, and once again, the three main approaches are employed.

## 1. Simple

As the name would suggest, using this approach is very simple to do.

```swift
fakeDog.stub(function: .bark).andReturn("Meow")
// as you might excted, this will result in 
fakeDog.bark() // returning "Meow"
```

There's a GOTCHA though! When doing a simple, no arguments stub like this, there is an additional side-effect: It becomes the only stub for that function. Any argument-specific stub is automatically overridden in favor of a simple stub if one exists. The only way to override a simple stub is to add a new simple stub.

You might have noticed the `.andReturn(_:)` method in the example above. A simple stub returns a `Stubbable` which has the methods `.andReturn(_:)` and `func andDo(_:)`. This gives you options. The former is if you want to return a specific value no matter what. The latter provides the array of arguments that were passed to the function (as an array of `[Any?]`, I'm sorry) in a closure so you can provide any additional logic or side-effects your little heart desires. 

For example:

```swift
fakeDog.stub(function: .shouldFetch).andDo { (arguments) -> Bool in
    let fetchableItem = arguments[0] as! FetchableItem
    let familyMember = arguments[1] as! FamilyMember
    switch (fetchableItem, familyMember) {
    case (.slippers, .kid):
        return true
    default:
        return false
    }
}
fakeDog.shouldFetch(.slippers, for: .kid) // returns true
```
(I normally advise strongly against the use of force-unwrapped optionals, but in a test case like this, they simulate the actual rigidity of the Swift type system, so I'm ok with it. In unit tests more than anywhere else you want to fail *fast*.)

The `andDo(_:)` method also enables you to stub a method once and have its execution block key off of state variables that you control and manipulate over the course of a test or test suite. An example of where you might want to do this is a function which wraps a network call. You can simply stub it once, and have what the simulated network call returns, or whether it succeeds or fails, based on state variables. Very handy.

## 2. ArgsCheck

As usual, this method is the hairiest approach, but the one where you have the most direct control. Control, in this case, over whether or not your stub is invoked or whether `Fake` is going to throw a `fatalError(_:)` message at the console about how you haven't stubbed the method in a way that matches the arguments the call was passed.

```swift
fakeDog.stub(function: .rollOntoTummy, where: { ($0[0] as? Bool) == false }).andReturn("HOWL")

// or 

fakeDog.stub(function: .rollOntoTummy) { (arguments) -> Bool in
    (arguments[0] as? Bool) == false
}.andReturn("HOWL")
```

Unlike the simple stub, an ArgsCheck stub returns an `AndReturnable` which only has the `.andReturn(_:)` method.

What this means is that you have two options for dynamically responding to arguments:

1. Supply an args check determining whether or not your stub is invoked and give that stub a single return value. This lets you create a different stub for any number of `ArgsCheck` closures, each with a different return value.
2. Stub the method universally and respond to the arguments (and/or other variables) dynamically on the way out. This lets you have one consolidated closure that encapsulates all of your return value logic. It also is the clearest and easiest way to add side-effects to the function call.

It's all up to you! Do what makes the most sense for you and works best for your tests.

## 3. Argument list

The automagic option returns! As always, this is the prettier and easier to read of the two argument-specific stubbing methods.

```swift
subject.stub(function: .shouldFetch, withArguments: FetchableItem.slippers, FamilyMember.kid).andReturn(true)
subject.stub(function: .shouldFetch, withArguments: FetchableItem.ball, FamilyMember.parent).andReturn(false)
subject.stub(function: .shouldFetch, withArguments: FetchableItem.ball, FamilyMember.kid).andReturn(true)
fakeDog.shouldFetch(.slippers, for: .kid) // return true
fakeDog.shouldFetch(.ball, for: .parent) // returns false
fakeDog.shouldFetch(.ball, for: .kid) // returns true
```
As was the case for argument list spying, there is a lot of "I hope this works" going on under the hood to make this approach work. Also like before, you can improve the stability and accuracty of this by conforming any types you care to check to `AnyEquatable`.

## One last thing

A technique I use a lot when writing generically typed methods that return the generic type, is to include the type itself as an argument and then give it a default argument, like I do on both methods that return a stubbed value:

```swift
func stubbedValue<T>(forFunction function: Function, asType: T.Type, arguments: [Any?]) -> T
// and
func recordAndStub<T>(function: Function, asType: T.Type = T.self, arguments: Any?...) -> T
```

What this does is give you options, as the caller. If you are assigning it to an explicitly typed variable or using it as the return line in a function, it can use type inference to determine what `T` is and that arument can disappear completely. (You'll notice that on `FakeDog` you never see the `asType:` argument.) But if you need to call the method and want to supply that type directly, you can easily pass it explicitly: 
```swift
recordAndstub(function: .shouldFetch, asType: Bool.self, arguments: item, familyMember)
```

## And that's it!

That's about all, folks. Anything more that you could want to know will be in the (forthcoming) documentation comments.

Thank you for taking the time to read through this. Feel free to reach out and ask about it, and to report any bugs you find. In the meantime, if you want a more stable, strongly-typed, fully-featured stubbing/spying framework that integrates seamlessly with Quick & Nimble, be sure to try the [Spry framework](https://github.com/Rivukis/Spry) on your next Swift project.
