import 'dart:collection';

import 'error.dart';
import 'event.dart';
import 'state.dart';
import 'transition.dart';
import 'transition_identity.dart';

/// [StateMachine] is a general purpose finite-state machine.
///
/// * [Event] - event parameter, must implement [StateMachineEvent].
/// * [State] - state parameter, must implement [StateMachineState].
///
/// To create an instance of [StateMachine] please use [StateMachineBuilder].
///
class StateMachine<Event extends StateMachineEvent,
    State extends StateMachineState> {
  final Map<TransitionIdentity<Event, State>, List<State>> _graph;
  State _currentState;

  final LinkedHashSet<StateMachineListener<State>> _listeners = LinkedHashSet();
  bool _inTransition = false;

  StateMachine._(Map<TransitionIdentity<Event, State>, List<State>> graph,
      State initialState)
      : _graph = graph,
        _currentState = initialState;

  /// Adds a [listener] to this [StateMachine].
  ///
  /// If this [listener] has been already added, then this call is no op.
  void addListener(StateMachineListener<State> listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Removes all listeners from this [StateMachine].
  void removeAllListeners() {
    _listeners.clear();
  }

  /// Removes a [listener] from this [StateMachine].
  void removeListener(StateMachineListener<State> listener) {
    _listeners.remove(listener);
  }

  /// Returns current [State] for this [StateMachine].
  State getCurrentState() {
    return _currentState;
  }

  /// Moves this [StateMachine] from the current state to a new one (if there is a matching transition).
  ///
  /// Depending on configuration of this [StateMachine] there may be several state changes
  /// for a single [consumeEvent()] call.
  ///
  /// Missed [consumeEvent()] calls (meaning no matching transition found) are ignored (no op).
  ///
  /// State changes are communicated via the [StateMachineListener] listeners.
  ///
  /// Returns a flag of whether the event was actually consumed (meaning moving to a new state) or ignored.
  ///
  /// Throws [StateError] if there is a matching transition for this event and current state,
  /// but there is still an unfinished transition in progress.
  bool consumeEvent(Event event) {
    var transitionIdentity = TransitionIdentity(event, _currentState);
    var transition = _graph[transitionIdentity];
    if (transition == null) {
      return false;
    }

    if (_inTransition) {
      throw StateError('there is a transition which is still in progress');
    }

    final len = transition.length;
    for (var i = 0; i < len; i++) {
      _inTransition = (i < (len - 1));
      var oldState = _currentState;
      var newState = transition[i];
      _currentState = newState;
      for (var listener in _listeners.toList()) {
        listener.call(oldState, newState);
      }
    }

    return true;
  }
}

/// A callback to communicate state changes of a [StateMachine].
typedef StateMachineListener<State extends StateMachineState> = void Function(
    State oldState, State newState);

/// [StateMachineBuilder] is used to create an instance of [StateMachine].
///
/// * [Event] - event parameter, must implement [StateMachineEvent].
/// * [State] - state parameter, must implement [StateMachineState].
class StateMachineBuilder<Event extends StateMachineEvent,
    State extends StateMachineState> {
  final _graph = HashMap<TransitionIdentity<Event, State>, List<State>>();
  State? _initialState;

  /// Adds a [transition] to the state machine configuration.
  ///
  /// Transition is a definition of a state path for a give event.
  ///
  /// Throws [StateMachineBuilderValidationError] if a duplicate transition identified
  /// (by a combination of event and starting state).
  StateMachineBuilder<Event, State> addTransition(
      Transition<Event, State> transition) {
    var statePathCopy = transition.statePath.toList();
    var startState = statePathCopy.removeAt(0);

    if (_graph.containsKey(transition.identity)) {
      throw StateMachineBuilderValidationError(
          "duplicate transition: a transition for event '${transition.event}' "
          "and starting state '${startState}' is already present");
    }

    _graph[transition.identity] = List.unmodifiable(statePathCopy);

    return this;
  }

  /// Sets initial [state] of the state machine.
  StateMachineBuilder<Event, State> setInitialState(State state) {
    _initialState = state;
    return this;
  }

  /// Returns a newly created instance of [StateMachine].
  ///
  /// Throws [StateMachineBuilderValidationException] in the following cases:
  /// * if initial state has not been set (see [setInitialState()])
  /// * if no transitions have been added (see [addTransition()])
  /// * if no transition defined with starting state matching the initial state
  StateMachine<Event, State> build() {
    var initState = _initialState;
    if (initState == null) {
      throw StateMachineBuilderValidationError('initial state is not defined, '
          'make sure to call $runtimeType.setInitialState()');
    }

    if (_graph.isEmpty) {
      throw StateMachineBuilderValidationError('no transitions defined,'
          ' make sure to call $runtimeType.addTransition()');
    }

    if (!(_graph.keys
        .map((transitionIdentity) => transitionIdentity.state)
        .contains(initState))) {
      throw StateMachineBuilderValidationError(
          'no transition defined with start state '
          'matching the initial state ($initState)');
    }

    return StateMachine._(HashMap.from(_graph), initState);
  }
}
