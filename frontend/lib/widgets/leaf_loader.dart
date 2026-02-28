import 'package:flutter/material.dart';

class LeafLoader extends StatefulWidget {
  final Color color;
  const LeafLoader({super.key, this.color = const Color(0xFF1F3D2B)});

  @override
  State<LeafLoader> createState() => _LeafLoaderState();
}

class _LeafLoaderState extends State<LeafLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: -8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _offset.value),
            child: Icon(Icons.eco_rounded, size: 36, color: widget.color),
          ),
        );
      },
    );
  }
}
