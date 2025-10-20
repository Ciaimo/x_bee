import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'package:x_bee/features/entities/presentation/read_entity_screen.dart';
import 'package:x_bee/services/firebase_services.dart';

class ScanEntityScreen extends ConsumerStatefulWidget {
  const ScanEntityScreen({super.key});

  @override
  ConsumerState<ScanEntityScreen> createState() => _ScanEntityScreenState();
}

class _ScanEntityScreenState extends ConsumerState<ScanEntityScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScanned;

  @override
  void reassemble() {
    super.reassemble();
    // ensure camera is restarted after hot reload
    _controller.stop();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String scannedId) async {
    if (_isProcessing) return;
    // ignore duplicates in a short window
    if (_lastScanned == scannedId) return;
    _isProcessing = true;
    _lastScanned = scannedId;
    await _controller.stop();

    final orgAsync = ref.read(organisationIdProvider);
    final orgId = orgAsync.asData?.value;
    if (orgId == null || orgId.isEmpty) {
      await _showMessage(
          'No organisation', 'No organisation available for this user.');
      _resumeScanner();
      return;
    }

    try {
      final doc = await FirebaseServices.firestore
          .collection('organisations')
          .doc(orgId)
          .collection('entities')
          .doc(scannedId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReadEntityScreen(entityId: scannedId)),
        );
        _resumeScanner();
      } else {
        await _showMessage('Entity not found',
            'The scanned entity "$scannedId" does not exist.');
        _resumeScanner();
      }
    } catch (e) {
      await _showMessage('Error', 'Failed to check entity: $e');
      _resumeScanner();
    }
  }

  void _resumeScanner() {
    _isProcessing = false;
    // allow re-scanning the same id after a short delay
    Future.delayed(
        const Duration(milliseconds: 500), () => _lastScanned = null);
    _controller.start();
  }

  Future<void> _showMessage(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Entity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              try {
                await _controller.toggleTorch();
              } catch (_) {}
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () async {
              try {
                await _controller.switchCamera();
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isEmpty) return;
                    final raw = barcodes.first.rawValue;
                    if (raw == null || raw.isEmpty) return;
                    _handleScan(raw.trim());
                  },
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 18),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Point camera at entity QR code',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
