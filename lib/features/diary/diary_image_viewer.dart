import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import 'package:glu_butler/models/diary_file.dart';

/// 일기 이미지 전체화면 뷰어
///
/// 이미지를 전체화면으로 보여주며 확대/축소/이동 기능을 제공합니다.
/// 여러 이미지가 있을 경우 좌우 스와이프 또는 화살표로 넘겨볼 수 있습니다.
class DiaryImageViewer extends StatefulWidget {
  final List<DiaryFile> files;
  final int initialIndex;

  const DiaryImageViewer({
    super.key,
    required this.files,
    this.initialIndex = 0,
  });

  /// 전체화면으로 이미지를 표시합니다
  static void show(
    BuildContext context, {
    required List<DiaryFile> files,
    int initialIndex = 0,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 배경을 투명하게
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85), // 반투명 검은색 배경
        pageBuilder: (context, animation, secondaryAnimation) {
          return DiaryImageViewer(
            files: files,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 페이드 + 스케일 애니메이션
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<DiaryImageViewer> createState() => _DiaryImageViewerState();
}

class _DiaryImageViewerState extends State<DiaryImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // 각 페이지마다 독립적인 TransformationController 생성
    for (int i = 0; i < widget.files.length; i++) {
      _transformationControllers[i] = TransformationController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.files.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.files.length > 1;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // 배경 터치 시 닫기
      child: Scaffold(
        backgroundColor: Colors.transparent, // 투명 배경
        body: GestureDetector(
          onTap: () {}, // 이미지 영역은 닫히지 않도록
          child: Stack(
            children: [
              // 이미지 뷰어
              PageView.builder(
                controller: _pageController,
                itemCount: widget.files.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _ImageZoomView(
                    filePath: widget.files[index].filePath,
                    transformationController: _transformationControllers[index]!,
                  );
                },
              ),

              // 좌우 화살표 (여러 이미지가 있을 때)
              if (hasMultipleImages) ...[
                // 왼쪽 화살표
                if (_currentIndex > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _previousImage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                // 오른쪽 화살표
                if (_currentIndex < widget.files.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _nextImage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.chevron_right,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],

              // 상단 툴바
              SafeArea(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      // 닫기 버튼
                      CupertinoButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      // 페이지 인디케이터 (여러 이미지가 있을 때)
                      if (hasMultipleImages)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.files.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageZoomView extends StatelessWidget {
  final String filePath;
  final TransformationController transformationController;

  const _ImageZoomView({
    required this.filePath,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CupertinoActivityIndicator(
              color: Colors.white,
              radius: 20,
            ),
          );
        }

        final fileExists = snapshot.data ?? false;

        if (!fileExists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '이미지를 불러올 수 없습니다',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return InteractiveViewer(
          transformationController: transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          panEnabled: true,
          scaleEnabled: true,
          child: Center(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이미지를 불러올 수 없습니다',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
