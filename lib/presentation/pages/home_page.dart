import 'package:flutter/material.dart';

// Example home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitFolio'),
      ),
      body: const Center(
        child: Text(
          'Welcome to GitFolio',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
