import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  final String id;
  final String userId; // Прив'язка до користувача
  final String title;
  final String imageAsset; // Тепер це буде URL посилання на Storage
  final int year;
  final String genre;
  final double rating;
  final String status; // 'watched' або 'planned'
  final String? notes;
  final int? userRating;

  Movie({
    required this.id,
    required this.userId,
    required this.title,
    required this.imageAsset,
    required this.year,
    required this.genre,
    required this.rating,
    required this.status,
    this.notes,
    this.userRating,
  });

  // Створення об'єкта з документу Firestore
  factory Movie.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Movie(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      imageAsset: data['imageAsset'] ?? '',
      year: data['year'] ?? 0,
      genre: data['genre'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      status: data['status'] ?? 'planned',
      notes: data['notes'],
      userRating: data['userRating'],
    );
  }

  // Перетворення в Map для запису в Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'imageAsset': imageAsset,
      'year': year,
      'genre': genre,
      'rating': rating,
      'status': status,
      'notes': notes,
      'userRating': userRating,
    };
  }

  Movie copyWith({
    String? id,
    String? userId,
    String? title,
    String? imageAsset,
    int? year,
    String? genre,
    double? rating,
    String? status,
    String? notes,
    int? userRating,
  }) {
    return Movie(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      imageAsset: imageAsset ?? this.imageAsset,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      userRating: userRating ?? this.userRating,
    );
  }
}