import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/customList.dart';

class FavoritePage extends StatefulWidget {
  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final List<ListItemData> _items = List.generate(
    20,
    (i) => ListItemData(
      imageUrl: 'https://picsum.photos/seed/${i + 1}/200/200', // 放大圖片比例
      title: "TOP${i + 1}", // 修改文字為 TOP1、TOP2 等
      subtitle1: "", // 移除副標題
      subtitle2: "", // 移除副標題
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          final itemData = _items[index];

          return CustomListItemWidget(
            itemData: itemData,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied ${itemData.title} to clipboard!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
