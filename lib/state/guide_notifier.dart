import 'package:flutter/foundation.dart';

class GuideNotifier extends ChangeNotifier {
  String _guide = "";

  String get guide => _guide;

  GuideNotifier() {}

  void setGuide(String newGuide) {
    _guide = newGuide;
    notifyListeners();
  }
}
