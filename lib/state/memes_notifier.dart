import 'package:flutter/material.dart';
import 'package:software_studio_final/model//meme.dart';

class MemeNotifier extends ChangeNotifier {
  List<Meme> _memes = [];

  List<Meme> get memes => _memes;

  Meme getMemeById(String id) {
    return _memes.firstWhere((meme) => meme.id == id);
  }

  Meme getPopularMeme(int offset) {
    return _memes[offset];
  }
}
