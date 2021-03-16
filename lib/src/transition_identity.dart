import 'event.dart';
import 'state.dart';

/// Represents an identity of a [Transition].
///
/// This class is for internal usage and should not be instantiated directly by client/consumer code.
class TransitionIdentity<Event extends StateMachineEvent,
    State extends StateMachineState> {
  final Event event;
  final State state;

  const TransitionIdentity(this.event, this.state);

  @override
  String toString() => 'TransitionIdentity { event: $event, state: $state }';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransitionIdentity &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          state == other.state);

  @override
  int get hashCode => event.hashCode ^ state.hashCode;
}
