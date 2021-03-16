import 'package:test/test.dart';
import 'package:dart_state_machine/src/transition.dart';
import 'package:dart_state_machine/src/transition_identity.dart';

import 'utils.dart';

void main() {
  var testParameters = [
    TestParams([State.stateA, State.stateB], null),
    TestParams([State.stateA, State.stateB, State.stateC], null),
    TestParams([State.stateA, State.stateB, State.stateA], null),
    TestParams([State.stateA, State.stateB, State.stateA, State.stateB], null),
    TestParams([State.stateA, State.stateB, State.stateC, State.stateD], null),
    TestParams(
        [State.stateA, State.stateB, State.stateC, State.stateD, State.stateE],
        null),
    TestParams([], ArgumentError('statePath must contain at least 2 items')),
    TestParams([State.stateA],
        ArgumentError('statePath must contain at least 2 items')),
    TestParams([State.stateA, State.stateA],
        ArgumentError('statePath must not have repeating items in a row')),
    TestParams([State.stateA, State.stateA, State.stateB],
        ArgumentError('statePath must not have repeating items in a row')),
    TestParams([State.stateA, State.stateB, State.stateB],
        ArgumentError('statePath must not have repeating items in a row')),
    TestParams([State.stateA, State.stateB, State.stateB, State.stateA],
        ArgumentError('statePath must not have repeating items in a row'))
  ];

  for (var params in testParameters) {
    if (params.expectedError == null) {
      test('Creation should not fail for $params', () {
        final transition =
            Transition(event: Event.event1, statePath: params.statePath);
        expect(transition.identity,
            TransitionIdentity(transition.event, transition.statePath.first));
      });
    } else {
      test('Creation should fail for $params', () {
        expect(
            () => Transition(event: Event.event1, statePath: params.statePath),
            throwsA(predicate((e) =>
                e is ArgumentError &&
                e.message == params.expectedError!.message)));
      });
    }
  }
}

class TestParams {
  final List<State> statePath;
  final ArgumentError? expectedError;

  TestParams(this.statePath, this.expectedError);

  @override
  String toString() {
    return 'TestParams{statePath: $statePath, expectedError: $expectedError}';
  }
}
