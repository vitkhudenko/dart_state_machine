import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'package:dart_state_machine/dart_state_machine.dart';

import 'utils.dart';

class MockListener extends Mock implements TestListener<State> {}

void main() {
  test('initial state should be set as expected', () {
    final listener = MockListener();

    const state = State.stateA;

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(
            Transition(event: Event.event1, statePath: [state, State.stateB]))
        .setInitialState(state)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    expect(state, equals(stateMachine.getCurrentState()));
    verifyZeroInteractions(listener);
  });

  test('out-of-config events should be ignored', () {
    final listener = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event3,
            statePath: [State.stateC, State.stateD, State.stateE]))
        .setInitialState(State.stateA)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    checkEventsAreIgnored(stateMachine, listener, [Event.event4, Event.event5]);
  });

  test(
      'in-config events, that do not match the current state '
      'of the state machine, should be ignored', () {
    final listener = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event3,
            statePath: [State.stateC, State.stateD, State.stateE]))
        .setInitialState(State.stateA)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    checkEventsAreIgnored(stateMachine, listener, [Event.event2, Event.event3]);
  });

  test('same transition should not happen, if the same event is fired again',
      () {
    final listener = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event3,
            statePath: [State.stateC, State.stateD, State.stateE]))
        .setInitialState(State.stateA)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    // verify transition from State.stateA to State.stateB happens
    checkEventIsConsumed(
        stateMachine, [listener], Event.event1, [State.stateA, State.stateB]);

    checkEventIsIgnored(stateMachine, listener, Event.event1);
  });

  test('same transition should happen, if the same event is fired again', () {
    final listener = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1,
            statePath: [State.stateA, State.stateB, State.stateA]))
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateB, State.stateA]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event3,
            statePath: [State.stateC, State.stateD, State.stateE]))
        .setInitialState(State.stateA)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    // verify transition State.stateA -> State.stateB -> State.stateA happens
    checkEventIsConsumed(stateMachine, [listener], Event.event1,
        [State.stateA, State.stateB, State.stateA]);

    // verify same transition happens again
    reset(listener);
    checkEventIsConsumed(stateMachine, [listener], Event.event1,
        [State.stateA, State.stateB, State.stateA]);
  });

  test('several transitions and final state', () {
    final listener = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event3,
            statePath: [State.stateC, State.stateD, State.stateE]))
        .setInitialState(State.stateA)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    expect(stateMachine.getCurrentState(), State.stateA);
    verifyZeroInteractions(listener);

    // verify transition from State.stateA to State.stateB happens
    checkEventIsConsumed(
        stateMachine, [listener], Event.event1, [State.stateA, State.stateB]);

    // verify transition from State.stateB to State.stateC happens
    checkEventIsConsumed(
        stateMachine, [listener], Event.event2, [State.stateB, State.stateC]);

    // verify transition from State.stateC to State.stateD to State.stateE happens
    checkEventIsConsumed(stateMachine, [listener], Event.event3,
        [State.stateC, State.stateD, State.stateE]);

    // verify any further events should are ignored as state machine is its final state
    checkEventsAreIgnored(stateMachine, listener,
        [Event.event1, Event.event2, Event.event3, Event.event4, Event.event5]);
  });

  test(
      'starting new transition while ongoing transition is not finished yet '
      'should be a consistency violation', () {
    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1,
            statePath: [State.stateA, State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateD]))
        .setInitialState(State.stateA)
        .build();

    final listener = MockListener();
    when(listener.onStateChanged(State.stateA, State.stateB)).thenAnswer((_) {
      // listener will fire Event.event2 as soon as the intermediate state State.stateB
      // in the first transition (State.stateA - State.stateB - State.stateC) is reached
      expect(stateMachine.getCurrentState(), State.stateB);
      expect(stateMachine.consumeEvent(Event.event2), true);
    });

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    expect(
        // The Event.event2, triggered from the listener.onStateChanged(State.stateA, State.stateB), breaks state
        // machine consistency, so it should crash. Otherwise the second transition (State.stateB to State.stateD)
        // would start while the first transition is still in the intermediate state State.stateB.
        () => stateMachine.consumeEvent(Event.event1),
        throwsA(predicate((e) =>
            e is StateError &&
            e.message == 'there is a transition which is still in progress')));
  });

  test(
      'starting new transition once ongoing transition has finished '
      'should not be a consistency violation (case with 2 transitions)', () {
    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1,
            statePath: [State.stateA, State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event2,
            statePath: [State.stateC, State.stateD, State.stateE]))
        .setInitialState(State.stateA)
        .build();

    final listener = MockListener();
    when(listener.onStateChanged(State.stateB, State.stateC)).thenAnswer((_) {
      // listener will fire Event.event2 as soon as the final state State.stateC in the first
      // transition (State.stateA - State.stateB - State.stateC) is reached
      expect(stateMachine.getCurrentState(), State.stateC);
      expect(stateMachine.consumeEvent(Event.event2), true);
    });

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    // verify that Event.event2, triggered from the listener.onStateChanged(State.stateB, State.stateC),
    // does not break state machine consistency (otherwise it would crash)
    checkEventIsConsumed(stateMachine, [listener], Event.event1,
        [State.stateA, State.stateB, State.stateC, State.stateD, State.stateE]);
  });

  test(
      'starting new transition once ongoing transition has finished '
      'should not be a consistency violation (case with 3 transitions)', () {
    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event3, statePath: [State.stateC, State.stateD]))
        .setInitialState(State.stateA)
        .build();

    final listener = MockListener();
    when(listener.onStateChanged(State.stateA, State.stateB)).thenAnswer((_) {
      // listener will fire Event.event2 as soon as the final state State.stateB
      // in the first transition (State.stateA - State.stateB) is reached
      expect(stateMachine.getCurrentState(), State.stateB);
      expect(stateMachine.consumeEvent(Event.event2), true);
    });
    when(listener.onStateChanged(State.stateB, State.stateC)).thenAnswer((_) {
      // listener will fire Event.event3 as soon as the final state State.stateC
      // in the second transition (State.stateB - State.stateC) is reached
      expect(stateMachine.getCurrentState(), State.stateC);
      expect(stateMachine.consumeEvent(Event.event3), true);
    });

    stateMachine.addListener((State oldState, State newState) =>
        listener.onStateChanged(oldState, newState));

    // Verify that:
    // a) Event.event2, fired from the listener.onStateChanged(State.stateA, State.stateB),
    //    does not break state machine consistency.
    // b) Event.event3, fired from the listener.onStateChanged(State.stateB, State.stateC),
    //    does not break state machine consistency.
    checkEventIsConsumed(stateMachine, [listener], Event.event1,
        [State.stateA, State.stateB, State.stateC, State.stateD]);
  });

  test('both listeners should be notified as expected', () {
    final listener1 = MockListener();
    final listener2 = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .setInitialState(State.stateA)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener1.onStateChanged(oldState, newState));
    stateMachine.addListener((State oldState, State newState) =>
        listener2.onStateChanged(oldState, newState));

    checkEventIsConsumed(stateMachine, [listener1, listener2], Event.event1,
        [State.stateA, State.stateB]);
  });

  test('adding same listener twice should be a no op', () {
    final listener = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .setInitialState(State.stateA)
        .build();

    final actualListener = (State oldState, State newState) =>
        listener.onStateChanged(oldState, newState);

    stateMachine.addListener(actualListener);
    stateMachine.addListener(actualListener);

    checkEventIsConsumed(
        stateMachine, [listener], Event.event1, [State.stateA, State.stateB]);
  });

  test('explicit call to remove one of the two listeners', () {
    final listener1 = MockListener();
    final listener2 = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .addTransition(Transition(
            event: Event.event3, statePath: [State.stateC, State.stateD]))
        .setInitialState(State.stateA)
        .build();

    final actualListener1 = (State oldState, State newState) =>
        listener1.onStateChanged(oldState, newState);
    final actualListener2 = (State oldState, State newState) =>
        listener2.onStateChanged(oldState, newState);
    stateMachine.addListener(actualListener1);
    stateMachine.addListener(actualListener2);

    checkEventIsConsumed(stateMachine, [listener1, listener2], Event.event1,
        [State.stateA, State.stateB]);

    // leave only listener2 attached to state machine
    stateMachine.removeListener(actualListener1);

    expect(stateMachine.consumeEvent(Event.event2), true);
    verify(listener2.onStateChanged(State.stateB, State.stateC));
    verifyNoMoreInteractions(listener1);
    verifyNoMoreInteractions(listener2);

    // leave no listeners attached to state machine
    stateMachine.removeListener(actualListener2);

    expect(stateMachine.getCurrentState(), State.stateC);
    expect(stateMachine.consumeEvent(Event.event3), true);
    expect(stateMachine.getCurrentState(), State.stateD);
    verifyNoMoreInteractions(listener1);
    verifyNoMoreInteractions(listener2);
  });

  test('first listener removes itself during notification', () {
    final listener1 = MockListener();
    final listener2 = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .setInitialState(State.stateA)
        .build();

    final actualListener1 = (State oldState, State newState) =>
        listener1.onStateChanged(oldState, newState);

    when(listener1.onStateChanged(State.stateA, State.stateB)).thenAnswer((_) {
      // listener1 will remove itself as soon as notified
      stateMachine.removeListener(actualListener1);
    });

    stateMachine.addListener(actualListener1);
    stateMachine.addListener((State oldState, State newState) =>
        listener2.onStateChanged(oldState, newState));

    // verify state changed and both listeners are notified as expected
    checkEventIsConsumed(stateMachine, [listener1, listener2], Event.event1,
        [State.stateA, State.stateB]);

    // verify state changed and only remaining listener2 is notified
    expect(stateMachine.consumeEvent(Event.event2), true);
    verify(listener2.onStateChanged(State.stateB, State.stateC));
    verifyNoMoreInteractions(listener1);
    verifyNoMoreInteractions(listener2);
  });

  test('second listener removes itself during notification', () {
    final listener1 = MockListener();
    final listener2 = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .setInitialState(State.stateA)
        .build();

    final actualListener2 = (State oldState, State newState) =>
        listener2.onStateChanged(oldState, newState);

    when(listener2.onStateChanged(State.stateA, State.stateB)).thenAnswer((_) {
      // listener2 will remove itself as soon as notified
      stateMachine.removeListener(actualListener2);
    });

    stateMachine.addListener((State oldState, State newState) =>
        listener1.onStateChanged(oldState, newState));
    stateMachine.addListener(actualListener2);

    // verify state changed and both listeners are notified as expected
    checkEventIsConsumed(stateMachine, [listener1, listener2], Event.event1,
        [State.stateA, State.stateB]);

    // verify state changed and only remaining listener1 is notified
    expect(stateMachine.consumeEvent(Event.event2), true);
    verify(listener1.onStateChanged(State.stateB, State.stateC));
    verifyNoMoreInteractions(listener1);
    verifyNoMoreInteractions(listener2);
  });

  test('first listener removes second listener during notification', () {
    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .setInitialState(State.stateA)
        .build();

    final listener1 = MockListener();
    final listener2 = MockListener();

    final actualListener2 = (State oldState, State newState) =>
        listener2.onStateChanged(oldState, newState);

    when(listener1.onStateChanged(State.stateA, State.stateB)).thenAnswer((_) {
      // listener1 will remove listener2 as soon as notified
      stateMachine.removeListener(actualListener2);
    });

    stateMachine.addListener((State oldState, State newState) =>
        listener1.onStateChanged(oldState, newState));
    stateMachine.addListener(actualListener2);

    // verify state changed and both listeners are notified as expected
    checkEventIsConsumed(stateMachine, [listener1, listener2], Event.event1,
        [State.stateA, State.stateB]);

    // verify state changed and only remaining listener1 is notified
    expect(stateMachine.consumeEvent(Event.event2), true);
    verify(listener1.onStateChanged(State.stateB, State.stateC));
    verifyNoMoreInteractions(listener1);
    verifyNoMoreInteractions(listener2);
  });

  test('second listener removes first listener during notification', () {
    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .addTransition(Transition(
            event: Event.event2, statePath: [State.stateB, State.stateC]))
        .setInitialState(State.stateA)
        .build();

    final listener1 = MockListener();
    final listener2 = MockListener();

    final actualListener1 = (State oldState, State newState) =>
        listener1.onStateChanged(oldState, newState);

    when(listener2.onStateChanged(State.stateA, State.stateB)).thenAnswer((_) {
      // listener2 will remove listener1 as soon as notified
      stateMachine.removeListener(actualListener1);
    });

    stateMachine.addListener(actualListener1);
    stateMachine.addListener((State oldState, State newState) =>
        listener2.onStateChanged(oldState, newState));

    // verify state changed and both listeners are notified as expected
    checkEventIsConsumed(stateMachine, [listener1, listener2], Event.event1,
        [State.stateA, State.stateB]);

    // verify state changed and only remaining listener2 is notified as expected
    expect(stateMachine.consumeEvent(Event.event2), true);
    verify(listener2.onStateChanged(State.stateB, State.stateC));
    verifyNoMoreInteractions(listener1);
    verifyNoMoreInteractions(listener2);
  });

  test('remove all listeners via removeAllListeners()', () {
    final listener1 = MockListener();
    final listener2 = MockListener();

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(Transition(
            event: Event.event1, statePath: [State.stateA, State.stateB]))
        .setInitialState(State.stateA)
        .build();

    stateMachine.addListener((State oldState, State newState) =>
        listener1.onStateChanged(oldState, newState));
    stateMachine.addListener((State oldState, State newState) =>
        listener2.onStateChanged(oldState, newState));
    stateMachine.removeAllListeners();

    expect(stateMachine.getCurrentState(), State.stateA);
    expect(stateMachine.consumeEvent(Event.event1), true);
    expect(stateMachine.getCurrentState(), State.stateB);

    verifyZeroInteractions(listener1);
    verifyZeroInteractions(listener2);
  });
}
