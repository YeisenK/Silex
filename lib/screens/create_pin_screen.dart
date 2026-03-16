import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/pin_service.dart';
import '../core/crypto_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isConfirmStep = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _onNext() async {
    if (!_isConfirmStep) {
      if (_pinController.text.length < 4 || _pinController.text.length > 6) {
        setState(() => _error = 'PIN must be 4-6 digits');
        return;
      }
      setState(() {
        _isConfirmStep = true;
        _error = null;
      });
      return;
    }

    if (_confirmController.text != _pinController.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await PinService.createPin(_pinController.text);
      await PinService.unlockWithPin(_pinController.text);
      await SocketService.connect();
      await CryptoService.ensureIdentityPublic();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to create PIN: $e';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: !_isConfirmStep
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () {
                  setState(() {
                    _isConfirmStep = false;
                    _confirmController.clear();
                    _error = null;
                  });
                },
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.lock_outline,
                size: 48,
                color: AppTheme.accentColor,
              ),
              const SizedBox(height: 24),
              Text(
                _isConfirmStep ? 'Confirm your PIN' : 'Create a PIN',
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isConfirmStep
                    ? 'Enter your PIN again to confirm.'
                    : 'Your PIN encrypts your private keys.\nChoose 4-6 digits you\'ll remember.',
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller:
                    _isConfirmStep ? _confirmController : _pinController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() => _error = null),
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 13,
                    color: Color(0xFFE57373),
                  ),
                ),
              ],
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _isLoading ? null : _onNext,
                  child: Container(
                    height: 40,
                    constraints: const BoxConstraints(minWidth: 88),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundSecondary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.accentColor),
                            ),
                          )
                        : Text(
                            _isConfirmStep ? 'Confirm' : 'Next',
                            style: const TextStyle(
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}