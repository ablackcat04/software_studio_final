class Meme {
  Meme({
    required this.id,
    required this.isFavorite,
    required this.popularity,
    required this.category,
  });

  String id;
  bool isFavorite;
  int popularity;
  String category;

  Meme copyWith({
    String? id,
    bool? isFavorite,
    int? popularity,
    String? category,
  }) {
    return Meme(
      id: id ?? this.id,
      isFavorite: isFavorite ?? this.isFavorite,
      popularity: popularity ?? this.popularity,
      category: category ?? this.category,
    );
  }
}
