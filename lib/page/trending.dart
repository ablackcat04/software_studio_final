import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/favorite_button.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      20,
      (i) => ListItemData(
        id: 'item_${i + 1}',
        imageUrl: 'https://picsum.photos/seed/${i + 1}/400/400',
        title: "TOP${i + 1}",
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Trending')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = items[index];

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 圖片部分
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    item.imageUrl,
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                // 收藏按鈕
                FavoriteButton(
                  id: item.id,
                  imageUrl: item.imageUrl,
                  title: item.title,
                ),
              ],
            ),
          );
        },
      ),
    );
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
