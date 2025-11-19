import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';

void main() {
  runApp(const ImmersiveImageApp());
}

class ImmersiveImageApp extends StatelessWidget {
  const ImmersiveImageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immersive Random Image',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const ImageScreen(),
    );
  }
}

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  Color _backgroundColor = const Color(0xFF212121);
  Color _textColor = Colors.white;
  
  String? _imageUrl;
  String? _previousImageUrl; // Cache previous URL
  bool _isLoading = false;
  String? _errorMessage;
  
  // Cache untuk palette agar tidak perlu generate ulang
  final Map<String, Color> _paletteCache = {};
  bool _isPaletteGenerating = false;

  @override
  void initState() {
    super.initState();
    _fetchNewImage();
  }

  /// Fetch image URL from the API dengan timeout yang lebih pendek
  Future<void> _fetchNewImage() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previousImageUrl = _imageUrl; // Keep previous image visible
    });

    try {
      final uri = Uri.parse('https://november7-730026606190.europe-west1.run.app/image');
      
      // Tambahkan timeout untuk menghindari waiting terlalu lama
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newUrl = data['url'];
        
        setState(() {
          _imageUrl = newUrl;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error loading image. Please try again.";
      });
      debugPrint("Error fetching image: $e");
    }
  }

  /// Extract dominant color dengan optimasi
  Future<void> _updatePalette(ImageProvider imageProvider) async {
    // Cek apakah sudah ada di cache
    final cacheKey = _imageUrl ?? '';
    if (_paletteCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _backgroundColor = _paletteCache[cacheKey]!;
          _textColor = _calculateTextColor(_backgroundColor);
        });
      }
      return;
    }

    // Prevent multiple palette generations
    if (_isPaletteGenerating) return;
    _isPaletteGenerating = true;

    try {
      // Kurangi maximumColorCount untuk performa lebih cepat
      final generator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 15, // Dikurangi dari 20 ke 10
        timeout: const Duration(seconds: 5), // Tambahkan timeout
      );
      
      if (mounted && _imageUrl == cacheKey) {
        final newColor = generator.mutedColor?.color ?? 
                         generator.dominantColor?.color ?? 
                         Colors.grey.shade900;
        
        // Simpan ke cache
        _paletteCache[cacheKey] = newColor;
        
        setState(() {
          _backgroundColor = newColor;
          _textColor = _calculateTextColor(newColor);
        });
      }
    } catch (e) {
      debugPrint("Error generating palette: $e");
    } finally {
      _isPaletteGenerating = false;
    }
  }

  Color _calculateTextColor(Color bg) {
    return ThemeData.estimateBrightnessForColor(bg) == Brightness.dark 
        ? Colors.white 
        : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600), // Dikurangi dari 800ms
        curve: Curves.easeInOut,
        color: _backgroundColor,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildImageArea(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _textColor, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _fetchNewImage,
              child: Text('Retry', style: TextStyle(color: _textColor)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _imageUrl == null
              ? Center(
                  child: CircularProgressIndicator(color: _textColor),
                )
              : CachedNetworkImage(
                  key: ValueKey(_imageUrl), // Force rebuild on URL change
                  imageUrl: _imageUrl!,
                  fit: BoxFit.cover,
                  
                  // Optimasi: gunakan memCacheWidth untuk resize otomatis
                  // memCacheWidth: 800, // Resize to max 800px width
                  // memCacheHeight: 800, // Resize to max 800px height
                  
                  imageBuilder: (context, imageProvider) {
                    // Update palette secara asynchronous
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _updatePalette(imageProvider);
                    });
                    return Image(image: imageProvider, fit: BoxFit.cover);
                  },
                  
                  placeholder: (context, url) => Stack(
                    children: [
                      // Show previous image if available
                      if (_previousImageUrl != null && _previousImageUrl != url)
                        CachedNetworkImage(
                          imageUrl: _previousImageUrl!,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                        ),
                      Center(
                        child: CircularProgressIndicator(
                          color: _textColor,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                  
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  fadeInDuration: const Duration(milliseconds: 300), // Lebih cepat
                  fadeOutDuration: const Duration(milliseconds: 200),
                ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _fetchNewImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: _textColor.withOpacity(0.9),
          foregroundColor: _backgroundColor,
          elevation: 5,
          disabledBackgroundColor: _textColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _backgroundColor,
                ),
              )
            : const Text(
                "Another",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _paletteCache.clear();
    super.dispose();
  }
}