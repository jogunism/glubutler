import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/models/feed_item.dart';

/// Y축 라벨을 그리는 CustomPainter
class YAxisPainter extends CustomPainter {
  final double minY;
  final double maxY;
  final Color textColor;

  YAxisPainter({
    required this.minY,
    required this.maxY,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const candidates = [70, 100, 120, 150, 180, 200, 220, 250, 280, 300, 320];

    // displayMinY ~ displayMaxY 범위에 포함되는 후보 필터링
    final inRange = candidates
        .where((v) => v > minY && v <= maxY)
        .toList();

    // 최대 5개 균등 선택
    final List<int> labels;
    if (inRange.length <= 5) {
      labels = inRange;
    } else {
      labels = List.generate(5, (i) {
        final idx = ((i * (inRange.length - 1)) / 4).round();
        return inRange[idx];
      });
    }

    for (final value in labels) {
      final yPosition = size.height * (1 - (value - minY) / (maxY - minY));

      final textSpan = TextSpan(
        text: value.toString(),
        style: TextStyle(color: textColor, fontSize: 10),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.right,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          size.width - textPainter.width - 5,
          yPosition - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 이벤트 배경과 터치 라인을 그리는 CustomPainter
class EventBackgroundPainter extends CustomPainter {
  final List<FeedItem> events;
  final double chartMinY;
  final double chartMaxY;
  final Color Function(FeedItemType) getEventColor;
  final Color Function(FeedItemType) getEventLabelColor;
  final String Function(FeedItemType) getEventLabel;
  final IconData Function(FeedItemType) getEventIcon;
  final double Function(FeedItem) getEventDuration;
  final Color cardColor;
  final Color textColor;
  final int? touchedBarIndex;
  final Color touchLineColor;
  final int totalBars;
  final double minutesPerBar;

  EventBackgroundPainter({
    required this.events,
    required this.chartMinY,
    required this.chartMaxY,
    required this.getEventColor,
    required this.getEventLabelColor,
    required this.getEventLabel,
    required this.getEventIcon,
    required this.getEventDuration,
    required this.cardColor,
    required this.textColor,
    required this.touchedBarIndex,
    required this.touchLineColor,
    required this.totalBars,
    required this.minutesPerBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / totalBars;

    for (final event in events) {
      if (event.type == FeedItemType.glucose) continue;

      final eventHour = event.timestamp.hour;
      final eventMinute = event.timestamp.minute;
      final eventSecond = event.timestamp.second;

      // 이벤트 지속시간 (시간 단위)
      final duration = getEventDuration(event);

      double eventIndex;
      double durationInBars;
      double halfWidth;

      // 분 단위로 통일된 공식
      eventIndex =
          (eventHour * 60 + eventMinute + eventSecond / 60.0) / minutesPerBar;
      durationInBars = duration * 60.0 / minutesPerBar;
      halfWidth = (durationInBars / 2) * 0.5;

      // 이벤트 범위 계산
      final x1 = (eventIndex - halfWidth).clamp(0.0, totalBars.toDouble());
      final x2 = (eventIndex + halfWidth).clamp(0.0, totalBars.toDouble());

      // 픽셀 좌표로 변환
      final left = x1 * barWidth;
      final right = x2 * barWidth;

      // 차트 전체 높이를 채우는 사각형 그리기 (bottomTitles 영역 제외)
      final rect = Rect.fromLTRB(
        left,
        0,
        right,
        size.height - 24, // bottomTitles reservedSize 제외
      );

      final paint = Paint()
        ..color = getEventColor(event.type).withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, paint);

      // 레이블: 줌 레벨에 따라 아이콘만 or 아이콘+텍스트
      // minutesPerBar >= 40 → 아이콘만, < 40 → 아이콘+텍스트
      final iconData = getEventIcon(event.type);
      final labelColor = getEventColor(event.type);
      final centerX = (left + right) / 2;
      const topY = 4.0;
      const iconSize = 12.0;

      // 아이콘 (Material font glyph)
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: iconData.fontFamily,
            color: labelColor.withValues(alpha: 0.85),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      if (minutesPerBar >= 40) {
        // 아이콘만
        iconPainter.paint(
          canvas,
          Offset(centerX - iconPainter.width / 2, topY),
        );
      } else {
        // 아이콘 + 텍스트 (세로 배치)
        final textPainter = TextPainter(
          text: TextSpan(
            text: getEventLabel(event.type),
            style: TextStyle(
              color: labelColor.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        final startY = topY;
        iconPainter.paint(
          canvas,
          Offset(centerX - iconPainter.width / 2, startY),
        );
        textPainter.paint(
          canvas,
          Offset(
            centerX - textPainter.width / 2,
            startY + iconPainter.height + 2,
          ),
        );
      }
    }

    // 터치된 바의 수직선 그리기
    if (touchedBarIndex != null) {
      final barWidth = size.width / totalBars;
      final x = touchedBarIndex! * barWidth + (barWidth / 2); // 바의 중앙

      final linePaint = Paint()
        ..color = touchLineColor.withValues(alpha: 0.8)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height - 24), // bottomTitles reservedSize 제외
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EventBackgroundPainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.chartMinY != chartMinY ||
        oldDelegate.chartMaxY != chartMaxY ||
        oldDelegate.touchedBarIndex != touchedBarIndex ||
        oldDelegate.totalBars != totalBars ||
        oldDelegate.minutesPerBar != minutesPerBar;
  }
}

/// 비교 기간 평균 혈당을 선으로 그리는 CustomPainter
class ComparisonLinePainter extends CustomPainter {
  final Map<int, double> compAverage;
  final double chartMinY;
  final double chartMaxY;
  final int totalBars;
  final Color color;
  final double? compMin;
  final double? compMax;
  final String unit;
  final double viewportWidth; // 실제 보이는 너비
  final double scrollOffset; // 현재 스크롤 오프셋

  ComparisonLinePainter({
    required this.compAverage,
    required this.chartMinY,
    required this.chartMaxY,
    required this.totalBars,
    required this.color,
    required this.compMin,
    required this.compMax,
    required this.unit,
    required this.viewportWidth,
    required this.scrollOffset,
  });

  double _toY(double value, double chartHeight) {
    final yRange = chartMaxY - chartMinY;
    return chartHeight * (1 - (value - chartMinY) / yRange);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 24; // bottomTitles 영역 제외
    final barSlotWidth = size.width / totalBars;
    // 전체 페인팅을 차트 영역(bottomTitles 제외)으로 클리핑
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, chartHeight));

    // ── 1. 비교 기간 배경 밴드 (슬롯 평균값 기준 ±5 mg/dL, 텍스트는 raw값)
    if (compMin != null && compMax != null) {
      final bandPaint = Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill;
      // 밴드는 슬롯 평균 기준 (선그래프와 동일 범위)
      const bandMgPadding = 12.0;
      final avgVals = compAverage.values;
      final bandBaseMin = avgVals.isNotEmpty ? avgVals.reduce(math.min) : compMin!;
      final bandBaseMax = avgVals.isNotEmpty ? avgVals.reduce(math.max) : compMax!;
      final yTop = _toY(bandBaseMax + bandMgPadding, chartHeight).clamp(0.0, chartHeight);
      final yBottom = _toY(bandBaseMin - bandMgPadding, chartHeight).clamp(0.0, chartHeight);
      canvas.drawRect(Rect.fromLTRB(0, yTop, size.width, yBottom), bandPaint);

      // ── 2. 배경 우측 상단에 최고/최소 수치 텍스트 ─────────────
      final maxText = TextPainter(
        text: TextSpan(
          text: '↑ ${compMax!.toInt()} $unit  ↓ ${compMin!.toInt()} $unit',
          style: TextStyle(
            color: color.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      // 뷰포트 우측 상단에 고정 — 줌/스크롤에 상관없이 항상 표시
      final textX = (scrollOffset + viewportWidth - maxText.width)
          .clamp(0.0, size.width - maxText.width);
      const textY = 4.0; // 차트 상단에 고정
      maxText.paint(canvas, Offset(textX, textY));
    }

    // ── 3. 비교 추이 라인 (갭 구간도 직접 연결) ─────────────────
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final path = Path();
    bool firstPoint = true;

    for (int i = 0; i < totalBars; i++) {
      final value = compAverage[i];
      if (value == null) continue; // 갭은 건너뛰고 다음 점과 직선 연결
      final x = i * barSlotWidth + barSlotWidth / 2;
      final y = _toY(value, chartHeight);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
    canvas.drawPath(path, linePaint);
    canvas.restore(); // 전체 클립 해제
  }

  @override
  bool shouldRepaint(covariant ComparisonLinePainter oldDelegate) {
    return oldDelegate.compAverage != compAverage ||
        oldDelegate.totalBars != totalBars ||
        oldDelegate.chartMinY != chartMinY ||
        oldDelegate.chartMaxY != chartMaxY ||
        oldDelegate.color != color ||
        oldDelegate.compMin != compMin ||
        oldDelegate.compMax != compMax ||
        oldDelegate.unit != unit ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}

class PieChartPainter extends CustomPainter {
  final double veryLowRatio;
  final double lowRatio;
  final double normalRatio;
  final double highRatio;
  final double veryHighRatio;
  final Color holeColor;
  final bool hasData;
  final Color emptyColor;
  final double animationValue;

  PieChartPainter({
    required this.veryLowRatio,
    required this.lowRatio,
    required this.normalRatio,
    required this.highRatio,
    required this.veryHighRatio,
    required this.holeColor,
    required this.hasData,
    required this.emptyColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * 0.6;

    // 데이터가 없으면 회색 원 그리기
    if (!hasData) {
      final greyPaint = Paint()
        ..color = emptyColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, greyPaint);

      // 중앙 구멍 (도넛 차트)
      final holePaint = Paint()
        ..color = holeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, innerRadius, holePaint);
      return;
    }

    double startAngle = -math.pi / 2;

    void drawRoundedArc(double sweepAngle, Color color) {
      if (sweepAngle <= 0) return;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();

      // 바깥쪽 호
      final outerRect = Rect.fromCircle(center: center, radius: radius);
      path.addArc(outerRect, startAngle, sweepAngle);

      // 안쪽 호 (역방향)
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
      path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);
      path.close();

      canvas.drawPath(path, paint);
    }

    // 매우 저혈당
    if (veryLowRatio > 0) {
      final sweepAngle = veryLowRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseVeryLow);
      startAngle += sweepAngle;
    }

    // 저혈당
    if (lowRatio > 0) {
      final sweepAngle = lowRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseLow);
      startAngle += sweepAngle;
    }

    // 정상
    if (normalRatio > 0) {
      final sweepAngle = normalRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseNormal);
      startAngle += sweepAngle;
    }

    // 고혈당
    if (highRatio > 0) {
      final sweepAngle = highRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseHigh);
      startAngle += sweepAngle;
    }

    // 매우 고혈당
    if (veryHighRatio > 0) {
      final sweepAngle = veryHighRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseVeryHigh);
    }

    // 중앙 구멍 (도넛 차트)
    final holePaint = Paint()
      ..color = holeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
