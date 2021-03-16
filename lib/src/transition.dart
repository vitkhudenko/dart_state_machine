import 'event.dart';
import 'state.dart';
import 'transition_identity.dart';

/// A transition is a core entity in state machine configuration. Transition
/// defines a state path for a given event. The event triggers state changes
/// in accordance with the state path. State machine's current state must be
/// equal to the first state of the transition's state path in order for the
/// event to be consumed (and current state changed according to the transition's
/// state path).
///
/// * [Event] - event parameter, must implement [StateMachineEvent].
/// * [State] - state parameter, must implement [StateMachineState].
class Transition<Event extends StateMachineEvent,
    State extends StateMachineState> {
  final Event event;
  final List<State> statePath;
  final TransitionIdentity<Event, State> identity;

  /// A transition defines its identity as a pair of the [event] and the starting state
  /// (the first item in the [statePath]). [StateMachine] allows unique transitions
  /// only (each transition must have a unique identity).
  ///
  /// Param [event] - triggering event for this transition.
  ///
  /// Param [statePath] - a list of states for this transition. First item
  /// is a starting state for the transition. Must have at least two items.
  /// Must not have repeating items in a row (e.g. `[A, A]` or `[A, B, B]` are invalid).
  ///
  /// Throws [ArgumentError] if statePath is empty or has just a single item.
  ///
  /// Throws [ArgumentError] if statePath has repeating items in a row.
  ///
  Transition({required Event event, required List<State> statePath})
      : identity =
            TransitionIdentity(event, _validateStatePath(statePath).first),
        event = event,
        statePath = statePath.toList();

  static List<State> _validateStatePath<State extends StateMachineState>(
      List<State> statePath) {
    if (statePath.length < 2) {
      throw ArgumentError('statePath must contain at least 2 items');
    }

    var iterator = statePath.iterator..moveNext();
    var current = iterator.current;
    while (iterator.moveNext()) {
      var next = iterator.current;
      if (current == next) {
        throw ArgumentError('statePath must not have repeating items in a row');
      }
      current = next;
    }

    return statePath;
  }
}
