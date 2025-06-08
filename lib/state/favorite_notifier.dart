import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Your ListItemData class from Step 2 should be here or imported

class FavoriteNotifier extends ChangeNotifier {
  final List<ListItemData> _favorites = [];
  final Set<String> _favoriteIds = {};

  // A constant for our filename
  static const _kFavoritesFileName = 'favorites.json';

  FavoriteNotifier() {
    // When the notifier is created, load favorites from disk
    loadFavoritesFromDisk();
  }

  List<ListItemData> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id, String imageUrl, String title) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      _favorites.removeWhere((item) => item.id == id);
    } else {
      _favoriteIds.add(id);
      _favorites.add(ListItemData(id: id, imageUrl: imageUrl, title: title));
    }
    // Save the updated list to disk every time it changes
    _saveFavoritesToDisk();
    notifyListeners();
  }

  /// Gets the local path for the app's documents directory.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Gets the file where favorites are stored.
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_kFavoritesFileName');
  }

  /// Saves the current list of favorites to the disk as a JSON file.
  Future<void> _saveFavoritesToDisk() async {
    try {
      final file = await _localFile;
      // Convert the list of ListItemData objects to a list of Maps
      final List<Map<String, dynamic>> jsonList =
          _favorites.map((item) => item.toJson()).toList();
      // Encode the list of Maps to a JSON string
      final jsonString = jsonEncode(jsonList);
      // Write the string to the file
      await file.writeAsString(jsonString);
    } catch (e) {
      // Handle potential errors, e.g., by logging them
      debugPrint("Error saving favorites: $e");
    }
  }

  /// Loads the list of favorites from the disk.
  Future<void> loadFavoritesFromDisk() async {
    try {
      final file = await _localFile;

      // If the file doesn't exist, there's nothing to load.
      if (!await file.exists()) {
        debugPrint("Favorites file does not exist. Nothing to load.");
        return;
      }

      // Read the file content
      final jsonString = await file.readAsString();
      // Decode the JSON string into a List of dynamic objects (maps)
      final List<dynamic> jsonList = jsonDecode(jsonString);

      // Clear current lists before loading
      _favorites.clear();
      _favoriteIds.clear();

      // Convert each map back into a ListItemData object and add to our lists
      for (var jsonItem in jsonList) {
        final item = ListItemData.fromJson(jsonItem as Map<String, dynamic>);
        _favorites.add(item);
        _favoriteIds.add(item.id);
      }

      // Notify listeners that the data has been loaded
      notifyListeners();
      debugPrint("Favorites loaded successfully.");
    } catch (e) {
      // Handle potential errors during loading
      debugPrint("Error loading favorites: $e");
    }
  }
}

// Don't forget your ListItemData class with toJson/fromJson
class ListItemData {
  final String id;
  final String imageUrl;
  final String title;

  ListItemData({required this.id, required this.imageUrl, required this.title});

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'title': title,
  };

  factory ListItemData.fromJson(Map<String, dynamic> json) {
    return ListItemData(
      id: json['id'],
      imageUrl: json['imageUrl'],
      title: json['title'],
    );
  }
}
