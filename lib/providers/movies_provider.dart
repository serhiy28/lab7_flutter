import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Для XFile
import '../models/movie.dart';
import '../repositories/movies_repository.dart';

class MoviesProvider extends ChangeNotifier {
  final MoviesRepository _repository = FirestoreMoviesRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Movie> _movies = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _moviesSubscription;

  // Геттери
  List<Movie> get allMovies => _movies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Movie> get watchedMovies =>
      _movies.where((m) => m.status == 'watched').toList();

  List<Movie> get plannedMovies =>
      _movies.where((m) => m.status == 'planned').toList();

  // Ініціалізація
  void init() {
    final user = _auth.currentUser;
    if (user == null) {
      _movies = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _moviesSubscription?.cancel();
    _moviesSubscription = _repository.getMoviesStream(user.uid).listen(
      (movies) {
        _movies = movies;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // --- ДОДАВАННЯ ФІЛЬМУ (Всі поля) ---
  Future<void> addMovieWithPoster({
    required String title,
    required String genre,
    required int year,
    required double rating,      
    required String status,      
    String? notes,               
    int? userRating,             
    XFile? posterFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      String imageUrl = '';
      
      // Якщо обрано файл - вантажимо, якщо ні - ставимо заглушку
      if (posterFile != null) {
        imageUrl = await _repository.uploadPoster(posterFile, user.uid);
      } else {
        imageUrl = 'https://placehold.co/300x450/png?text=No+Poster';
      }

      final newMovie = Movie(
        id: '', // Генерується автоматично
        userId: user.uid,
        title: title,
        imageAsset: imageUrl,
        year: year,
        genre: genre,
        rating: rating,
        status: status,
        notes: notes,
        userRating: userRating,
      );

      await _repository.addMovie(newMovie);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
       // Скидаємо лоадер (хоча стрім оновиться сам)
       if (_error != null) {
          _isLoading = false;
          notifyListeners();
       }
    }
  }

  // --- РЕДАГУВАННЯ ФІЛЬМУ ---
  Future<void> editMovie({
    required String id,
    required String currentImageUrl, // Поточне посилання на фото
    required String title,
    required String genre,
    required int year,
    required double rating,
    required String status,
    String? notes,
    int? userRating,
    XFile? newPosterFile, // Новий файл (може бути null)
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      String finalImageUrl = currentImageUrl;

      // Якщо користувач обрав нове фото, вантажимо його і отримуємо нове URL
      if (newPosterFile != null) {
        finalImageUrl = await _repository.uploadPoster(newPosterFile, user.uid);
      }

      final updatedMovie = Movie(
        id: id,
        userId: user.uid,
        title: title,
        imageAsset: finalImageUrl,
        year: year,
        genre: genre,
        rating: rating,
        status: status,
        notes: notes,
        userRating: userRating,
      );

      await _repository.updateMovie(updatedMovie);

    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      if (_error != null) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // --- ВИДАЛЕННЯ ---
  Future<void> deleteMovie(String movieId) async {
    await _repository.deleteMovie(movieId);
  }
  
  // --- ІНШЕ ---
  Future<void> toggleStatus(Movie movie) async {
    final newStatus = movie.status == 'watched' ? 'planned' : 'watched';
    await _repository.updateMovie(movie.copyWith(status: newStatus));
  }

  List<Movie> getFilteredMovies({String? status, String? searchQuery}) {
    var filtered = _movies;
    if (status != null && status != 'all') {
      filtered = filtered.where((m) => m.status == status).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            m.genre.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  @override
  void dispose() {
    _moviesSubscription?.cancel();
    super.dispose();
  }
}