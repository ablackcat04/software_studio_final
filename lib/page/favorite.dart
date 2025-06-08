import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/favorite_notifier.dart';
import 'package:software_studio_final/widgets/favorite_button.dart';
import 'package:software_studio_final/widgets/copy_button.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteNotifier = Provider.of<FavoriteNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite')),
      body: favoriteNotifier.favorites.isEmpty
          ? const Center(
              child: Text(
                'No favorites yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: favoriteNotifier.favorites.length,
              itemBuilder: (BuildContext context, int index) {
                final item = favoriteNotifier.favorites[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 圖片部分
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          item.imageUrl,
                          width: MediaQuery.of(context).size.width * 0.7, // 圖片佔螢幕寬度的 70%
                          height: MediaQuery.of(context).size.width * 0.7, // 高度與寬度一致
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8), // 圖片與按鈕之間的間距
                      // 按鈕部分
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FavoriteButton(
                            id: item.id,
                            imageUrl: item.imageUrl,
                            title: item.title,
                          ),
                          const SizedBox(height: 8), // 按鈕之間的間距
                          CopyButton(imagePath: item.imageUrl),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
