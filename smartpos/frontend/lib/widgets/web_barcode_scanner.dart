import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebBarcodeScanner extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final VoidCallback? onClose;

  const WebBarcodeScanner({
    super.key,
    required this.onBarcodeDetected,
    this.onClose,
  });

  @override
  State<WebBarcodeScanner> createState() => _WebBarcodeScannerState();
}

class _WebBarcodeScannerState extends State<WebBarcodeScanner> {
  final String _videoElementId = 'barcode-scanner-video-${DateTime.now().millisecondsSinceEpoch}';
  html.MediaStream? _stream;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Register the video element view
      ui_web.platformViewRegistry.registerViewFactory(
        _videoElementId,
        (int viewId) {
          final videoElement = html.VideoElement()
            ..id = _videoElementId
            ..autoplay = true
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover';
          
          // Request camera access
          html.window.navigator.mediaDevices!.getUserMedia({
            'video': {
              'facingMode': 'environment',
              'width': {'ideal': 1280},
              'height': {'ideal': 720}
            }
          }).then((stream) {
            _stream = stream;
            videoElement.srcObject = stream;
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }).catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Camera access denied. Please allow camera permission and try again.';
              });
            }
          });
          
          return videoElement;
        },
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _stopCamera();
    _barcodeController.dispose();
    super.dispose();
  }

  void _stopCamera() {
    if (_stream != null) {
      _stream!.getTracks().forEach((track) {
        track.stop();
      });
      _stream = null;
    }
  }

  void _submitBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      // Call callback BEFORE popping
      widget.onBarcodeDetected(barcode);
      // Small delay to ensure callback completes before navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      // Show error if barcode is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a barcode'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            widget.onClose?.call();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Barcode Scanner (Web)',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Note: Camera access requires HTTPS or localhost',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Camera Preview
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: HtmlElementView(
                              viewType: _videoElementId,
                            ),
                          ),
                          // Scanning frame overlay
                          Center(
                            child: Container(
                              width: 300,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          // Instructions
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.black54,
                              child: const Text(
                                'Position barcode within the frame\nOr enter manually below',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Manual entry section
                    Container(
                      color: Colors.grey[900],
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Manual Barcode Entry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _barcodeController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              hintText: 'Type or scan barcode here',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[800],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.qr_code, color: Colors.white70),
                            ),
                            onSubmitted: (_) => _submitBarcode(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _submitBarcode,
                            icon: const Icon(Icons.check),
                            label: const Text('Submit Barcode'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
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
