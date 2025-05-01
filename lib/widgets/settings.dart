import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:software_studio_final/models/settings.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/settings_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(
      context,
      listen: false,
    );
    final Settings settings = settingsNotifier.settings;

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
              title: Text('My Favorite'),
              trailing: Switch(
                value: settings.myFavorite,
                onChanged: (bool value) {},
              ),
            ),
            ListTile(
              title: Text('Hidden Pictures'),
              trailing: Switch(
                value: settings.hiddenPictures,
                onChanged: (bool value) {},
              ),
            ),
            ListTile(
              title: Text('Privacy Mode'),
              trailing: Switch(
                value: settings.privacyPolicy,
                onChanged: (bool value) {},
              ),
            ),
            ListTile(
              title: Text('Dark Theme'),
              trailing: Switch(
                value: settings.isDarkTheme,
                onChanged: settingsNotifier.setTheme,
              ),
            ),
            ListTile(
              title: Text('Suggestion Amount(Once)'),
              trailing: SizedBox(
                width: 60,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: settings.optionNumber.toString(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                  ),
                  onChanged: (String value) {
                    final int? newValue = int.tryParse(value);
                    if (newValue != null) {
                      settingsNotifier.setOptionNumber(newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
