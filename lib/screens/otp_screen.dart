import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../core/crypto_service.dart';
import '../core/pin_service.dart';
import '../services/keys_service.dart';
import '../services/socket_service.dart';
import 'create_pin_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? devOtp;

  const OtpScreen({super.key, required this.phone, this.devOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.devOtp != null) {
      _otpController.text = widget.devOtp!;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  bool get _isOtpValid => _otpController.text.trim().length == 6;

  Future<void> _onVerify() async {
    if (!_isOtpValid || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.verifyOtp(widget.phone, _otpController.text.trim());

      // generate and upload keys ONLY if it's your first login
      final keysAlreadyGenerated = await CryptoService.keysGenerated();
      if (!keysAlreadyGenerated) {
        final keyBundle = await CryptoService.generateAllKeys();
        await KeysService.uploadKeys(keyBundle);
      }

      if (!mounted) return;

      // check if PIN is already configured (returning user)
      final hasPinConfigured = await PinService.isPinConfigured();

      if (hasPinConfigured) {
        // returning user — connect and go home
        await SocketService.connect();
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        // new user — go to create PIN (keys are still in plaintext in storage)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CreatePinScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Verification code',
                style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit code sent to\n${widget.phone}',
                style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 28,
                  color: AppTheme.textPrimary,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: AppTheme.accentColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                cursorColor: AppTheme.accentColor,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _isOtpValid ? 1.0 : 0.40,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _isOtpValid ? _onVerify : null,
                    child: Container(
                      height: 40,
                      constraints: const BoxConstraints(minWidth: 88),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.accentColor),
                              ),
                            )
                          : Text(
                              'Verify',
                              style: TextStyle(
                                fontFamily: 'BarlowCondensed',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 1.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
