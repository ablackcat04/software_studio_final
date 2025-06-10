// state/settings_notifier.dart

import 'package:flutter/material.dart';
import 'package:software_studio_final/model/settings.dart';

class SettingsNotifier extends ChangeNotifier {
  Settings _settings = Settings(
    optionNumber: 4,
    myFavorite: true,
    hiddenPictures: false,
    privacyPolicy: true,
    isDarkTheme: false,
    enabledFolders: {'all'}, // <-- Initialize with 'all' selected
  );

  Settings get settings => _settings;

  // A convenient getter for the list of enabled folders, ready to be sent to the API.
  // If 'all' is selected, you might want to send a specific list of all available folders.
  // For now, let's just return the set. The backend can interpret 'all'.
  Set<String> get enabledFolders => _settings.enabledFolders;

  void toggleFolder(String folderId) {
    final currentFolders = _settings.enabledFolders;

    if (folderId == 'all') {
      // If 'all' is tapped, clear everything and just add 'all'.
      currentFolders.clear();
      currentFolders.add('all');
    } else {
      // If any other folder is tapped:
      // 1. Remove 'all' if it's currently selected.
      currentFolders.remove('all');

      // 2. Toggle the selected folder.
      if (currentFolders.contains(folderId)) {
        currentFolders.remove(folderId);
      } else {
        currentFolders.add(folderId);
      }
    }

    // 3. Failsafe: If no folder is selected, default back to 'all'.
    // This prevents a state where nothing can be searched.
    if (currentFolders.isEmpty) {
      currentFolders.add('all');
    }

    notifyListeners();
  }

  void setSettings(Settings settings) {
    _settings = settings;
    notifyListeners();
  }

  void setOptionNumber(int value) {
    _settings.optionNumber = value;
    notifyListeners();
  }

  void setTheme(bool value) {
    _settings.isDarkTheme = value;
    notifyListeners();
  }

  void setHiddenPictures(bool value) {
    _settings.hiddenPictures = value;
    notifyListeners();
  }

  int getoptionnumbers() {
    return _settings.optionNumber;
  }
}
