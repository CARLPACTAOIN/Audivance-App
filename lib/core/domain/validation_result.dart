class ValidationResult {
  const ValidationResult._(this.messages);

  const ValidationResult.valid() : messages = const [];

  factory ValidationResult.invalid(Iterable<String> messages) {
    final normalized = messages
        .map((message) => message.trim())
        .where((message) => message.isNotEmpty)
        .toList(growable: false);
    if (normalized.isEmpty) {
      return const ValidationResult.valid();
    }
    return ValidationResult._(normalized);
  }

  factory ValidationResult.failure(String message) {
    return ValidationResult.invalid([message]);
  }

  final List<String> messages;

  bool get isValid => messages.isEmpty;
  bool get isInvalid => !isValid;

  String get summary => messages.join('\n');

  ValidationResult merge(ValidationResult other) {
    return ValidationResult.invalid([...messages, ...other.messages]);
  }

  static ValidationResult combine(Iterable<ValidationResult> results) {
    return ValidationResult.invalid(
      results.expand((result) => result.messages),
    );
  }
}
