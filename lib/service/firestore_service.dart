import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_studio_final/meme_template.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get a list of memes, sorted by 'used_times' in descending order
  Future<List<MemeTemplate>> getTrendingMemes() async {
    try {
      QuerySnapshot querySnapshot =
          await _db
              .collection('trending')
              .orderBy(
                'used_times',
                descending: true,
              ) // This is the key for "trending"
              .get();

      print(querySnapshot.toString());

      // Map the documents to our MemeTemplate model
      return querySnapshot.docs
          .map((doc) => MemeTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching trending memes: $e');
      return []; // Return an empty list on error
    }
  }
}
