// lib/widgets/add_movie_button.dart
import 'package:flutter/material.dart';
// import '../utils/theme.dart';

class AddMovieButton extends StatelessWidget {
  const AddMovieButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
      
        },
        icon: const Icon(Icons.add),
        label: const Text('Додати фільм'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}