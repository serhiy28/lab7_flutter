
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // Додайте цей імпорт для XFile
import '../models/movie.dart';

abstract class MoviesRepository {
  Stream<List<Movie>> getMoviesStream(String userId);
  Future<void> addMovie(Movie movie);
  Future<void> updateMovie(Movie movie);
  Future<void> deleteMovie(String movieId);
  Future<String> uploadPoster(XFile file, String userId); // Змінили тип на XFile
}

class FirestoreMoviesRepository implements MoviesRepository {
  final CollectionReference _moviesCollection =
      FirebaseFirestore.instance.collection('movies');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<Movie>> getMoviesStream(String userId) {
    return _moviesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> addMovie(Movie movie) async {
    await _moviesCollection.add(movie.toMap());
  }

  @override
  Future<void> updateMovie(Movie movie) async {
    await _moviesCollection.doc(movie.id).update(movie.toMap());
  }

  @override
  Future<void> deleteMovie(String movieId) async {
    await _moviesCollection.doc(movieId).delete();
  }

  @override
  Future<String> uploadPoster(XFile file, String userId) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('users/$userId/posters/$fileName');

    // УНІВЕРСАЛЬНИЙ СПОСІБ (працює і на Web, і на Mobile):
    // Читаємо файл як набір байтів
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final bytes = await file.readAsBytes(); 
    
    // Завантажуємо байти (putData замість putFile)
    final UploadTask uploadTask = ref.putData(bytes, metadata);
    final TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }
}