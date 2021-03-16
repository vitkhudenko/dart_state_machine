import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'package:dart_state_machine/dart_state_machine.dart';

class Event implements StateMachineEvent {
  static const Event event1 = Event._('1');
  static const Event event2 = Event._('2');
  static const Event event3 = Event._('3');
  static const Event event4 = Event._('4');
  static const Event event5 = Event._('5');

  final String id;

  const Event._(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$id';
}

class State implements StateMachineState {
  static const State stateA = State._('a');
  static const State stateB = State._('b');
  static const State stateC = State._('c');
  static const State stateD = State._('d');
  static const State stateE = State._('e');

  final String id;

  const State._(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is State && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$id';
}

void checkEventIsIgnored(StateMachine<Event, State> stateMachine,
    TestListener<State> listener, Event event) {
  _checkEventsAreIgnored(stateMachine, [listener], [event]);
}

void checkEventsAreIgnored(StateMachine<Event, State> stateMachine,
    TestListener<State> listener, List<Event> events) {
  _checkEventsAreIgnored(stateMachine, [listener], events);
}

void checkEventIsConsumed(StateMachine<Event, State> stateMachine,
    List<TestListener<State>> listeners, Event event, List<State> transition) {
  expect(transition.first, stateMachine.getCurrentState());
  expect(stateMachine.consumeEvent(event), true);
  expect(transition.last, stateMachine.getCurrentState());

  for (var listener in listeners) {
    final expectedStateChanges = <List<State>>[];
    for (var i = 0, len = transition.length; i < (len - 1); i++) {
      final from = transition[i];
      final to = transition[i + 1];
      expectedStateChanges.add([from, to]);
    }
    verifyInOrder([
      for (var stateChange in expectedStateChanges)
        listener.onStateChanged(stateChange.first, stateChange.last)
    ]);
    verifyNoMoreInteractions(listener);
  }
}

void _checkEventsAreIgnored(StateMachine<Event, State> stateMachine,
    List<TestListener<State>> listeners, List<Event> events) {
  final state = stateMachine.getCurrentState();
  final listenersCopy = listeners.toList();
  for (var event in events) {
    expect(stateMachine.consumeEvent(event), false);
    expect(state, stateMachine.getCurrentState());
    for (var listener in listenersCopy) {
      verifyNoMoreInteractions(listener);
    }
  }
}

class TestListener<State extends StateMachineState> {
  void onStateChanged(State oldState, State newState) {}
}
