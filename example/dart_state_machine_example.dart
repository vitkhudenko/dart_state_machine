import 'package:dart_state_machine/dart_state_machine.dart';

void main() {
  var stateMachine = StateMachineBuilder<MySessionEvent, MySessionState>()
      .setInitialState(MySessionState.active)
      .addTransition(Transition(
          event: MySessionEvent.login,
          statePath: [MySessionState.inactive, MySessionState.active]))
      .addTransition(Transition(
          event: MySessionEvent.logout,
          statePath: [MySessionState.active, MySessionState.inactive]))
      .addTransition(Transition(
          event: MySessionEvent.logoutAndForget,
          statePath: [MySessionState.active, MySessionState.forgotten]))
      .build();

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
}

class MySessionEvent implements StateMachineEvent {
  static const MySessionEvent login = MySessionEvent._('login');
  static const MySessionEvent logout = MySessionEvent._('logout');
  static const MySessionEvent logoutAndForget =
      MySessionEvent._('logout_and_forget');

  final String id;

  const MySessionEvent._(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MySessionEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$id';
}

class MySessionState implements StateMachineState {
  static const MySessionState active = MySessionState._('active');
  static const MySessionState inactive = MySessionState._('inactive');
  static const MySessionState forgotten = MySessionState._('forgotten');

  final String id;

  const MySessionState._(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MySessionState &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$id';
}
