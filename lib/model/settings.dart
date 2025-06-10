class Settings {
  Settings({
    required this.optionNumber,
    required this.myFavorite,
    required this.hiddenPictures,
    required this.privacyPolicy,
    required this.isDarkTheme,
    required this.enabledFolders,
  });

  int optionNumber;
  bool myFavorite;
  bool hiddenPictures;
  bool privacyPolicy;
  bool isDarkTheme;
  Set<String> enabledFolders;

  Settings copyWith({
    int? optionNumber,
    bool? myFavorite,
    bool? hiddenPictures,
    bool? privacyPolicy,
    bool? isDarkTheme,
  }) {
    return Settings(
      optionNumber: optionNumber ?? this.optionNumber,
      myFavorite: myFavorite ?? this.myFavorite,
      hiddenPictures: hiddenPictures ?? this.hiddenPictures,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      enabledFolders: enabledFolders,
    );
  }
}
