import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:software_studio_final/model//meme.dart';

class MemeNotifier extends ChangeNotifier {
  final List<Meme> _memes = [];

  List<Meme> get memes => _memes;

  MemeNotifier() {
    _loadMemes();
  }
  void _loadMemes() async {
    final box = await Hive.openBox('memes');
    final memeList = List<Map<String, dynamic>>.from(box.get("memes"));
    _memes.addAll(memeList.map((meme) => Meme.fromMap(meme)).toList());
    notifyListeners();
  }

  void save() async {
    final box = await Hive.openBox('memes');
    box.put("memes", _memes.map((meme) => meme.toMap()).toList());
  }

  Meme getMemeById(String id) {
    return _memes.firstWhere((meme) => meme.id == id);
  }
}
