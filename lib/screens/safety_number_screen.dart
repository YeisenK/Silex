import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/safety_number_service.dart';
import '../core/storage_service.dart';
import '../services/keys_service.dart';
import '../theme/app_theme.dart';

class SafetyNumberScreen extends StatefulWidget {
  final String contactId;
  final String contactName;

  const SafetyNumberScreen({
    super.key,
    required this.contactId,
    required this.contactName,
  });

  @override
  State<SafetyNumberScreen> createState() => _SafetyNumberScreenState();
}

class _SafetyNumberScreenState extends State<SafetyNumberScreen> {
  String? _safetyNumber;
  List<String>? _rows;
  bool _isLoading = true;
  String? _error;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _generateSafetyNumber();
  }

  Future<void> _generateSafetyNumber() async {
    try {
      final myIdentityKey = await StorageService.getKey('identity_public');
      if (myIdentityKey == null) {
        setState(() {
          _error = 'Identity key not found';
          _isLoading = false;
        });
        return;
      }

      final keyBundle = await KeysService.getKeyBundle(widget.contactId);
      final theirIdentityKey = keyBundle['identity_key'] as String;

      final safetyNumber = SafetyNumberService.generate(
        myIdentityKey: myIdentityKey,
        theirIdentityKey: theirIdentityKey,
      );

      setState(() {
        _safetyNumber = safetyNumber;
        _rows = SafetyNumberService.formatRows(safetyNumber);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate safety number';
        _isLoading = false;
      });
    }
  }

  void _scanQR() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QRScannerScreen(
          expectedSafetyNumber: _safetyNumber!,
          onResult: (matched) {
            Navigator.of(context).pop();
            setState(() => _verified = matched);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  matched
                      ? 'Identity verified'
                      : 'Verification failed — safety numbers do not match',
                ),
                backgroundColor:
                    matched ? AppTheme.accentColor : const Color(0xFFE57373),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Verify ${widget.contactName}',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.accentColor))
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // ── Status ──
                      if (_verified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  color: AppTheme.accentColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Identity verified',
                                style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 13,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Info ──
                      Text(
                        'Compare this safety number with ${widget.contactName} '
                        'by meeting in person or through a trusted channel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 12,
                          color:
                              AppTheme.textSecondary.withValues(alpha: 0.8),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── QR Code ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _safetyNumber!,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1A1A1A),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Safety number ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: _rows!
                              .map(
                                (row) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    row,
                                    style: TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 16,
                                      color: AppTheme.textPrimary
                                          .withValues(alpha: 0.9),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Copy button ──
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _safetyNumber!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Safety number copied'),
                              backgroundColor: AppTheme.accentColor,
                            ),
                          );
                        },
                        icon: Icon(Icons.copy,
                            size: 16, color: AppTheme.accentColor),
                        label: Text(
                          'Copy number',
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Scan button ──
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _scanQR,
                          icon: const Icon(Icons.qr_code_scanner,
                              color: Colors.white),
                          label: const Text(
                            'Scan their QR code',
                            style: TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

// ── QR Scanner ──

class _QRScannerScreen extends StatefulWidget {
  final String expectedSafetyNumber;
  final void Function(bool matched) onResult;

  const _QRScannerScreen({
    required this.expectedSafetyNumber,
    required this.onResult,
  });

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _hasScanned = true;
        final matched = value.trim() == widget.expectedSafetyNumber;
        widget.onResult(matched);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Point at the other device\'s QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}