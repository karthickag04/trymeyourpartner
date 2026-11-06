/// Thrown when a value the member chose (a caste, state or district name) has
/// no matching row. Saving must fail visibly rather than store an empty id,
/// which made registration reappear on every launch.
class LookupNotFoundException implements Exception {
  const LookupNotFoundException(this.field, this.value);

  final String field;
  final String value;

  @override
  String toString() => 'No $field named "$value" was found';
}

/// The id for [name], or null when nothing was chosen. Throws
/// [LookupNotFoundException] when a name was chosen but [id] is missing.
String? requireLookupId(String field, String? name, String? id) {
  if (name == null || name.trim().isEmpty) return null;
  if (id == null || id.isEmpty) throw LookupNotFoundException(field, name);
  return id;
}
