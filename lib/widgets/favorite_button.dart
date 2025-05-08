import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  final String id;

  const FavoriteButton({super.key, required this.id});

  void _onToggleLike(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          true ? '${id} added to favorites!' : '${id} removed from favorites!',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _onToggleLike(context),
      icon: IconButton(
        icon: Icon(true ? Icons.favorite : Icons.favorite_border),
        color: true ? Colors.pinkAccent : Colors.grey,
        onPressed: () => _onToggleLike(context),
      ),
    );
  }
}
