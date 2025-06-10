import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:software_studio_final/model/settings.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/settings_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(
      context,
      listen: true,
    );
    final Settings settings = settingsNotifier.settings;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            ListTile(
              title: Text('Dark Theme'),
              trailing: Switch(
                value: settings.isDarkTheme,
                onChanged: settingsNotifier.setTheme,
              ),
            ),
            ListTile(
              title: Text('Suggestion Amount (Once)'),
              trailing: SizedBox(
                width: 60,
                child: TextFormField(
                  textAlign: TextAlign.center, // Center the text
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

            // --- NEW FOLDER SELECTION UI ---
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Meme Folders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0, // Horizontal space between chips
                runSpacing: 4.0, // Vertical space between lines of chips
                children: [
                  _buildFolderChip('All', 'all', settingsNotifier),
                  _buildFolderChip('MyGo', 'mygo', settingsNotifier),
                  _buildFolderChip('Spongebob', 'spongebob', settingsNotifier),
                ],
              ),
            ),

            // --- END OF NEW UI ---
          ],
        ),
      ),
    );
  }

  // Helper widget to create a FilterChip, avoiding code repetition.
  Widget _buildFolderChip(
    String label,
    String folderId,
    SettingsNotifier notifier,
  ) {
    final bool isSelected = notifier.settings.enabledFolders.contains(folderId);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        // The boolean value from onSelected is not needed here
        notifier.toggleFolder(folderId);
      },
      // Optional: Style the chip to look better
      selectedColor: Colors.blue.withAlpha(50),
      checkmarkColor: Colors.blue,
      shape: StadiumBorder(
        side: BorderSide(color: isSelected ? Colors.blue : Colors.grey),
      ),
    );
  }
}
