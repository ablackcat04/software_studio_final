import 'package:flutter/material.dart';
import 'package:software_studio_final/model//settings.dart';

class SettingsNotifier extends ChangeNotifier {
  Settings _settings = Settings(
    optionNumber: 4,
    myFavorite: true,
    hiddenPictures: false,
    privacyPolicy: true,
    isDarkTheme: false,
  );

  Settings get settings => _settings;

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
}
