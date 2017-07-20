# JakeFake
A bare-bones class and protocol for creating test fakes for stubbing/spying in Swift.

Inspired by (the MUCH more fully-featured framework) Spry: https://github.com/Rivukis/Spry

## The Cast of Characters
JakeFake has two main components:

#### JakeFaker object
This object encapsulates most of the JakeFake functionality. It works as a helper object to manage the spying and stubbing for a given fake. It has a generic *Function* type which allows the user to implement any kind of object to define their method captures as long as that object conforms to *JakeFakeFunction* which simply is a bundling of the *Equatable* and *Hashable* protocols. I recommend using an ```enum```.

#### JakeFake protocol
This protocol is what your fake objects will actually conform to. It's designed to closely mirror the *JakeFaker* object, so that in tests you can inspect the fake itself rather than having to inspect its ```.faker``` property. Since the majority of the protocol is intended to be passthrough to the faker, I have included a protocol extension which does exactly that, so that all one needs to do to conform to the *JakeFake* is to define the *Function* type, and implement the ```faker``` property, which will include that type as its generic.

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

Wasn't that easy?

Now that we have our *FakeDog* object, if we want to verify that a method has been called on *Dog*, for example: ```eat(food:)```, we can simply call ```received(method:)```:

```swift
let dog = FakeDog()
dog.eat(food: .tableScraps)

dog.received(method: .eat(.tableScraps))  //evaluates to true
```

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

And that's about it! Feel free to ask me all about it, and, more than anything else. If you want a more stable, strongly-type, fully-fleshed-out framework, be sure to install the Spry framework in your next Swift project: https://github.com/Rivukis/Spry
