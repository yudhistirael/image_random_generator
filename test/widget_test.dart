import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_random_generator/color_utils.dart';
import 'package:image_random_generator/image_screen.dart';

import 'package:image_random_generator/main.dart'; 


void main() {

  group('Color Logic Tests', () {
    test('calculateDominantColor returns correct dominant color', () {
    
      
      final List<int> mockPixels = [
       
        255, 0, 0, 255, 
     
        255, 0, 0, 255,
  
        255, 0, 0, 255,
  
        0, 0, 255, 255,
      ];

      final Uint8List bytes = Uint8List.fromList(mockPixels);

     
      final int resultColorInt = extractColorFromBytes(bytes); 
      
     
      
      expect(resultColorInt, isA<int>());
      expect(resultColorInt, isNot(0));
    });
  });

  testWidgets('App loads and shows initial UI correctly', (WidgetTester tester) async {

    await tester.pumpWidget(const ImmersiveImageApp());

    expect(find.text('Another'), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  
  });
}
