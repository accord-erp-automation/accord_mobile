class AdminItemGroupTreeEntry {
  const AdminItemGroupTreeEntry({
    required this.name,
    required this.itemGroupName,
    required this.parentItemGroup,
    required this.isGroup,
  });

  final String name;
  final String itemGroupName;
  final String parentItemGroup;
  final bool isGroup;

  factory AdminItemGroupTreeEntry.fromJson(Map<String, dynamic> json) {
    return AdminItemGroupTreeEntry(
      name: json['name'] as String? ?? '',
      itemGroupName: json['item_group_name'] as String? ?? '',
      parentItemGroup: json['parent_item_group'] as String? ?? '',
      isGroup: json['is_group'] as bool? ?? false,
    );
  }
}
