import 'dart:io';
import 'package:flutter/foundation.dart'; // для kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/movie.dart';
import '../providers/movies_provider.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            // --- КНОПКИ РЕДАГУВАННЯ / ВИДАЛЕННЯ ---
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(context, movie);
                  } else if (value == 'delete') {
                    _confirmDelete(context, movie.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit, color: Colors.black), SizedBox(width: 8), Text('Редагувати')]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Видалити', style: TextStyle(color: Colors.red))]),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(movie.title),
              background: Image.network(
                movie.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[800], child: Icon(Icons.movie, size: 100)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(label: Text(movie.genre), backgroundColor: Theme.of(context).primaryColor),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('${movie.rating}/10', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Рік: ${movie.year} | Статус: ${movie.status == 'watched' ? "Переглянуто" : "Заплановано"}', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 16),
                  Text('Нотатки:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(movie.notes ?? 'Опис відсутній.', style: TextStyle(fontSize: 16, height: 1.5)),
                  SizedBox(height: 24),
                  if (movie.userRating != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [Text('Ваша оцінка: '), Text('${movie.userRating}/10', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Логіка видалення
  void _confirmDelete(BuildContext context, String movieId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Видалити фільм?'),
        content: Text('Цю дію неможливо скасувати.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Ні')),
          TextButton(
            onPressed: () async {
              await Provider.of<MoviesProvider>(context, listen: false).deleteMovie(movieId);
              Navigator.pop(ctx); // Закрити діалог
              Navigator.pop(context); // Повернутись назад
            },
            child: Text('Так, видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Логіка редагування
  void _showEditDialog(BuildContext context, Movie movie) {
    final titleController = TextEditingController(text: movie.title);
    final genreController = TextEditingController(text: movie.genre);
    final yearController = TextEditingController(text: movie.year.toString());
    final ratingController = TextEditingController(text: movie.rating.toString());
    final notesController = TextEditingController(text: movie.notes);
    
    String status = movie.status;
    int userRating = movie.userRating ?? 0;
    XFile? _newImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          Future<void> _pickImage() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) setStateDialog(() => _newImage = pickedFile);
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('Редагувати фільм', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Фото (показує старе, якщо нове не обрано)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150, width: 100,
                      decoration: BoxDecoration(color: Colors.black26),
                      child: _newImage != null
                          ? (kIsWeb 
                              ? Image.network(_newImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_newImage!.path), fit: BoxFit.cover))
                          : Image.network(movie.imageAsset, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.error)),
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  _buildTextField(titleController, 'Назва'),
                  _buildTextField(genreController, 'Жанр'),
                  _buildTextField(yearController, 'Рік', isNumber: true),
                  _buildTextField(ratingController, 'Рейтинг', isNumber: true),
                  
                  DropdownButtonFormField<String>(
                    value: status,
                    dropdownColor: const Color(0xFF1E293B),
                    style: TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem(value: 'planned', child: Text('Заплановано')),
                      DropdownMenuItem(value: 'watched', child: Text('Переглянуто'))
                    ],
                    onChanged: (val) => setStateDialog(() => status = val!),
                    decoration: InputDecoration(labelText: 'Статус', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  
                  if (status == 'watched') ...[
                     SizedBox(height: 10),
                     Text('Ваша оцінка: $userRating', style: TextStyle(color: Colors.white)),
                     Slider(
                       value: userRating.toDouble(), min: 0, max: 10, divisions: 10,
                       activeColor: const Color(0xFF7C3AED),
                       onChanged: (v) => setStateDialog(() => userRating = v.toInt())
                     ),
                  ],
                  
                  _buildTextField(notesController, 'Нотатки', maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Скасувати')),
              ElevatedButton(
                onPressed: () async {
                  // Закриваємо діалог
                  Navigator.pop(ctx);
                  
                  // Зберігаємо
                  await Provider.of<MoviesProvider>(context, listen: false).editMovie(
                    id: movie.id,
                    currentImageUrl: movie.imageAsset,
                    title: titleController.text,
                    genre: genreController.text,
                    year: int.tryParse(yearController.text) ?? 2000,
                    rating: double.tryParse(ratingController.text.replaceAll(',', '.')) ?? 0.0,
                    status: status,
                    notes: notesController.text,
                    userRating: userRating > 0 ? userRating : null,
                    newPosterFile: _newImage,
                  );
                  
                  // Закриваємо екран деталей (бо дані змінились)
                  Navigator.pop(context);
                },
                child: Text('Зберегти'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String l, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: 8),
      child: TextField(
        controller: c, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines, style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: l, labelStyle: TextStyle(color: Colors.white70),
          filled: true, fillColor: Colors.black12,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}