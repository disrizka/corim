/// Shared "entity" reference (company/legal entity), e.g. "Corim Indonesia".
///
/// Mirrors the shape returned by `GET /entities`:
/// ```json
/// { "id": "...", "code": "CI", "name": "Corim Indonesia" }
/// ```
/// Used anywhere an entity needs to be picked or displayed: expense request
/// list (card + filter) and the home screen request list.
class EntityItem {
  final String id;
  final String code;
  final String name;

  const EntityItem({required this.id, required this.code, required this.name});

  factory EntityItem.fromJson(dynamic json) {
    if (json is! Map) return const EntityItem(id: '', code: '-', name: '-');
    final map = Map<String, dynamic>.from(json);
    return EntityItem(
      id: (map['id'] ?? '').toString(),
      code: (map['code'] ?? '-').toString(),
      name: (map['name'] ?? '-').toString(),
    );
  }

  /// "CI - Corim Indonesia" style label used in badges/chips.
  String get displayLabel =>
      code.isNotEmpty && code != '-' ? '$code - $name' : name;

  @override
  bool operator ==(Object other) => other is EntityItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
