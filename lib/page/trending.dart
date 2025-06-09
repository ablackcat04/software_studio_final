import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your own project imports. Make sure the paths are correct.
import 'package:software_studio_final/widgets/favorite_button.dart';

// -------------------------------------------------------------------
// DATA MODEL: Represents a single meme document from Firestore
// -------------------------------------------------------------------
class MemeTemplate {
  final String id;
  final String path;
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

  /// Fetches memes and sorts them by 'used_times' in descending order.
  Stream<List<MemeTemplate>> getTrendingMemesStream() {
    return _db
        .collection('trending')
        .orderBy('used_times', descending: true)
        .snapshots() // Use snapshots() instead of get()
        .map((snapshot) {
          // Map the QuerySnapshot to a List<MemeTemplate>
          return snapshot.docs
              .map((doc) => MemeTemplate.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> addOrIncrementMeme({
    required String memeId,
    required String path,
  }) async {
    final String cleanMemeId = memeId.split('/').last.split('.').first;

    final memeRef = _db
        .collection('trending')
        .doc(cleanMemeId); // Use the clean ID

    try {
      await _db.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(memeRef);
        if (docSnapshot.exists) {
          transaction.update(memeRef, {'used_times': FieldValue.increment(1)});
        } else {
          // Use the original 'path' for the data, but the 'cleanMemeId' for the document.
          transaction.set(memeRef, {'path': path, 'used_times': 1});
        }
      });
    } catch (e) {
      debugPrint('Error in addOrIncrementMeme transaction: $e');
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
  // We no longer need a late Future variable.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trending')),
      // --- REPLACE FutureBuilder WITH StreamBuilder ---
      body: StreamBuilder<List<MemeTemplate>>(
        // Listen to the new stream method
        stream: _firestoreService.getTrendingMemesStream(),
        builder: (context, snapshot) {
          // 1. If an error occurred in the stream
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }

          // 2. While waiting for the first data from the stream, show a spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. If the stream is empty or has no data, show a message
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No trending memes found.'));
          }

          // 4. If data is successfully received, build the grid
          // This builder will now re-run AUTOMATICALLY whenever data changes!
          final memes = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.8,
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
      clipBehavior: Clip.antiAlias,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.asset(
              meme.path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                FavoriteButton(
                  id: meme.id,
                  imageUrl: meme.path,
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
