import 'package:flutter/material.dart';

class ViolationsScreen extends StatelessWidget {
  const ViolationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Violations')),
      body: const Center(child: Text('No violations found. Drive safely!')),
    );
  }
}
