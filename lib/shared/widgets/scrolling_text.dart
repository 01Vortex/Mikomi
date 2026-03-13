import 'package:flutter/material.dart';

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final double height;

  const ScrollingText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.height = 16,
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText> {
  final ScrollController _scrollController = ScrollController();
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkIfNeedsScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        setState(() => _needsScroll = true);
        _startAutoScroll();
      }
    }
  }

  void _startAutoScroll() async {
    if (!_needsScroll || !mounted) return;

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || !_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 3),
      curve: Curves.linear,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_scrollController.hasClients) return;

    _scrollController.jumpTo(0);

    if (mounted) {
      _startAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Text(
          widget.text,
          maxLines: widget.maxLines,
          style: widget.style,
        ),
      ),
    );
  }
}
