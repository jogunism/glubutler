import 'package:flutter/material.dart';

/// 설정 화면용 아이콘 위젯
///
/// ScreenFab과 동일한 스타일 - 단색 배경 + 그림자
class GlassIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const GlassIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}
