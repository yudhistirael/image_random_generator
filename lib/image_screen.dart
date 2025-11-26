import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_random_generator/color_utils.dart';

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
  String? _previousImageUrl;
  bool _isLoading = false;
  bool _isImageLoading = false;
  
  // Cache sederhana untuk warna agar jika gambar sama tidak hitung ulang
  final Map<String, Color> _colorCache = {};

  

  @override
  void initState() {
    super.initState();
    _fetchNewImage();
  }


  Future<void> _fetchNewImage() async {
    if (_isLoading) return; 
    
    setState(() {
      _isLoading = true;
      _isImageLoading = true;
      _previousImageUrl = _imageUrl; 
    });

    try {
      final uri = Uri.parse('https://november7-730026606190.europe-west1.run.app/image');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String url = data['url'];
    
        if (mounted) {
          setState(() {
            _imageUrl = url;
            _isLoading = false;
          });
        }
      } else {
       
        _handleRetry();
      }
    } catch (e) {
      debugPrint("API Error: $e");
      _handleRetry();
    }
  }

  
  void _handleRetry() {
    if (!mounted) return;
   
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
         setState(() => _isLoading = false); 
         _fetchNewImage();
      }
    });
  }

 
  Future<void> _updatePaletteFast(ImageProvider imageProvider, String url) async {
    if (_colorCache.containsKey(url)) {
      _animateToColor(_colorCache[url]!);
      return;
    }

    try {
     
      final ImageProvider resizedProvider = ResizeImage(
        imageProvider,
        width: 50,
        height: 50,
        policy: ResizeImagePolicy.exact,
      );

      // Resolve image stream
      final ImageStream stream = resizedProvider.resolve(ImageConfiguration.empty);
      final completer = Completer<ui.Image>();
      late ImageStreamListener listener;
      
      listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      }, onError: (dynamic exception, StackTrace? stackTrace) {
        stream.removeListener(listener);
      });
      
      stream.addListener(listener);
      
      final ui.Image image = await completer.future;
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      
      if (byteData == null) return;
      
     
      final int dominantColorInt = await compute(extractColorFromBytes, byteData.buffer.asUint8List());
      final Color rawColor = Color(dominantColorInt);

      final hsl = HSLColor.fromColor(rawColor);
      final double newLightness = (hsl.lightness - 0.1).clamp(0.1, 0.9);
      final Color finalColor = hsl.withLightness(newLightness).toColor();
      
      // Simpan ke cache & update UI
      _colorCache[url] = finalColor;
      _animateToColor(finalColor);

    } catch (e) {
      debugPrint("Color extraction failed: $e");
    }
  }

  void _animateToColor(Color color) {
    if (!mounted) return;
    setState(() {
      _backgroundColor = color;
      _textColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark 
          ? Colors.white 
          : Colors.black;
      _isImageLoading = false; 
    });
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500), 
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
              ? Center(child: CircularProgressIndicator(color: _textColor))
              : CachedNetworkImage(
                  key: ValueKey(_imageUrl),
                  imageUrl: _imageUrl!,
                  fit: BoxFit.cover,
                  
                 
                  memCacheWidth: 800, 
                  memCacheHeight: 800,
                  
                  imageBuilder: (context, imageProvider) {
                   
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _updatePaletteFast(imageProvider, _imageUrl!);
                    });
                    return Image(image: imageProvider, fit: BoxFit.cover);
                  },
                  
                  placeholder: (context, url) => Stack(
                    children: [
                      
                      if (_previousImageUrl != null && _previousImageUrl != url)
                        Semantics(
                          label: "Random image from Unsplash",
                          image: true,
                          child: CachedNetworkImage(
                            imageUrl: _previousImageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            memCacheHeight: 800,
                          ),
                        ),
                      Center(
                        child: CircularProgressIndicator(
                          color: _textColor,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                  

                  errorWidget: (context, url, error) {
                   
                    debugPrint("Image Load Error: $error. Retrying...");
                    
                   
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       _handleRetry(); 
                    });

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: _textColor.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text("Retrying...", style: TextStyle(color: _textColor.withOpacity(0.5), fontSize: 12))
                        ],
                      ),
                    );
                  },
                  fadeInDuration: const Duration(milliseconds: 300),
                ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final isButtonLoading = _isLoading || _isImageLoading;
    
    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton(
        onPressed: isButtonLoading ? null : _fetchNewImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: _textColor.withOpacity(0.9),
          foregroundColor: _backgroundColor,
          elevation: 5,
          disabledBackgroundColor: _textColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isButtonLoading
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
}