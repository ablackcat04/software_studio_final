import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/favorite_notifier.dart';

class FavoriteButton extends StatelessWidget {
  final String id;
  final String imageUrl;
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
        favoriteNotifier.toggleFavorite(id, imageUrl, title);
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
