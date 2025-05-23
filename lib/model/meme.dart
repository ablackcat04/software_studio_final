class Meme {
  Meme({
    required this.id,
    required this.isFavorite,
    required this.popularity,
    required this.category,
  });

  int id;
  bool isFavorite;
  int popularity;
  String category;

  factory Meme.fromMap(Map<String, dynamic> map) => Meme(
    id: map["id"],
    isFavorite: map["isFavorite"] ?? false,
    popularity: map["popularity"] ?? 0,
    category: map["category"] ?? "",
  );
  Map<String, dynamic> toMap() => {
    "id": id,
    "isFavorite": isFavorite,
    "popularity": popularity,
    "category": category,
  };
}
