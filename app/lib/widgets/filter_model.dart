typedef FilterChoice = Map<String, String>;

class FilterOption {
  const FilterOption(this.id, this.label);

  final String id;
  final String label;
}

class FilterSection {
  const FilterSection({
    required this.key,
    required this.title,
    required this.options,
  });

  final String key;
  final String title;
  final List<FilterOption> options;
}
