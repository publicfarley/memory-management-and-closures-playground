import UIKit
//: # Parent - Child Reference Relationships
//: ## 1. One way. Parent stronlgy refers to Child.
//: ## 🆗

class Base {
    init() {
        print("\(self) got allocated.")
    }
    
    deinit {
        print("\(self) got deallocated.")
    }
}

class Child: Base {}

class Parent: Base {
    let child: Child // strong reference
    
    init(child: Child) {
        self.child = child
    }
}

var p: Parent? = Parent(child: Child())  // +1 p, +1 c
p = nil // -1 c, -1 p

func doPrintSeparator() {
    print("\n-----------\n")
}

doPrintSeparator()

/*:
 At the end of execution, reference counts for parent and child are both `0`.
 
 So this prints out that the parent instance and the child instance were both successfully deallocated. 🙂
 */


//: ## 2. Two way. Parent stronlgy refers to Child. Child stronlgy refers to Parent.
//: ## 🚫

class Child2: Base {
    var parent: Parent2? // strong reference
}

class Parent2: Base {
    let child: Child2 // strong reference
    
    init(child: Child2) {
        self.child = child
    }
}

var c2: Child2? = Child2() // +1 c2
var p2: Parent2? = Parent2(child: c2!) // +1 p2, +1 c2
c2?.parent = p2 // + 1 p2
c2 = nil // - 1 c2
p2 = nil // - 1 p2

doPrintSeparator()

/*:
 At the end of execution, reference counts for parent and child are both `1`.
 
 Reference Cycle! 🔥 Parent and child did not get deallocated. They strongly refer to each other. 😖
 */

//: ## 3. Two way. Parent stronlgy refers to Child. Child weakly refers to Parent.
//: ## 🆗

class Child3: Base {
    weak var parent: Parent3? // weak reference
}

class Parent3: Base {
    let child: Child3 // strong reference
    
    init(child: Child3) {
        self.child = child
    }
}

var c3: Child3? = Child3() // + 1 c
var p3: Parent3? = Parent3(child: c3!) // + 1 p, +1 c
c3?.parent = p3 // + 0 p
c3 = nil // -1 c
p3 = nil // -1 c, -1 p

doPrintSeparator()

/*:
 At the end of execution, reference counts for parent and child are both `0`.
 
 Child holds parent weakly. So this prints out that the parent instance and the child instance were both successfully deallocated. 🙂
 */

//: ----
//: # Closures
/*:
 **Closures are reference types. So the same Parent - Child reference relationships apply.**
 
 **Look for the aforementioned reference relationship patterns when dealing with closures to help with correct assessment.**
*/
 
/*:
 So now, what about this?
 ```
 UIView.animate(withDuration: 1.0) {
    self.view.alpha = 0.5
 }
 ```
 
 Note that `animate(withDuration:)` is a static method on UIView and the closure is a reference type. So the closure has a strong refrence to the UIView instance through `self` and that's it.
 
 So the closure is a parent in this scenario, and the UIView instance is the child. So, when the closure is deallocated, the overall reference count to the child UIView is decremented. So this relationship termniates correctly.
 
 🆗
 */

class MyView: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        print("\(self) got allocated.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animateMe() {
        UIView.animate(withDuration: 1.0) {
            self.alpha = 0.5
        }
    }

    deinit {
        print("\(self) got deallocated.")
    }
}

MyView().animateMe()
doPrintSeparator()



class Greeter {
    required init() {
        print("\(self) got allocated.")
    }
    
    func greet() {
        assertionFailure("greet() method must be overriden.")
    }
    
    deinit {
        print("\(self) got deallocated.")
    }
}

//: ----

/*:
 What about this?
 
 1. Basic Anonymous Inline Closure
 
 ```
final class GreetingService {
    static func getGreeting(completion: @escaping (String) -> Void) {
        DispatchQueue.global().sync {
            completion("Hello World")
        }
    }
}

final class GreeterUsingAnonymousInlineClosure: Greeter {
    var message: String?
 
    required init() {
        super.init()
    }
 
    func greet() {
        GreetingService.getGreeting { message in
            self.message = message
        }
    }
}

 ```
 
 The closure here strongly captures the enclosing Greeter instance. Greeter doesn't have a reference to the closure. So the closure is the parent and the Greeter is the child. So, when the closure is deallocated the overall reference count to the child Greeter is decremented. So this relationship termniates correctly.
 
 🆗
 */

final class GreetingService {
    static func getGreeting(completion: @escaping (String) -> Void) {
        DispatchQueue.global().sync {
            completion("Hello World")
        }
    }
}

final class GreeterUsingAnonymousInlineClosure: Greeter {
    var message: String?
    
    required init() {
        super.init()
    }

    override func greet() {
        GreetingService.getGreeting { message in
            self.message = message
        }
    }
}


//: ----

