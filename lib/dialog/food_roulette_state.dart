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
  final List<FoodItem> foods;
  final bool isSpinning;
  final int selectedIndex;
  final FoodItem? selectedFood;
  final bool isLoading;

  FoodRouletteState({
    this.foods = const [],
    this.isSpinning = false,
    this.selectedIndex = -1,
    this.selectedFood,
    this.isLoading = false,
  });

  FoodRouletteState copyWith({
    List<FoodItem>? foods,
    bool? isSpinning,
    int? selectedIndex,
    FoodItem? selectedFood,
    bool? isLoading,
  }) {
    return FoodRouletteState(
      foods: foods ?? this.foods,
      isSpinning: isSpinning ?? this.isSpinning,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedFood: selectedFood ?? this.selectedFood,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
