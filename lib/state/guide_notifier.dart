import 'package:flutter/foundation.dart';

class GuideNotifier extends ChangeNotifier {
  String _guide = "";
  String _mode = "一般";

  String get guide => _guide;
  String get mode => _mode;

  GuideNotifier() {}

  void setGuide(String newGuide) {
    _guide = newGuide;
    notifyListeners();
  }

  void setMode(String newMode) {
    _mode = newMode;
    notifyListeners();
  }
}