/*:
 What about this?
 
 2. Strong Closure Property
 
 ```
 final class GreeterWithStrongClosureProperty: Greeter  {
    var message: String?

    required init() {
        super.init()
    }

    lazy var messageHandler: (String) -> Void = { message in
        self.message = message
    }
 
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
 }
 ```

Here the `messageHandler` is a strong property of Greeter and the `messsageHandler` strongly captures the Greeter instance.
 
So the messageHanlder closure instance has a strong reference to the Greeter instance and vice versa.
 
🔥 Reference Cycle! 🔥

🚫
 
 ```
 */

final class GreeterWithStrongClosureProperty: Greeter  {
    var message: String?
    
    required init() {
        super.init()
    }
 
    lazy var messageHandler: (String) -> Void = { message in
        self.message = message
    }
 
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
 }

// Reference cycle! GreeterWithStrongClosureProperty *and* the messageHandler closure will never be deallocated

//: ----

/*:
  What about this? Does this completely fix the previous example?
 
 3. Strong Closure Property, with weakly captured self


```
final class GreeterWithStrongClosurePropertyWeaklyCapturedSelf: Greeter  {
    var message: String?
 
    required init() {
        super.init()
    }
 
    lazy var messageHandler: (String) -> Void = { [weak self] message in
        self?.message = message
    }
 
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
}
```
 
 Yup. Breaks the reference cycle. But `self` could go away before messageHandler has a chance to use it!
 So no reference cycle, but possibly incorrect behaviour.
 
 > This is _possibly_ 🆗. Depends on context.
*/

final class GreeterWithStrongClosurePropertyWeaklyCapturedSelf: Greeter  {
    var message: String?

    required init() {
        super.init()
    }

    lazy var messageHandler: (String) -> Void = { [weak self] message in
        self?.message = message
    }
    
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
}

//: ----

/*:
 What about this? Does this fix the previous example?
 
 4. Strong Closure Property, with weakly captured `self` then `strongSelf`.

 
 ```
final class GreeterWithStrongClosurePropertyWeaklyCapturedSelfThenStrongSelf: Greeter  {
    var message: String?

    required init() {
        super.init()
    }

    lazy var messageHandler: (String) -> Void = { [weak self] message in
        guard let strongSelf = self else { return }
        strongSelf.message = message
    }
 
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
}
 ```
 
 Yup. This breaks the reference cycle *and* ensures that `self` stays around for the duration of the closure (via `strongSelf`).
 So no reference cycle, *and* self stays around at least as long as the closure. Deterministic behaviour.
 
 🆗
 */


final class GreeterWithStrongClosurePropertyWeaklyCapturedSelfThenStrongSelf: Greeter  {
    var message: String?
    
    required init() {
        super.init()
    }

    lazy var messageHandler: (String) -> Void = { [weak self] message in
        guard let strongSelf = self else { return }
        strongSelf.message = message
    }
    
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
}

//: ----

/*:
 What about this?
 
 5. Instance Method as Handler.

 
 ```
final class GreeterWithInstanceMethodAsHandler: Greeter  {
    var message: String?
 
    required init() {
        super.init()
    }

    func messageHandler(message: String) {
        self.message = message
    }
 
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
}
 ```
 
 The Greeter instance method `messageHandler` is intrinsicly tied to the lifetime of Greeter. The method dose not have a separate reference count. `self` will naturally stay around for as long as the method. Relationship terminates correctly.

 🆗
 */


final class GreeterWithInstanceMethodAsHandler: Greeter  {
    var message: String?
    
    required init() {
        super.init()
    }

    func messageHandler(message: String) {
        self.message = message
    }
    
    override func greet() {
        GreetingService.getGreeting(completion: messageHandler)
    }
}

//: ----

/*:
 What about this?
 
 6.  Instance Method as Handler used from strongly held message handler holder.
 
 ```
final class MessageHandlerHolder {
    let messageHandler: (String) -> Void
 
    init(messageHandler: @escaping (String) -> Void) {
        self.messageHandler = messageHandler
    }
}

final class GreeterWithInstanceMethodAsHandlerGivenToStronglyHeldMessageHandlerHolder: Greeter  {
    var message: String?
 
    required init() {
        super.init()
    }

    lazy var messageHandlerHolder: MessageHandlerHolder = MessageHandlerHolder(messageHandler: self.messageHandler)
 
    func messageHandler(message: String) {
        self.message = message
    }
 
    override func greet() {
        GreetingService.getGreeting(completion: messageHandlerHolder.messageHandler)
    }
}
 ```
 
// Greeter strongly holds `messageHandlerHolder`. It also passes itself via the `messageHandler` function to `MessageHandlerHolder`. `MessageHandlerHolder` strongly holds its `messageHandler` property. So both hold each other strongly. 🔥 Reference Cycle! 🔥
 
 🚫
 */


final class MessageHandlerHolder {
    let messageHandler: (String) -> Void
    
    init(messageHandler: @escaping (String) -> Void) {
        self.messageHandler = messageHandler
    }
}

final class GreeterWithInstanceMethodAsHandlerGivenToStronglyHeldMessageHandlerHolder: Greeter  {
    var message: String?

    required init() {
        super.init()
    }

    lazy var messageHandlerHolder: MessageHandlerHolder = MessageHandlerHolder(messageHandler: self.messageHandler)
    
