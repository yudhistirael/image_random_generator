import 'dart:typed_data';

import 'package:flutter/material.dart';

Color calculateDominantColor(Uint8List pixels) {
    final Map<int, int> colorCounts = {};
    int maxCount = 0;
    int dominantColorInt = 0xFF212121; 

   
    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final a = pixels[i + 3];

      if (a < 128) continue; 
      
     
      final quantizedR = (r ~/ 10) * 10;
      final quantizedG = (g ~/ 10) * 10;
      final quantizedB = (b ~/ 10) * 10;

      final colorInt = (0xFF << 24) | (quantizedR << 16) | (quantizedG << 8) | quantizedB;
      final currentCount = (colorCounts[colorInt] ?? 0) + 1;
      colorCounts[colorInt] = currentCount;

      if (currentCount > maxCount) {
        maxCount = currentCount;
        dominantColorInt = colorInt;
      }
    }

   
    final hsl = HSLColor.fromColor(Color(dominantColorInt));
    final double newLightness = (hsl.lightness - 0.1).clamp(0.1, 0.9);
    return hsl.withLightness(newLightness).toColor();
  }



int extractColorFromBytes(Uint8List pixels) {
  final Map<int, int> colorCounts = {};
  int maxCount = 0;

  int dominantColorInt = 0xFF212121; 

  for (int i = 0; i < pixels.length; i += 4) {
    final r = pixels[i];
    final g = pixels[i + 1];
    final b = pixels[i + 2];
    final a = pixels[i + 3];

    if (a < 128) continue; 

    final quantizedR = (r ~/ 10) * 10;
    final quantizedG = (g ~/ 10) * 10;
    final quantizedB = (b ~/ 10) * 10;

    final colorInt = (0xFF << 24) | (quantizedR << 16) | (quantizedG << 8) | quantizedB;
    
    final currentCount = (colorCounts[colorInt] ?? 0) + 1;
    colorCounts[colorInt] = currentCount;

    if (currentCount > maxCount) {
      maxCount = currentCount;
      dominantColorInt = colorInt;
    }
  }

  return dominantColorInt;
}
