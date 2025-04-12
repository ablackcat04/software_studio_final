import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/customList.dart';

class TrendingPage extends StatelessWidget {
  final List<ListItemData> _items = List.generate(
    20,
    (i) => ListItemData(
      // Example of using a placeholder image URL - replace with real ones
      imageUrl:
          'https://picsum.photos/seed/${i + 1}/80/80', // Random image based on index
      title: "Trending Meme ${i + 1}",
      subtitle1:
          "This is the first subtitle for item ${i + 1}. It can be a bit longer.",
      // Make subtitle2 sometimes null or empty for testing the condition
      subtitle2: (i % 3 == 0) ? "Optional Info ${i + 1}" : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trending')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          // Get the data for the current item
          final itemData = _items[index];

          // Create an instance of the custom widget, passing the data
          return CustomListItemWidget(
            itemData: itemData,
            onTap: () {
              // Handle item tap - e.g., navigate or show details
              print('Copied: ${itemData.title}');
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
