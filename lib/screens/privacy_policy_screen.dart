import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────
// Data model for a policy section
// ─────────────────────────────────────────────────────────
class _PolicySection {
  final String title;
  final String body;
  final IconData icon;

  const _PolicySection({
    required this.title,
    required this.body,
    required this.icon,
  });
}

const List<_PolicySection> _kSections = [
  _PolicySection(
    icon: Icons.lock_outline,
    title: 'End-to-End Encryption',
    body:
        'All messages sent through Silex are encrypted on your device before '
        'being transmitted. Only the intended recipient can decrypt and read them. '
        'The server acts solely as a relay for ciphertext — it has no access to '
        'the content of your conversations at any time.',
  ),
  _PolicySection(
    icon: Icons.key_outlined,
    title: 'Your Keys, Your Device',
    body:
        'Cryptographic key pairs are generated locally on your device and never '
        'leave it. Private keys are stored only within the secure storage of your '
        'phone. Silex servers store only your public key, which by design cannot '
        'be used to decrypt any message.',
  ),
  _PolicySection(
    icon: Icons.phone_outlined,
    title: 'Phone Number & Identity',
    body:
        'Registration requires a phone number for identity verification via OTP. '
        'We do not store your phone number in plain text — only a one-way '
        'cryptographic hash (SHA-256) is persisted on the server. This hash '
        'cannot be reversed to obtain your original number.',
  ),
  _PolicySection(
    icon: Icons.storage_outlined,
    title: 'What the Server Stores',
    body:
        'The server retains the minimum data necessary to operate:\n'
        '  · Public keys (for key exchange)\n'
        '  · Session metadata (token hash, device identifier)\n'
        '  · Encrypted message payloads, temporarily, until delivery\n'
        '  · OTP hashes, valid for 10 minutes\n\n'
        'Messages are deleted from the server once delivered or after 7 days. '
        'No message content, contact lists, or conversation history is stored '
        'in plain text at any point.',
  ),
  _PolicySection(
    icon: Icons.visibility_off_outlined,
    title: 'Zero Server Knowledge',
    body:
        'Silex is designed so that the server cannot read your messages even if '
        'compelled to do so. The architecture follows a zero-trust model: the '
        'server is treated as an untrusted intermediary. Encrypted payloads '
        'stored in transit are opaque to anyone without the recipient\'s '
        'private key.',
  ),
  _PolicySection(
    icon: Icons.autorenew_outlined,
    title: 'Session & Key Rotation',
    body:
        'Sessions are cryptographically bound to a specific device. Each session '
        'token is stored as a hash — the raw token is never persisted. '
        'The key exchange scheme is inspired by the Signal Protocol, which '
        'provides forward secrecy properties: past sessions cannot be '
        'decrypted even if future keys are compromised.',
  ),
  _PolicySection(
    icon: Icons.photo_outlined,
    title: 'Media & Attachments',
    body:
        'Media files are encrypted before upload. References are stored with a '
        'composite foreign key that ties them to the encrypted message. Media '
        'is available for a limited window (currently 48 hours) and is removed '
        'from the server after that period. No media is processed or analyzed '
        'server-side.',
  ),
  _PolicySection(
    icon: Icons.share_outlined,
    title: 'No Data Sharing',
    body:
        'Silex does not sell, rent, or share your data with third parties for '
        'advertising, analytics, or any other commercial purpose. No third-party '
        'SDKs with data-collection capabilities are embedded in the application.',
  ),
  _PolicySection(
    icon: Icons.update_outlined,
    title: 'Policy Updates',
    body:
        'This policy may be updated as the application evolves. Significant '
        'changes will be communicated within the app before taking effect. '
        'Continued use of Silex after a policy update constitutes acceptance '
        'of the revised terms.',
  ),
  _PolicySection(
    icon: Icons.mail_outline,
    title: 'Contact',
    body:
        'If you have questions about this privacy policy or how your data is '
        'handled, you can reach the developer directly through the project\'s '
        'official repository or contact channel.',
  ),
];

// ─────────────────────────────────────────────────────────
// PrivacyPolicyScreen
// ─────────────────────────────────────────────────────────
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Track which sections are expanded
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
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
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Privacy policy',
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              // ── Header banner ──
              SliverToBoxAdapter(
                child: _HeaderBanner(),
              ),

              // ── Last updated chip ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.accentColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Last updated: March 2026',
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Intro text ──
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Silex is built on the principle that private communication '
                    'should be private by default, not by policy. The following '
                    'describes how the application handles your data — and more '
                    'importantly, how it is designed to minimize what it touches '
                    'in the first place.',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.7,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              // ── Divider ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: AppTheme.accentColor,
                    height: 1,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Policy sections (accordion) ──
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final section = _kSections[i];
                    final isOpen = _expanded.contains(i);
                    return _PolicyTile(
                      section: section,
                      isOpen: isOpen,
                      onTap: () => _toggle(i),
                    );
                  },
                  childCount: _kSections.length,
                ),
              ),

              // ── Footer ──
              SliverToBoxAdapter(
                child: _Footer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Header Banner
// ─────────────────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.accentColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy by design',
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Silex is designed so the server cannot read your messages — '
                  'not because of a policy, but because of how the cryptography works.',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Policy Tile (accordion item)
// ─────────────────────────────────────────────────────────
class _PolicyTile extends StatelessWidget {
  final _PolicySection section;
  final bool isOpen;
  final VoidCallback onTap;

  const _PolicyTile({
    required this.section,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isOpen
                ? AppTheme.backgroundSecondary
                : AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOpen
                  ? AppTheme.accentColor
                  : AppTheme.accentColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      section.icon,
                      size: 18,
                      color: isOpen
                          ? AppTheme.accentColor
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.title,
                        style: TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isOpen
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: isOpen
                            ? AppTheme.accentColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body (animated expand) ──
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: AppTheme.accentColor,
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        section.body,
                        style: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.75,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: isOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                sizeCurve: Curves.easeOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          Divider(
            color: AppTheme.accentColor,
            height: 1,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 12,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Silex · End-to-End Encrypted',
                style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}