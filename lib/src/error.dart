class StateMachineBuilderValidationError extends Error {
  final String message;

  StateMachineBuilderValidationError(this.message);

  @override
  String toString() => '${runtimeType}: $message';
}
