class Settings {
  Settings({
    required this.optionNumber,
    required this.myFavorite,
    required this.hiddenPictures,
    required this.privacyPolicy,
    required this.isDarkTheme,
  });

  int optionNumber;
  bool myFavorite;
  bool hiddenPictures;
  bool privacyPolicy;
  bool isDarkTheme;

  factory Settings.fromMap(Map<dynamic, dynamic> map) => Settings(
    optionNumber: map['optionNumber'] ?? 4,
    myFavorite: map['myFavorite'] ?? true,
    hiddenPictures: map['hiddenPictures'] ?? false,
    privacyPolicy: map['privacyPolicy'] ?? false,
    isDarkTheme: map['isDarkTheme'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'optionNumber': optionNumber,
    'myFavorite': myFavorite,
    'hiddenPictures': hiddenPictures,
    'privacyPolicy': privacyPolicy,
    'isDarkTheme': isDarkTheme,
  };
}
