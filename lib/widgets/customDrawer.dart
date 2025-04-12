// custom_drawer.dart
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  // --- Dependencies passed from the parent ---

  // Data needed for display
  final List<List<Map<String, dynamic>>> chatHistory;

  // Callbacks for actions
  final Function(int)
  onHistoryItemSelected; // Callback when a history item is tapped
  final VoidCallback onGoToTrending; // Callback for Trending button
  final VoidCallback onGoToFavorite; // Callback for Favorite button
  final VoidCallback onGoToSettings; // Callback for Settings button

  // Constructor to receive dependencies
  const CustomDrawer({
    super.key,
    required this.chatHistory,
    required this.onHistoryItemSelected,
    required this.onGoToTrending,
    required this.onGoToFavorite,
    required this.onGoToSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          const _DrawerHeader(),

          _ChatHistoryList(
            chatHistory: chatHistory,
            onHistoryItemSelected: onHistoryItemSelected,
          ),

          _DrawerActionButtons(
            onGoToTrending: onGoToTrending,
            onGoToFavorite: onGoToFavorite,
            onGoToSettings: onGoToSettings,
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
      ),
      color: Theme.of(context).primaryColor,
      child: Center(
        child: Text(
          'History',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

class _ChatHistoryList extends StatelessWidget {
  final List<List<Map<String, dynamic>>> chatHistory;
  final Function(int) onHistoryItemSelected;

  const _ChatHistoryList({
    required this.chatHistory,
    required this.onHistoryItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: chatHistory.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text("對話 ${index + 1}"),
            onTap: () {
              onHistoryItemSelected(index);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

class _DrawerActionButtons extends StatelessWidget {
  final VoidCallback onGoToTrending;
  final VoidCallback onGoToFavorite;
  final VoidCallback onGoToSettings;

  const _DrawerActionButtons({
    required this.onGoToTrending,
    required this.onGoToFavorite,
    required this.onGoToSettings,
  });

  // Helper to get button text style, kept local to where it's used
  TextStyle _getButtonText(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w200,
      color: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  // Helper to create a consistent button style
  ButtonStyle _getButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withAlpha(75),
      shadowColor: Colors.transparent, // Remove shadow if desired
      minimumSize: const Size(double.infinity, 48), // Make button wider
      alignment: Alignment.centerLeft, // Align content left
      textStyle: _getButtonText(context),
    ).copyWith(
      elevation: ButtonStyleButton.allOrNull(0.0), // Ensure elevation is 0
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context); // Get the style once

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Column takes minimum space
            crossAxisAlignment: CrossAxisAlignment.start, // Align buttons left
            children: [
              ElevatedButton.icon(
                onPressed: onGoToTrending,
                label: const Text('Trending'),
                icon: const Icon(Icons.trending_up, size: 32),
                iconAlignment: IconAlignment.start,
                style: buttonStyle, // Apply shared style
              ),
              const SizedBox(height: 8), // Add spacing
              ElevatedButton.icon(
                onPressed: onGoToFavorite,
                label: const Text('Favorite '),
                icon: const Icon(Icons.favorite, size: 32),
                iconAlignment: IconAlignment.start,
                style: buttonStyle, // Apply shared style
              ),
              const SizedBox(height: 8), // Add spacing
              ElevatedButton.icon(
                onPressed: onGoToSettings,
                label: const Text('Settings '),
                icon: const Icon(Icons.settings, size: 32),
                iconAlignment: IconAlignment.start,
                style: buttonStyle, // Apply shared style
              ),
            ],
          ),
        ),
      ),
    );
  }
}
