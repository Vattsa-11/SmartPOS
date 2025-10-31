import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BarcodeScannerModal extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;
  
  const BarcodeScannerModal({
    Key? key,
    required this.onBarcodeScanned,
  }) : super(key: key);

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> {
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 300,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enter Barcode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Info message for web
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Camera scanner is not available on web. Please enter the barcode manually.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            // Barcode input
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                hintText: 'Enter barcode number',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onBarcodeScanned(value.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Submit button
            ElevatedButton(
              onPressed: () {
                if (_barcodeController.text.trim().isNotEmpty) {
                  widget.onBarcodeScanned(_barcodeController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
