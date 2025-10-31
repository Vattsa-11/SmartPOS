import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'web_barcode_scanner.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final VoidCallback? onClose;

  const BarcodeScannerWidget({
    super.key,
    required this.onBarcodeDetected,
    this.onClose,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  @override
  Widget build(BuildContext context) {
    // Use web-specific scanner for web platform
    if (kIsWeb) {
      return WebBarcodeScanner(
        onBarcodeDetected: widget.onBarcodeDetected,
        onClose: widget.onClose,
      );
    }
    
    // Use mobile scanner for mobile platforms
    return _MobileBarcodeScanner(
      onBarcodeDetected: widget.onBarcodeDetected,
      onClose: widget.onClose,
    );
  }
}

class _MobileBarcodeScanner extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final VoidCallback? onClose;

  const _MobileBarcodeScanner({
    required this.onBarcodeDetected,
    this.onClose,
  });

  @override
  State<_MobileBarcodeScanner> createState() => _MobileBarcodeScannerState();
}

class _MobileBarcodeScannerState extends State<_MobileBarcodeScanner> {
  MobileScannerController? controller;
  bool _isTorchOn = false;
  bool _hasDetected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    try {
      controller = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
        detectionSpeed: DetectionSpeed.normal,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
      controller?.toggleTorch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            widget.onClose?.call();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Barcode Scanner',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: _errorMessage != null
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
                      style: const TextStyle(color: Colors.white),
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
          : Stack(
              children: [
                // Camera Preview
                if (controller != null)
                  MobileScanner(
                    controller: controller,
                    onDetect: (BarcodeCapture capture) {
                      if (_hasDetected) return;
                      
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final barcode = barcodes.first;
                        final String? code = barcode.rawValue;
                        
                        if (code != null && code.isNotEmpty) {
                          setState(() {
                            _hasDetected = true;
                          });
                          
                          // Call callback with detected barcode
                          widget.onBarcodeDetected(code);
                          
                          // Close scanner after detection
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          });
                        }
                      }
                    },
                  ),
                
                // Scanning Frame Overlay
                Center(
                  child: Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hasDetected ? Colors.green : Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // Instructions
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      if (_hasDetected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Barcode Detected!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          'Position barcode within the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
