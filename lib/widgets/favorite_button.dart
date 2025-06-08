import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/page/trending.dart';
import 'package:software_studio_final/state/favorite_notifier.dart';

class FavoriteButton extends StatelessWidget {
  final String id;
  final String imageUrl; // This will be used as the 'path'
  final String title;

  const FavoriteButton({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteNotifier = Provider.of<FavoriteNotifier>(context);
    final isFavorite = favoriteNotifier.isFavorite(id);

    return IconButton(
      onPressed: () {
        // We only interact with the 'trending' collection when ADDING a favorite.
        if (!isFavorite) {
          // --- THIS IS THE KEY CHANGE ---
          // Call the new, more powerful service method.
          // It handles both creating a new document and incrementing an existing one.
          FirestoreService().addOrIncrementMeme(
            memeId: id,
            path:
                imageUrl, // Pass the imageUrl as the path for the new document
          );
        }

        // Your existing local state management logic remains the same.
        favoriteNotifier.toggleFavorite(id, imageUrl, title);

        // Your existing SnackBar feedback remains the same.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite
                  ? '$title removed from favorites!'
                  : '$title added to favorites!',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      color: isFavorite ? Colors.pinkAccent : Colors.grey,
    );
  }
}
