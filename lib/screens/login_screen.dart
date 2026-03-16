import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

// ─────────────────────────────────────────────────────────
// Country model
// ─────────────────────────────────────────────────────────
class _Country {
  final String name;
  final String flag;
  final String dialCode;

  const _Country({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

const List<_Country> _kCountries = [
  _Country(name: 'Mexico', flag: '🇲🇽', dialCode: '+52'),
  _Country(name: 'United States', flag: '🇺🇸', dialCode: '+1'),
  _Country(name: 'Canada', flag: '🇨🇦', dialCode: '+1'),
  _Country(name: 'Spain', flag: '🇪🇸', dialCode: '+34'),
  _Country(name: 'Argentina', flag: '🇦🇷', dialCode: '+54'),
  _Country(name: 'Colombia', flag: '🇨🇴', dialCode: '+57'),
  _Country(name: 'Chile', flag: '🇨🇱', dialCode: '+56'),
  _Country(name: 'Brazil', flag: '🇧🇷', dialCode: '+55'),
  _Country(name: 'Peru', flag: '🇵🇪', dialCode: '+51'),
  _Country(name: 'Venezuela', flag: '🇻🇪', dialCode: '+58'),
  _Country(name: 'Ecuador', flag: '🇪🇨', dialCode: '+593'),
  _Country(name: 'Bolivia', flag: '🇧🇴', dialCode: '+591'),
  _Country(name: 'Germany', flag: '🇩🇪', dialCode: '+49'),
  _Country(name: 'France', flag: '🇫🇷', dialCode: '+33'),
  _Country(name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44'),
  _Country(name: 'Italy', flag: '🇮🇹', dialCode: '+39'),
  _Country(name: 'Japan', flag: '🇯🇵', dialCode: '+81'),
  _Country(name: 'China', flag: '🇨🇳', dialCode: '+86'),
  _Country(name: 'India', flag: '🇮🇳', dialCode: '+91'),
  _Country(name: 'Australia', flag: '🇦🇺', dialCode: '+61'),
];

// ─────────────────────────────────────────────────────────
// LoginScreen
// ─────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();

  bool _isLoading = false;
  _Country _selectedCountry = _kCountries.first;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Country picker — full-screen ──
  Future<void> _showCountryPicker() async {
    final result = await Navigator.of(context).push<_Country>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CountryPickerScreen(selected: _selectedCountry),
      ),
    );
    if (result != null) setState(() => _selectedCountry = result);
  }

  // ── Validation & submission ──
  bool get _isPhoneValid => _phoneController.text.trim().length == 10;

  Future<void> _onNext() async {
    if (!_isPhoneValid || _isLoading) return;

    final fullPhone =
        '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

    setState(() => _isLoading = true);

    try {
      final otp = await AuthService.requestOtp(fullPhone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(phone: fullPhone, devOtp: otp),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        // ── Menu (3 dots) top-right ──
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              color: AppTheme.backgroundSecondary,
              icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
              onSelected: (value) {
                if (value == 'privacy') {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'privacy',
                  child: Text('Privacy policy',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontFamily: 'ShareTechMono',
                        fontSize: 13,
                      )),
                ),
              ],
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // ── Title ──
                  Text(
                    'Phone number',
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
                    'You will receive a verification code. Carrier\nrates may apply.',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Country selector ──
                  _CountrySelector(
                    country: _selectedCountry,
                    onTap: _showCountryPicker,
                  ),
                  const SizedBox(height: 12),

                  // ── Dial code + phone number row ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Dial code box
                      _DialCodeBox(code: _selectedCountry.dialCode),
                      const SizedBox(width: 12),
                      // Phone number field
                      Expanded(
                        child: _PhoneField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Digit counter + error hint ──
                  Builder(builder: (_) {
                    final len = _phoneController.text.trim().length;
                    final hasInput = len > 0;
                    final isOver = len > 10;
                    final color = isOver
                        ? const Color(0xFFE57373)
                        : hasInput && len == 10
                            ? AppTheme.accentColor
                            : AppTheme.textSecondary;
                    final label = isOver
                        ? 'Max 10 digits'
                        : hasInput
                            ? '$len / 10'
                            : '10 digits required';
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 10,
                          letterSpacing: 1,
                          color: color,
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  // ── Next button bottom-right ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: _isPhoneValid ? 1.0 : 0.40,
                      duration: const Duration(milliseconds: 200),
                      child: _NextButton(
                        isLoading: _isLoading,
                        onTap: _isPhoneValid ? _onNext : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Country Selector Row
// ─────────────────────────────────────────────────────────
class _CountrySelector extends StatelessWidget {
  final _Country country;
  final VoidCallback onTap;

  const _CountrySelector({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                country.name,
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Dial Code Box
// ─────────────────────────────────────────────────────────
class _DialCodeBox extends StatelessWidget {
  final String code;

  const _DialCodeBox({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'ShareTechMono',
          fontSize: 15,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Phone Number Field — floating label (nativo Flutter)
// ─────────────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos Theme para sobreescribir los colores del InputDecorator
    // sin tocar AppTheme global.
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.accentColor,       // color del label elevado + border
              onSurface: AppTheme.textPrimary,      // color del texto escrito
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.backgroundSecondary,
          // borde inactivo
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: AppTheme.accentColor.withOpacity(0.30),
              width: 1,
            ),
          ),
          // borde activo
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: AppTheme.accentColor,
              width: 2,
            ),
          ),
          // label styles
          labelStyle: const TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
          floatingLabelStyle: const TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 11,
            color: AppTheme.accentColor,
            letterSpacing: 0.3,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        autofocus: true,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'ShareTechMono',
          fontSize: 16,
          color: AppTheme.textPrimary,
          letterSpacing: 1.2,
        ),
        decoration: const InputDecoration(
          labelText: 'Phone number',
        ),
        cursorColor: AppTheme.accentColor,
        cursorWidth: 2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Country Picker — Full Screen
// ─────────────────────────────────────────────────────────
class _CountryPickerScreen extends StatefulWidget {
  final _Country selected;
  const _CountryPickerScreen({required this.selected});

  @override
  State<_CountryPickerScreen> createState() => _CountryPickerScreenState();
}

class _CountryPickerScreenState extends State<_CountryPickerScreen> {
  final _searchCtrl = TextEditingController();
  List<_Country> _filtered = _kCountries;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? _kCountries
            : _kCountries
                .where((c) =>
                    c.name.toLowerCase().contains(q) ||
                    c.dialCode.contains(q))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select country',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  prefixIcon:
                      Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                cursorColor: AppTheme.accentColor,
              ),
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: AppTheme.accentColor.withOpacity(0.15),
          ),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = c.name == widget.selected.name;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(c),
                  splashColor: AppTheme.accentColor.withOpacity(0.08),
                  child: Container(
                    color: isSelected
                        ? AppTheme.accentColor.withOpacity(0.06)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Text(c.flag,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 14,
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          c.dialCode,
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 13,
                            color: isSelected
                                ? AppTheme.accentColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check,
                              size: 16, color: AppTheme.accentColor),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Next Button (pill FAB)
// ─────────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _NextButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                ),
              )
            : Text(
                'Next',
                style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
      ),
    );
  }
}