import 'package:flutter/material.dart';
import 'package:mikomi/shared/theme_extensions.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分类')),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 64,
                color: context.colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '分类功能开发中...',
                style: TextStyle(fontSize: 18, color: context.colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
