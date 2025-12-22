import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/navigation/app_routes.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/initialization_service.dart';

/// 스플래시/로딩 화면
///
/// 앱 시작 시 초기화 작업을 수행하는 동안 표시되는 화면입니다.
/// 애니메이션 효과와 함께 앱 로고를 표시하고, 초기화 완료 후 피드 화면으로 이동합니다.
///
/// ## 애니메이션 시퀀스
/// 1. **페이드인** (0-500ms): 로고가 투명→불투명으로 페이드인
/// 2. **스케일** (200-700ms): 로고가 0.8→1.0으로 확대
/// 3. **로딩 표시** (700ms~): 로딩 인디케이터 페이드인
/// 4. **완료 후 전환**: /feed로 이동
///
/// ## 초기화 작업
/// - [SettingsService] 로드 (테마, 언어, 사용자 설정)
/// - 건강앱 연결 상태 확인
/// - (향후) iCloud 데이터 동기화
///
/// ## 라우팅
/// - `/splash` - 앱 시작 시 최초 화면
/// - 초기화 완료 후 `/feed`로 이동
///
/// ## 관련 파일
/// - [InitializationService] - 초기화 로직
/// - [SettingsService] - 설정 상태 관리
/// - [AppTheme] - 디자인 상수
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _exitFadeAnimation;

  bool _showLoading = false;
  InitializationStep _currentStep = InitializationStep.settings;

  // static으로 앱 전체에서 한 번만 초기화되도록 보장
  static bool _isAppInitializing = false;
  // 현재 활성화된 인스턴스의 상태 업데이트 콜백
  static void Function(InitializationStep)? _activeStepCallback;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // context를 사용하려면 initState 이후에 호출해야 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialization();
    });
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    // 아이콘 먼저 즉시 표시
    _controller.forward();

    // 로딩 인디케이터는 아이콘 애니메이션 완료 후 표시
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }
    });
  }

  void _updateStep(InitializationStep step) {
    if (mounted) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  Future<void> _startInitialization() async {
    // 이 인스턴스를 활성 콜백으로 등록 (항상 최신 인스턴스가 UI 업데이트 받음)
    _activeStepCallback = _updateStep;

    // 이미 초기화 중이면 콜백만 등록하고 리턴
    if (_isAppInitializing) return;
    _isAppInitializing = true;

    final settingsService = context.read<SettingsService>();
    final initService = InitializationService(
      settingsService: settingsService,
      onStepChanged: (step) {
        // static 콜백을 통해 현재 활성 인스턴스에 상태 전달
        _activeStepCallback?.call(step);
      },
    );

    try {
      await initService.initialize();
      debugPrint('[SplashScreen] Initialization complete');
    } catch (e) {
      debugPrint('[SplashScreen] Initialization error: $e');
    }

    if (mounted) {
      _navigateToHome();
    }
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;

    // 페이드아웃 애니메이션 실행 (TickerMode가 비활성화된 경우 타임아웃 처리)
    try {
      await _exitController.forward().orCancel.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
    } catch (_) {}

    if (mounted) {
      AppRoutes.goToMain(context);
    }
  }

  String _getStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case InitializationStep.settings:
        return l10n.initLoadingSettings;
      case InitializationStep.healthSync:
        return l10n.initCheckingHealth;
      case InitializationStep.iCloudSync:
        return l10n.initCheckingiCloud;
      case InitializationStep.localDatabase:
        return l10n.initLocalDatabase;
      case InitializationStep.done:
        return l10n.initDone;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.iosBackground(context),
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _exitController]),
        builder: (context, child) {
          final exitOpacity =
              _exitController.isAnimating || _exitController.isCompleted
              ? _exitFadeAnimation.value
              : 1.0;
          return Opacity(
            opacity: _fadeAnimation.value * exitOpacity,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 로고 이미지
                    Image.asset(
                      'assets/images/main_logo-removebg.png',
                      width: 240,
                      height: 240,
                    ),
                    const SizedBox(height: 16),
                    // 앱 슬로건
                    Text(
                      AppLocalizations.of(context)!.appSlogan,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary(context).withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // 로딩 인디케이터
                    AnimatedOpacity(
                      opacity: _showLoading ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const CupertinoActivityIndicator(radius: 14),
                    ),
                    const SizedBox(height: 16),
                    // 초기화 상태 텍스트
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _getStatusText(context),
                        key: ValueKey(_currentStep),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textPrimary(context).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
