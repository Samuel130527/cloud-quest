
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Listen to the shared daily challenge.
  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchTodayChallenge() {
    return _firestore
        .collection('challenges')
        .doc('today')
        .snapshots();
  }

  // Listen to the signed-in learner's private progress.
  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchTodayProgress(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('today')
        .snapshots();
  }
}
