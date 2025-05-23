import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/favorite_notifier.dart';
import 'package:software_studio_final/widgets/favorite_button.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteNotifier = Provider.of<FavoriteNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite')),
      body:
          favoriteNotifier.favorites.isEmpty
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

                  print(item.imageUrl);

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
                          child:
                              item.imageUrl.startsWith('http')
                                  ? Image.network(
                                    item.imageUrl,
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    height:
                                        MediaQuery.of(context).size.width * 0.6,
                                    fit: BoxFit.cover,
                                  )
                                  : // 如果是本地圖片，使用 AssetImage
                                  // 注意：這裡的路徑需要根據實際情況調整
                                  Image.asset(
                                    item.imageUrl,
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    height:
                                        MediaQuery.of(context).size.width * 0.6,
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
