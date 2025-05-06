import 'package:flutter/material.dart';

class FolderSelection extends StatelessWidget {
  final bool isAllSelected;
  final bool isMygoSelected;
  final bool isFavoriteSelected;
  final Function(bool) onAllChanged;
  final Function(bool) onMygoChanged;
  final Function(bool) onFavoriteChanged;

  const FolderSelection({
    Key? key,
    required this.isAllSelected,
    required this.isMygoSelected,
    required this.isFavoriteSelected,
    required this.onAllChanged,
    required this.onMygoChanged,
    required this.onFavoriteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ALL Checkbox
        Row(
          children: [
            Checkbox(
              value: isAllSelected,
              onChanged: (bool? value) {
                onAllChanged(value ?? false);
              },
            ),
            const SizedBox(width: 8),
            const Icon(Icons.folder, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('ALL'),
          ],
        ),
        const SizedBox(width: 20),
        // MYGO Checkbox
        Row(
          children: [
            Checkbox(
              value: isMygoSelected,
              onChanged: (bool? value) {
                onMygoChanged(value ?? false);
              },
            ),
            const SizedBox(width: 8),
            const Icon(Icons.folder, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('MYGO'),
          ],
        ),
        const SizedBox(width: 20),
        // FAVORITE Checkbox
        Row(
          children: [
            Checkbox(
              value: isFavoriteSelected,
              onChanged: (bool? value) {
                onFavoriteChanged(value ?? false);
              },
            ),
            const SizedBox(width: 8),
            const Icon(Icons.folder, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('FAVORITE'),
          ],
        ),
      ],
    );
  }
}