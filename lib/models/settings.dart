class Settings {
  Settings({
    required this.optionNumbers,
    required this.myFavorite,
    required this.hiddenPictures,
    required this.privacyPolicy,
    required this.isDarkTheme,
  });

  int optionNumbers;
  bool myFavorite;
  bool hiddenPictures;
  bool privacyPolicy;
  bool isDarkTheme;

  Settings copyWith({
    int? optionNumbers,
    bool? myFavorite,
    bool? hiddenPictures,
    bool? privacyPolicy,
    bool? isDarkTheme,
  }) {
    return Settings(
      optionNumbers: optionNumbers ?? this.optionNumbers,
      myFavorite: myFavorite ?? this.myFavorite,
      hiddenPictures: hiddenPictures ?? this.hiddenPictures,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }
}