    func messageHandler(message: String) {
        self.message = message
    }
    
    override func greet() {
        GreetingService.getGreeting(completion: messageHandlerHolder.messageHandler)
    }
}

//: ---

/*:
 What about this?
 
 7.  Anonymous Closure as Handler used from strongly held message handler holder.

 
 ```
 final class GreeterWithAnonymousClosureAsHandlerGivenToStronglyHeldMessageHandlerHolder: Greeter  {
    var message: String?
 
    required init() {
        super.init()
    }
 
    lazy var messageHandlerHolder: MessageHandlerHolder = MessageHandlerHolder(messageHandler: { message in
        self.message = message
    })
 
    override func greet() {
        GreetingService.getGreeting(completion: messageHandlerHolder.messageHandler)
    }
}
 ```

 // Greeter strongly holds `messageHandlerHolder`. `MessageHandlerHolder` strongly holds its `messageHandler` property. Additionally, we have filled the `messageHandler` property with an anonymous closure that stronly refers to the Greeter.
 
 So:
 1) Greeter _has strong reference to_ MessageHandlerHolder _has strong reference to_ Closure
 2) Closure _has strong reference to_ Greeter
 
 So both reference each other strongly. 🔥 Reference Cycle! 🔥
 
 🚫

 */

final class GreeterWithAnonymousClosureAsHandlerGivenToStronglyHeldMessageHandlerHolder: Greeter  {
    var message: String?

    required init() {
        super.init()
    }

    lazy var messageHandlerHolder: MessageHandlerHolder = MessageHandlerHolder(messageHandler: { message in
        self.message = message
    })
    
    override func greet() {
        GreetingService.getGreeting(completion: messageHandlerHolder.messageHandler)
    }
}


//: ----

/*:
 What about this?
 
 8.  Local Closure as Handler.

 
 ```
final class GreeterWithLocalClosureAsHandler: Greeter  {
    var message: String?
 
    required init() {
        super.init()
    }
 
    override func greet() {
 
        let messageHandler: (String) -> Void = { message in
            self.message = message
        }

        GreetingService.getGreeting(completion: messageHandler)
    }
}
 ```
 
 The closure here strongly captures the enclosing Greeter instance. Greeter doesn't have a reference to the closure. So the closure is the parent and the Greeter is the child. So, when the closure is deallocated the overall reference count to the child Greeter is decremented. So this relationship termniates correctly.

🆗
 */


final class GreeterWithLocalClosureAsHandler: Greeter  {
    var message: String?
    
    required init() {
        super.init()
    }
    
    override func greet() {
        
        let messageHandler: (String) -> Void = { message in
            self.message = message
        }

        GreetingService.getGreeting(completion: messageHandler)
    }
}

//: ----

/*:
 What about this?
 
 9.  Local function as Handler.

 ```
final class GreeterWithLocalFunctionAsHandler: Greeter  {
    var message: String?
 
    required init() {
        super.init()
    }
 
    override func greet() {
 
        func messageHandler(_ message: String) {
            self.message = message
        }
 
        GreetingService.getGreeting(completion: messageHandler)
    }
}
 ```
 
 The local function ('named closure') strongly captures the enclosing Greeter instance. Greeter doesn't have a reference to the local function. So the function is the parent and the Greeter is the child. So, when the function is deallocated the overall reference count to the child Greeter is decremented. So this relationship termniates correctly.

🆗
 */


final class GreeterWithLocalFunctionAsHandler: Greeter  {
    var message: String?
    
    required init() {
        super.init()
    }
    
    override func greet() {
        
        func messageHandler(_ message: String) {
            self.message = message
        }
        
        GreetingService.getGreeting(completion: messageHandler)
    }
}

//: ----

/*:
 # Results:
 
 Observe below the results of running the various Greeter types with various reference relationships.
 
 - 'allocation'/'deallocation' pairs indicate a proper termination scenario.
 - an 'allocation' without a corresponding 'deallocation' indicates a reference cycle.
 */


var greeters: Array<Greeter.Type> = [GreeterUsingAnonymousInlineClosure.self,GreeterWithStrongClosureProperty.self,GreeterWithStrongClosurePropertyWeaklyCapturedSelf.self,GreeterWithStrongClosurePropertyWeaklyCapturedSelfThenStrongSelf.self,GreeterWithInstanceMethodAsHandler.self,GreeterWithInstanceMethodAsHandlerGivenToStronglyHeldMessageHandlerHolder.self,GreeterWithAnonymousClosureAsHandlerGivenToStronglyHeldMessageHandlerHolder.self,GreeterWithLocalClosureAsHandler.self,GreeterWithLocalFunctionAsHandler.self]

greeters.forEach {
    ($0.init()).greet()
    doPrintSeparator()
}

// Note: The results are printed in the console window.
//: ----

/*:
 # What about 'unowned'?
 
 TBD
 */

//: ----

/*:
 For more information, please refer to:
 
 [Swift Automatic Reference Counting](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)
 */

// © 2018 Farley Caesar



