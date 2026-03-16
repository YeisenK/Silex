import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/pin_service.dart';
import '../services/socket_service.dart';
import '../core/crypto_service.dart';
import '../theme/app_theme.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int _attempts = 0;

  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUnlock() async {
    if (_pinController.text.length < 4 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await PinService.unlockWithPin(_pinController.text);

      if (result == null) {
        _attempts++;
        _shakeCtrl.forward(from: 0);
        HapticFeedback.mediumImpact();
        setState(() {
          _isLoading = false;
          _error = _attempts >= 3
              ? 'Incorrect PIN ($_attempts attempts)'
              : 'Incorrect PIN';
          _pinController.clear();
        });
        return;
      }

      await SocketService.connect();
      await CryptoService.ensureIdentityPublic();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Logo ──
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 30,
                        color: AppTheme.accentColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Title ──
                    Text(
                      'SILEX',
                      style: TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: 6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Enter your PIN to unlock',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── PIN input ──
                    _ShakeWidget(
                      controller: _shakeCtrl,
                      child: SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _pinController,
                          autofocus: true,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: (_) => setState(() => _error = null),
                          onSubmitted: (_) => _onUnlock(),
                          style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 24,
                            color: AppTheme.textPrimary,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _error != null
                                    ? const Color(0xFFE57373)
                                    : AppTheme.accentColor,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          cursorColor: AppTheme.accentColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Error ──
                    SizedBox(
                      height: 18,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _error != null
                            ? Text(
                                _error!,
                                key: ValueKey(_error),
                                style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 12,
                                  color: Color(0xFFE57373),
                                  letterSpacing: 0.5,
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('no-error'),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Unlock button ──
                    GestureDetector(
                      onTap: _isLoading ? null : _onUnlock,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        width: 120,
                        decoration: BoxDecoration(
                          color: _pinController.text.length >= 4
                              ? AppTheme.accentColor
                              : AppTheme.accentColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'UNLOCK',
                                style: TextStyle(
                                  fontFamily: 'BarlowCondensed',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 3,
                                  color: _pinController.text.length >= 4
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShakeWidget extends AnimatedWidget {
  final Widget child;

  const _ShakeWidget({
    required AnimationController controller,
    required this.child,
  }) : super(listenable: controller);

  AnimationController get _controller => listenable as AnimationController;

  @override
  Widget build(BuildContext context) {
    final sineValue = 3 * 3.14159 * _controller.value;
    final dx = 10 * (1 - _controller.value) * _sin(sineValue);
    return Transform.translate(
      offset: Offset(dx, 0),
      child: child,
    );
  }

  double _sin(double x) {
    x = x % (2 * 3.14159);
    if (x > 3.14159) x -= 2 * 3.14159;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}