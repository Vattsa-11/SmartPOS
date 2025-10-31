import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _upiIdController = TextEditingController();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isUploadingQr = false;
  
  @override
  void initState() {
    super.initState();
    // Load UPI ID from user if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user?.upiId != null) {
        _upiIdController.text = user!.upiId!;
      }
    });
  }
  
  @override
  void dispose() {
    _upiIdController.dispose();
    super.dispose();
  }
  
  Future<void> _saveUpiSettings() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not found'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      await _apiService.updateUpiSettings(
        int.parse(user.id!),
        _upiIdController.text.trim(),
        null, // QR URL not implemented yet
      );
      
      // Refresh user data to get updated UPI settings
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI settings saved successfully ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving UPI settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  Future<void> _uploadQrCode() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not found'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    try {
      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return; // User cancelled
      
      setState(() => _isUploadingQr = true);
      
      // Read image bytes for web compatibility
      final bytes = await image.readAsBytes();
      
      // Upload to backend
      await _apiService.uploadUpiQrBytes(
        int.parse(user.id!),
        bytes,
        image.name,
      );
      
      // Refresh user data to get updated QR URL
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      
      if (mounted) {
        final updatedUser = Provider.of<AuthProvider>(context, listen: false).user;
        print('📸 QR Upload - Updated user QR URL: ${updatedUser?.upiQrUrl}');
        
        setState(() {}); // Trigger rebuild to show new QR
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code uploaded successfully ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading QR: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingQr = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const Text(
              'Configure your SmartPOS system',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Business Information Section (Read-only)
            _buildSectionHeader('🏪 Business Information', null),
            const SizedBox(height: 12),
            _buildBusinessInfoCard(user),
            
            const SizedBox(height: 24),
            
            // UPI Payment Settings Section
            _buildSectionHeader('📱 UPI Payment Settings', null),
            const SizedBox(height: 12),
            _buildUpiSettingsCard(),
            
            const SizedBox(height: 24),
            
            // Database Status Section
            _buildSectionHeader('💾 Database Status', null),
            const SizedBox(height: 12),
            _buildDatabaseStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData? icon) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Business Information Card (Read-only)
  Widget _buildBusinessInfoCard(User user) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReadOnlyField('Shop Name', user.shopName),
            const SizedBox(height: 16),
            _buildReadOnlyField('Owner Name', user.ownerName),
            const SizedBox(height: 16),
            _buildReadOnlyField('Phone', user.phone),
            const SizedBox(height: 16),
            _buildReadOnlyField('Email', user.email),
            const SizedBox(height: 12),
            Text(
              'Contact support to update business information',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[800],
            isDense: true,
          ),
        ),
      ],
    );
  }

  // UPI Settings Card
  Widget _buildUpiSettingsCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UPI ID (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _upiIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'yourname@upi',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your UPI ID for receiving payments',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'UPI QR Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
              ),
              child: user?.upiQrUrl != null && user!.upiQrUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        '${ApiConfig.baseUrl}${user.upiQrUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ QR Image Error: $error');
                          print('❌ QR URL: ${ApiConfig.baseUrl}${user.upiQrUrl}');
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load QR code',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please upload again',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No QR code uploaded',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload your UPI QR code image',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingQr ? null : _uploadQrCode,
                    icon: _isUploadingQr
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isUploadingQr ? 'Uploading...' : 'Upload QR Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'This QR code will be shown during UPI payment at billing',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveUpiSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'Saving...' : 'Save UPI Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Database Status Card
  Widget _buildDatabaseStatusCard() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusItem(
              '☁️ Cloud Sync',
              'Synced',
              AppColors.success,
            ),
            const SizedBox(height: 12),
            Text(
              'Your data is automatically backed up to the cloud and synced across devices.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
