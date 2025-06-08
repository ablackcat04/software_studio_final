import 'package:cloud_firestore/cloud_firestore.dart';

class MemeTemplate {
  final String id; // The document ID
  final String path;
  final int used_times;

  MemeTemplate({
    required this.id,
    required this.path,
    required this.used_times,
  });

  // A factory constructor to create a MemeTemplate from a Firestore document
  factory MemeTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemeTemplate(
      id: doc.id,
      path: data['path'] ?? '',
      used_times: data['used_times'] ?? 0,
    );
  }
}
