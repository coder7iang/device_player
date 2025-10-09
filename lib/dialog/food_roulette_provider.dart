import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_player/dialog/food_roulette_state.dart';

final foodRouletteProvider = StateNotifierProvider<FoodRouletteNotifier, FoodRouletteState>((ref) {
  return FoodRouletteNotifier();
});

class FoodRouletteNotifier extends StateNotifier<FoodRouletteState> {
  FoodRouletteNotifier() : super(FoodRouletteState()) {
    _loadFoodData();
  }

  /// 加载食物数据
  Future<void> _loadFoodData() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final String jsonString = await rootBundle.loadString('assets/data/food_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> foodsJson = jsonData['foods'] ?? [];
      
      final List<FoodItem> foods = foodsJson
          .map((json) => FoodItem.fromJson(json))
          .toList();
      
      state = state.copyWith(
        foods: foods,
        isLoading: false,
      );
      
      debugPrint('加载食物数据成功: ${foods.length} 个食物');
    } catch (e) {
      debugPrint('加载食物数据失败: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 开始旋转
  void startSpin() {
    if (state.foods.isEmpty) {
      debugPrint('食物数据为空，无法开始旋转');
      return;
    }
    
    state = state.copyWith(
      isSpinning: true,
      selectedIndex: -1,
      selectedFood: null,
    );
    
    debugPrint('开始旋转轮盘');
  }

  /// 停止旋转并选择食物
  void stopSpin() {
    if (state.foods.isEmpty) {
      debugPrint('食物数据为空，无法停止旋转');
      return;
    }
    
    final random = Random();
    final selectedIndex = random.nextInt(state.foods.length);
    final selectedFood = state.foods[selectedIndex];
    
    state = state.copyWith(
      isSpinning: false,
      selectedIndex: selectedIndex,
      selectedFood: selectedFood,
    );
    
    debugPrint('停止旋转，选中食物: ${selectedFood.name}');
  }

  /// 重新开始
  void reset() {
    state = state.copyWith(
      isSpinning: false,
      selectedIndex: -1,
      selectedFood: null,
    );
  }
}
