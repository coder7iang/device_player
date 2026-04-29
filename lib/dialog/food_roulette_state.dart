class FoodItem {
  final int id;
  final String name;
  final String category;
  final String description;
  final String address;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'address': address,
    };
  }
}

class FoodRouletteState {
  static const String defaultTitle = '🍽️ 今天吃什么？';

  final List<FoodItem> foods;
  final bool isSpinning;
  final int selectedIndex;
  final FoodItem? selectedFood;
  final bool isLoading;
  final String title;

  FoodRouletteState({
    this.foods = const [],
    this.isSpinning = false,
    this.selectedIndex = -1,
    this.selectedFood,
    this.isLoading = false,
    this.title = defaultTitle,
  });

  FoodRouletteState copyWith({
    List<FoodItem>? foods,
    bool? isSpinning,
    int? selectedIndex,
    FoodItem? selectedFood,
    bool? isLoading,
    String? title,
    bool clearSelectedFood = false,
  }) {
    return FoodRouletteState(
      foods: foods ?? this.foods,
      isSpinning: isSpinning ?? this.isSpinning,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedFood: clearSelectedFood ? null : (selectedFood ?? this.selectedFood),
      isLoading: isLoading ?? this.isLoading,
      title: title ?? this.title,
    );
  }
}
