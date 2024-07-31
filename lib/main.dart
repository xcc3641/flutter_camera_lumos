import 'package:flutter/material.dart';
import 'package:flutter_camera_lumos/camera_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Lumos',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: CameraDemo(),
      ),
    );
  }
}
