import 'package:test/test.dart';

import 'package:dart_state_machine/src/error.dart';
import 'package:dart_state_machine/src/state_machine.dart';
import 'package:dart_state_machine/src/transition.dart';

import 'utils.dart';

void main() {
  test('builder should fail if no transitions have been added', () {
    expect(
        () => StateMachineBuilder<Event, State>()
            .setInitialState(State.stateA)
            .build(),
        throwsA(predicate((e) =>
            e is StateMachineBuilderValidationError &&
            e.message ==
                'no transitions defined, make sure to '
                    'call StateMachineBuilder<Event, State>.addTransition()')));
  });

  test('builder should fail if initial state has not been set', () {
    final transition = Transition(
        event: Event.event1, statePath: [State.stateA, State.stateB]);
    expect(
        () => StateMachineBuilder<Event, State>()
            .addTransition(transition)
            .build(),
        throwsA(predicate((e) =>
            e is StateMachineBuilderValidationError &&
            e.message ==
                'initial state is not defined, make sure to call '
                    'StateMachineBuilder<Event, State>.setInitialState()')));
  });

  test(
      'builder should fail if transition with the same event '
      'AND start state has been already added (option 1)', () {
    final event = Event.event1;
    final state = State.stateA;

    final transition1 =
        Transition(event: event, statePath: [state, State.stateB]);
    final transition2 =
        Transition(event: event, statePath: [state, State.stateB]);

    expect(
        () => StateMachineBuilder<Event, State>()
            .addTransition(transition1)
            .addTransition(transition2),
        throwsA(predicate((e) =>
            e is StateMachineBuilderValidationError &&
            e.message == _getMessageForDuplicateStartState(event, state))));
  });

  test(
      'builder should fail if transition with the same event '
      'AND start state has been already added (option 2)', () {
    final event = Event.event1;
    final state = State.stateA;

    final transition1 =
        Transition(event: event, statePath: [state, State.stateB]);
    final transition2 = Transition(
        event: event, statePath: [state, State.stateB, State.stateC]);

    expect(
        () => StateMachineBuilder<Event, State>()
            .addTransition(transition1)
            .addTransition(transition2),
        throwsA(predicate((e) =>
            e is StateMachineBuilderValidationError &&
            e.message == _getMessageForDuplicateStartState(event, state))));
  });

  test(
      'builder should fail if transition with the same event '
      'AND start state has been already added (option 3)', () {
    final event = Event.event1;
    final state = State.stateA;

    final transition1 = Transition(
        event: event, statePath: [state, State.stateB, State.stateC]);
    final transition2 =
        Transition(event: event, statePath: [state, State.stateB]);

    expect(
        () => StateMachineBuilder<Event, State>()
            .addTransition(transition1)
            .addTransition(transition2),
        throwsA(predicate((e) =>
            e is StateMachineBuilderValidationError &&
            e.message == _getMessageForDuplicateStartState(event, state))));
  });

  test(
      'builder should fail if there is no transition defined '
      'with start state matching the initial state', () {
    final transition = Transition(
        event: Event.event1, statePath: [State.stateA, State.stateB]);
    final initialState = State.stateC;

    expect(
        () => StateMachineBuilder<Event, State>()
            .setInitialState(initialState)
            .addTransition(transition)
            .build(),
        throwsA(predicate((e) =>
            e is StateMachineBuilderValidationError &&
            e.message ==
                'no transition defined with start state matching '
                    'the initial state ($initialState)')));
  });

  test('builder should successfully create state machine', () {
    final transition1 = Transition(
        event: Event.event1, statePath: [State.stateA, State.stateB]);
    final transition2 = Transition(
        event: Event.event2, statePath: [State.stateB, State.stateC]);
    final transition3 = Transition(
        event: Event.event3,
        statePath: [State.stateA, State.stateB, State.stateA]);

    final state = State.stateA;

    final stateMachine = StateMachineBuilder<Event, State>()
        .addTransition(transition1)
        .addTransition(transition2)
        .addTransition(transition3)
        .setInitialState(state)
        .build();

    expect(stateMachine.getCurrentState(), state);
  });

  test(
      'once a state machine is created adding a new transition '
      'to builder should not affect the state machine', () {
    final transition1 = Transition(
        event: Event.event1, statePath: [State.stateA, State.stateB]);

    final stateMachineBuilder = StateMachineBuilder<Event, State>();
    final stateMachine = stateMachineBuilder
        .addTransition(transition1)
        .setInitialState(State.stateA)
        .build();

    expect(stateMachine.consumeEvent(Event.event1), true);
    expect(stateMachine.getCurrentState(), State.stateB);

    expect(stateMachine.consumeEvent(Event.event2), false);
    expect(stateMachine.getCurrentState(), State.stateB);

    final transition2 = Transition(
        event: Event.event2, statePath: [State.stateB, State.stateC]);
    stateMachineBuilder.addTransition(transition2);

    expect(stateMachine.consumeEvent(Event.event2), false);
    expect(stateMachine.getCurrentState(), State.stateB);
  });
}

String _getMessageForDuplicateStartState(Event event, State state) =>
    'duplicate transition: a transition for event \'$event\' '
    'and starting state \'$state\' is already present';
