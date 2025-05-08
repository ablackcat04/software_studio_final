import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/customList.dart';

class TrendingPage extends StatefulWidget {
  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  final List<ListItemData> _items = List.generate(
    20,
    (i) => ListItemData(
      imageUrl: 'https://picsum.photos/seed/${i + 1}/400/400', // 放大圖片比例
      title: "TOP${i + 1}", // 修改文字為 TOP1、TOP2 等
      subtitle1: "", // 移除副標題
      subtitle2: "", // 移除副標題
    ),
  );

  // 用於追蹤每個項目的收藏狀態
  final List<bool> _isFavorite = List.generate(20, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trending')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          final itemData = _items[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 圖片部分
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    itemData.imageUrl ?? 'https://via.placeholder.com/400',
                    width: MediaQuery.of(context).size.width * 0.6, // 圖片占用 60% 的寬度
                    height: MediaQuery.of(context).size.width * 0.6, // 高度與寬度相同
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8), // 圖片與文字之間的間距
                // 文字與按鈕部分
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顯示文字
                      Text(
                        itemData.title,
                        style: const TextStyle(
                          fontSize: 16, // 調整文字大小
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8), // 文字與按鈕之間的間距
                      // 收藏與複製按鈕
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isFavorite[index]
                                  ? Icons.favorite // 實心愛心
                                  : Icons.favorite_border, // 空心愛心
                            ),
                            color: Colors.red,
                            onPressed: () {
                              setState(() {
                                _isFavorite[index] = !_isFavorite[index]; // 切換收藏狀態
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isFavorite[index]
                                        ? '${itemData.title} added to favorites!'
                                        : '${itemData.title} removed from favorites!',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            color: Colors.blue,
                            onPressed: () {
                              // 複製按鈕的邏輯
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${itemData.title} copied to clipboard!'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
