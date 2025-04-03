import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pot_g/app/values/palette.dart';

class PotGToggle extends StatelessWidget {
  const PotGToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final void Function(bool value) onChanged;

  static const _animationDuration = Duration(milliseconds: 100);
  static const _toggleWidth = 60.0;
  static const _toggleHeight = 33.0;
  static const _togglePadding = EdgeInsets.symmetric(horizontal: 4.5);
  static const _knobSize = 25.5;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: _animationDuration,
        width: _toggleWidth,
        height: _toggleHeight,
        decoration: BoxDecoration(
          color: value ? Palette.primary : Palette.grey,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: _togglePadding,
        child: Stack(
          children: [
            AnimatedAlign(
              curve: Curves.easeOutQuad,
              duration: _animationDuration,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knobSize,
                height: _knobSize,
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
