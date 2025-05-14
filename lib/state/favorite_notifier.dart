import 'package:flutter/material.dart';

class FavoriteNotifier extends ChangeNotifier {
  final List<ListItemData> _favorites = []; // 收藏的圖片資料
  final Set<String> _favoriteIds = {}; // 收藏的圖片 ID

  List<ListItemData> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id, String imageUrl, String title) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      _favorites.removeWhere((item) => item.id == id);
    } else {
      _favoriteIds.add(id);
      _favorites.add(ListItemData(id: id, imageUrl: imageUrl, title: title));
    }
    notifyListeners(); // 通知所有監聽者狀態已更新
  }
}

class ListItemData {
  final String id;
  final String imageUrl;
  final String title;

  ListItemData({
    required this.id,
    required this.imageUrl,
    required this.title,
  });
}