import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// This import is from your original code. Make sure this file exists.
import 'package:software_studio_final/widgets/favorite_button.dart';

// -------------------------------------------------------------------
// DATA MODEL: Represents a single meme document from Firestore
// -------------------------------------------------------------------
class MemeTemplate {
  final String id; // The document ID (e.g., "99")
  final String path; // The asset path (e.g., "assets/images/basic/99.jpg")
  final int usedTimes;

  MemeTemplate({required this.id, required this.path, required this.usedTimes});

  // Factory constructor to create an instance from a Firestore document
  factory MemeTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemeTemplate(
      id: doc.id,
      path: data['path'] ?? '', // Default to empty string if null
      usedTimes: data['used_times'] ?? 0, // Default to 0 if null
    );
  }
}

// -------------------------------------------------------------------
// SERVICE CLASS: Handles all communication with Firestore
// -------------------------------------------------------------------
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetches memes and sorts them by 'used_times' in descending order
  Future<List<MemeTemplate>> getTrendingMemes() async {
    try {
      QuerySnapshot querySnapshot =
          await _db
              .collection('trending')
              .orderBy('used_times', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => MemeTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      // It's good practice to log errors for debugging
      debugPrint('Error fetching trending memes: $e');
      return []; // Return an empty list on error to prevent crashing
    }
  }
}

// -------------------------------------------------------------------
// UI: The main Trending Page widget
// -------------------------------------------------------------------
class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<MemeTemplate>> _trendingMemesFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching the data as soon as the page is loaded
    _trendingMemesFuture = _firestoreService.getTrendingMemes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trending')),
      body: FutureBuilder<List<MemeTemplate>>(
        future: _trendingMemesFuture,
        builder: (context, snapshot) {
          // --- Handle different states of the Future ---

          // 1. While data is loading, show a spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. If an error occurred, show an error message
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }

          // 3. If data is empty or null, show a message
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No trending memes found.'));
          }

          // 4. If data is successfully loaded, build the grid
          final memes = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two items per row
              crossAxisSpacing: 12.0, // Horizontal spacing
              mainAxisSpacing: 12.0, // Vertical spacing
              childAspectRatio:
                  0.8, // Adjust ratio for card appearance (width / height)
            ),
            itemCount: memes.length,
            itemBuilder: (context, index) {
              final meme = memes[index];
              return TrendingMemeCard(meme: meme);
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------
// UI WIDGET: A single card for displaying a meme in the grid
// -------------------------------------------------------------------
class TrendingMemeCard extends StatelessWidget {
  const TrendingMemeCard({super.key, required this.meme});
  final MemeTemplate meme;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior:
          Clip.antiAlias, // Ensures the image respects the card's rounded corners
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image part of the card
          Expanded(
            child: Image.asset(
              meme.path,
              fit: BoxFit.cover,
              // Shows an icon if the image asset fails to load
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          // Bottom info bar of the card
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Usage count display
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meme.usedTimes.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // Your existing FavoriteButton
                FavoriteButton(
                  id: meme.id,
                  // The FavoriteButton needs an identifier for the image.
                  // We pass the asset path. You may need to adjust this depending
                  // on how your FavoriteButton is implemented.
                  imageUrl: meme.path,
                  // We can create a title from the meme data.
                  title: 'Meme #${meme.id}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
