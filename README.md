A general purpose finite-state machine for Dart developers.

This package is a port of the Kotlin version of the [state machine][kotlin-state-machine].

## Usage

Let's suppose your app wants to use a state machine for user session state management.

First, let's create your `MySessionEvent` and `MySessionState` classes (an implementation of the
library's `StateMachineEvent` and `StateMachineState` abstract classes):

```dart
import 'package:dart_state_machine/dart_state_machine.dart';

class MySessionEvent implements StateMachineEvent {
  static const MySessionEvent login           = MySessionEvent._('login');
  static const MySessionEvent logout          = MySessionEvent._('logout');
  static const MySessionEvent logoutAndForget = MySessionEvent._('logout_and_forget');

  final String id;

  const MySessionEvent._(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || 
          other is MySessionEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$id';
}

class MySessionState implements StateMachineState {
  static const MySessionState active    = MySessionState._('active');
  static const MySessionState inactive  = MySessionState._('inactive');
  static const MySessionState forgotten = MySessionState._('forgotten');

  final String id;

  const MySessionState._(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || 
          other is MySessionState && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$id';
}
```

Then it is possible to create a `StateMachine` using a `StateMacnineBuilder`:

```dart
var stateMachine = StateMachineBuilder<MySessionEvent, MySessionState>()
    .setInitialState(MySessionState.active)
    .addTransition(
        Transition(
            event: MySessionEvent.login,
            statePath: [MySessionState.inactive, MySessionState.active]
        )
    )
    .addTransition(
        Transition(
            event: MySessionEvent.logout,
            statePath: [MySessionState.active, MySessionState.inactive]
        )
    )
    .addTransition(
        Transition(
            event: MySessionEvent.logoutAndForget,
            statePath: [MySessionState.active, MySessionState.forgotten]
        )
    )
    .build();
```

Meaning of the above sample configuration is that:
* There are 3 possible session states (`active`, `inactive` and `forgotten`).
* There are 3 possible events (`login`, `logout` and `logoutAndForget`).
* StateMachine's initial state is `ACTIVE`.
* There are 3 possible state machine transitions:

|Event            |State path              |
|-----------------|------------------------|
|`login`          |`inactive` -> `active`  |
|`logout`         |`active` -> `inactive`  |
|`logoutAndForget`|`active` -> `forgotten` |

Now, we can attach a listener and play with the state machine a bit:

```dart
var listener = (MySessionState oldState, MySessionState newState) => 
    print('state change: $oldState -> $newState');

stateMachine.addListener(listener);

// prints "state change: active -> inactive"
var consumed = stateMachine.consumeEvent(MySessionEvent.logout);
assert(consumed);

// does nothing
consumed = stateMachine.consumeEvent(MySessionEvent.logout);
assert(!consumed);

// prints "state change: inactive -> active"
consumed = stateMachine.consumeEvent(MySessionEvent.login);
assert(consumed);

// does nothing
consumed = stateMachine.consumeEvent(MySessionEvent.login);
assert(!consumed);

// prints "state change: active -> forgotten"
consumed = stateMachine.consumeEvent(MySessionEvent.logoutAndForget);
assert(consumed);

// does nothing
consumed = stateMachine.consumeEvent(MySessionEvent.login);
assert(!consumed);

// does nothing
consumed = stateMachine.consumeEvent(MySessionEvent.logout);
assert(!consumed);
```

[kotlin-state-machine]: https://github.com/vitkhudenko/state_machine
