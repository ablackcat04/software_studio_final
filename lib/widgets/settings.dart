import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:software_studio_final/models/settings.dart';

class SettingsPage extends StatefulWidget {
  final Settings initSettings;
  final Function(Settings settings) onChanged;

  const SettingsPage({
    super.key,
    required this.initSettings,
    required this.onChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Settings settings;

  @override
  void initState() {
    super.initState();
    settings = widget.initSettings;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 點擊 TextField 以外的地方時關閉鍵盤
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: ListView(
          children: [
            ListTile(
              title: Text('Option Numbers'),
              trailing: SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  ),
                  onChanged: (String value) {
                    final int? newValue = int.tryParse(value);
                    if (newValue != null) {
                      Settings newSettings = settings.copyWith(
                        optionNumbers: newValue,
                      );
                      setState(() {
                        settings = newSettings;
                      });
                    }
                  },
                ),
              ),
            ),
            ListTile(
              title: Text('My Favorite'),
              trailing: Switch(
                value: settings.myFavorite,
                onChanged: (bool value) {
                  Settings newSettings = settings.copyWith(myFavorite: value);
                  setState(() {
                    settings = newSettings;
                  });
                  widget.onChanged(newSettings);
                },
              ),
            ),
            ListTile(
              title: Text('Hidden Pictures'),
              trailing: Switch(
                value: settings.hiddenPictures,
                onChanged: (bool value) {
                  Settings newSettings = settings.copyWith(hiddenPictures: value);
                  setState(() {
                    settings = newSettings;
                  });
                  widget.onChanged(newSettings);
                },
              ),
            ),
            ListTile(
              title: Text('Privacy Policy'),
              trailing: Switch(
                value: settings.privacyPolicy,
                onChanged: (bool value) {
                  Settings newSettings = settings.copyWith(privacyPolicy: value);
                  setState(() {
                    settings = newSettings;
                  });
                  widget.onChanged(newSettings);
                },
              ),
            ),
            ListTile(
              title: Text('Theme'),
              trailing: Switch(
                value: settings.isDarkTheme,
                onChanged: (bool value) {
                  Settings newSettings = settings.copyWith(isDarkTheme: value);
                  setState(() {
                    settings = newSettings;
                  });
                  widget.onChanged(newSettings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
