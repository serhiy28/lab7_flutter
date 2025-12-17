import 'dart:io';
import 'package:flutter/foundation.dart'; // для kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/movies_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/filter_chips.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedFilter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MoviesProvider>(context, listen: false).init();
    });
  }

  Future<void> _loadSavedFilter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedStatus = prefs.getString('movie_filter_status') ?? 'all';
    });
  }

  void _onFilterChanged(String status) async {
    setState(() => _selectedStatus = status);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('movie_filter_status', status);
  }

  // --- ДІАЛОГ ДОДАВАННЯ ---
  void _showAddMovieDialog(BuildContext context) {
    final titleController = TextEditingController();
    final genreController = TextEditingController();
    final yearController = TextEditingController();
    final ratingController = TextEditingController(); // Рейтинг фільму
    final notesController = TextEditingController();
    
    String status = 'planned';
    int userRating = 0;
    XFile? _selectedImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          Future<void> _pickImage() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setStateDialog(() => _selectedImage = pickedFile);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('Додати фільм', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Фото
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150, width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24)
                      ),
                      child: _selectedImage != null
                          ? (kIsWeb 
                              ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.white54),
                                SizedBox(height: 8),
                                Text('Фото', style: TextStyle(color: Colors.white54, fontSize: 10))
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Поля
                  _buildTextField(titleController, 'Назва'),
                  _buildTextField(genreController, 'Жанр'),
                  _buildTextField(yearController, 'Рік', isNumber: true),
                  _buildTextField(ratingController, 'Рейтинг IMDb (напр. 8.5)', isNumber: true),
                  
                  SizedBox(height: 10),
                  // Статус
                  DropdownButtonFormField<String>(
                    value: status,
                    dropdownColor: const Color(0xFF1E293B),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Статус', labelStyle: TextStyle(color: Colors.white70),
                      filled: true, fillColor: const Color(0xFF0F172A),
                    ),
                    items: [
                      DropdownMenuItem(value: 'planned', child: Text('Заплановано')),
                      DropdownMenuItem(value: 'watched', child: Text('Переглянуто')),
                    ],
                    onChanged: (val) => setStateDialog(() => status = val!),
                  ),

                  // Оцінка користувача (тільки якщо переглянуто)
                  if (status == 'watched') ...[
                    SizedBox(height: 16),
                    Text('Ваша оцінка: ${userRating == 0 ? "-" : userRating}/10', style: TextStyle(color: Colors.white)),
                    Slider(
                      value: userRating.toDouble(),
                      min: 0, max: 10, divisions: 10,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: (val) => setStateDialog(() => userRating = val.toInt()),
                    ),
                  ],

                  SizedBox(height: 10),
                  _buildTextField(notesController, 'Нотатки', maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Скасувати')),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  Navigator.of(ctx).pop();

                  try {
                    await Provider.of<MoviesProvider>(context, listen: false).addMovieWithPoster(
                      title: titleController.text,
                      genre: genreController.text,
                      year: int.tryParse(yearController.text) ?? 2025,
                      rating: double.tryParse(ratingController.text.replaceAll(',', '.')) ?? 0.0,
                      status: status,
                      notes: notesController.text,
                      userRating: userRating > 0 ? userRating : null,
                      posterFile: _selectedImage,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Фільм додано!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Text('Додати'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final moviesProvider = Provider.of<MoviesProvider>(context);
    
    final filteredMovies = moviesProvider.getFilteredMovies(
      status: _selectedStatus,
      searchQuery: _searchQuery,
    );

    Widget content;
    if (moviesProvider.isLoading && moviesProvider.allMovies.isEmpty) {
      content = Center(child: CircularProgressIndicator(color: const Color(0xFF7C3AED)));
    } else if (moviesProvider.error != null) {
      content = Center(child: Text('Помилка: ${moviesProvider.error}', style: TextStyle(color: Colors.white)));
    } else if (filteredMovies.isEmpty) {
      content = Center(child: Text('Фільми не знайдено', style: TextStyle(color: Colors.white54)));
    } else {
      content = GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredMovies.length,
        itemBuilder: (context, index) => MovieCard(movie: filteredMovies[index]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Моя Колекція'),
        backgroundColor: const Color(0xFF0f0e17),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFF0f0e17), const Color(0xFF1a1a2e)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Пошук...',
                  prefixIcon: Icon(Icons.search, color: const Color(0xFF7C3AED)),
                  filled: true, fillColor: const Color(0xFF1a1a2e),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            FilterChips(
              selectedStatus: _selectedStatus,
              onStatusChanged: _onFilterChanged,
            ),
            Expanded(child: content),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C3AED),
        onPressed: () => _showAddMovieDialog(context),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}