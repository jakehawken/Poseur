# JakeFake
A bare-bones class and protocol for creating test fakes for stubbing/spying in Swift.

Inspired by (the MUCH more fully-featured framework) Spry: https://github.com/Rivukis/Spry

__Table of Contents__

* [The Cast of Characters](#the-cast-of-characters)
    * [JakeFaker object](#jakefaker-object)
    * [JakeFake protocol](#jakefake-protocol)
* [A bit of advice](#a-bit-of-advice)
* [How to Use](#how-to-use)
    * [Conforming to JakeFake](#conforming-to-jakefake)
    * [Spying on our fake](#spying-on-our-fake)
    * [Stubbing methods on our fake](#stubbing-methods-on-our-fake)

## The Cast of Characters
JakeFake has two main components:

#### JakeFaker object
This object encapsulates most of the JakeFake functionality. It works as a helper object to manage the spying and stubbing for a given fake. It has a generic *Function* type which allows the user to implement any kind of object to define their method captures as long as that object conforms to *JakeFakeFunction* which simply is a bundling of the *Equatable* and *Hashable* protocols.

#### JakeFake protocol
This protocol is what your fake objects will actually conform to. It's designed to closely mirror the *JakeFaker* object, so that in tests you can inspect the fake itself rather than having to inspect its ```.faker``` property. Since the majority of the protocol is intended to be passthrough to the faker, I have included a protocol extension which does exactly that. And thanks to that, all one needs to do to conform to the *JakeFake* is to define their ```Function``` type, and implement the ```faker``` property, which will include that type as its generic.

## A bit of advice
When you define your *Function* type, I recommend using an ```enum```, as it gives you a finite set of cases, each corresponding to a given method, which you can configure any number of ways. Swift enum associated values are also an excellent tool for capturing the arguments of the methods. This gives you a strong typing for the capturing and comparing of method calls. For example, a method with the signature
```swift
func doStuff(toString string:String, doOtherStuff:Bool) -> String
```
would have a corresponded case in the enum
```swift
case doStuff(String, Bool)
```

## How to Use

Imagine, if you will, that you have a class called *Dog*:

```swift
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
```
#### Conforming to JakeFake
*Dog* is a depency in a class, *HappyFamily*, that you're testing. As such, you want to generate a fake so that you can control *Dog*'s behavior in your tests. *JakeFake* allows you to create a fake simply by creating a subclass of Dog that conforms to the *JakeFake* protocol, and overriding its methods. Check it out!

```swift
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
```
#### Spying on our fake
Wasn't that easy?

Now that we have our *FakeDog* object, if we want to verify that a method has been called on *Dog*, for example: ```eat(food:)```, we can simply call ```received(method:)```:

```swift
let dog = FakeDog()
dog.eat(food: .tableScraps)

dog.received(method: .eat(.tableScraps))  //evaluates to true
```
##### Ignoring arguments.
And with our *Function* type defined as we do above, we can differentiate between a method being called with specific arguments and a method being called period. To do this we set the hidden ```ignoreArguments``` parameter (it has a default value of ```false```specified), to ```true```.

```swift
let dog = FakeDog()
dog.eat(food: .dry)
dog.eat(food: .wet)

dog.received(method: .eat(.tableScraps))                            //evaluates to false
dog.callCountFor(method: .eat(.tableScraps))                        //evaluates to 0

dog.received(method: .eat(.tableScraps), ignoreArguments: true)     //evaluates to true
dog.callCountFor(method: .eat(.tableScraps), ignoreArguments: true) //evaluates to 2
```

For the time being, you still have to provide the associated values, but they'll be ignored, as seen above.

#### Stubbing methods on our fake
For methods on *Dog* that have return types, such as ```digest``` we can also use *JakeFake* to stub out what that method will return. So, in our setup, we can do the following:

```swift
dog.stub(.digest) { () -> Any? in
    return "Upset tummy"
}
```

And as the following code will evaluate as shown:

```swift
dog.digest()  //evaluates to "Upset tummy", the stubbed value above
dog.received(method: .digest)  //evaluates to true
```

### Thanks!
And that's about it! Feel free to ask me all about it, and report any bugs you find.

And in the meantime, if you want a more stable, strongly-type, fully-featured stubbing/spying framework, be sure to install the Spry framework in your next Swift project: https://github.com/Rivukis/Spry
