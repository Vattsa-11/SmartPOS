# SmartPOS - Modern Point of Sale System

A comprehensive retail management solution built with Flutter and FastAPI, featuring real-time inventory tracking, barcode scanning, weight-based product support, and seamless cross-platform deployment.

## Overview

SmartPOS is a production-ready point of sale system designed for modern retail businesses. With support for both web and mobile platforms, it provides a unified experience across devices while maintaining powerful features for inventory management, sales processing, and business analytics.

## Key Features

### User Management & Authentication
- Secure JWT-based authentication system
- Multi-user support with complete data isolation
- User registration and login workflows
- Profile management with shop details and UPI QR code upload
- Settings screen for business customization

### Product Management
- Complete CRUD operations for product catalog
- **Unit Type Support**: Pieces (pcs), Kilogram (kg), Gram (g), Litre (ltr), Millilitre (ml), Box, Pack, Dozen
- **Weight-Based Products**: Full support for decimal quantities (e.g., 2.5 kg, 1.75 ltr)
- Barcode scanning with hybrid implementation (web and mobile)
- Dynamic pricing with cost price, selling price, and discount management
- Product search and filtering capabilities
- Minimum and maximum stock level configuration
- Tax percentage and discount percentage tracking

### Advanced Inventory System
- Real-time stock monitoring with automatic updates
- **Decimal Quantity Support**: Enter 2.5 kg or 0.75 ltr for weight-based products
- Stock adjustment dialogs with weight/count-specific input
- Low stock alerts and reorder level management
- Inventory history and audit trail
- Product-specific stock tracking per user
- Automatic inventory deduction after sales (supports decimal quantities)

### Barcode Scanning (Hybrid)
- **Web Version**: Custom HTML5 camera scanner using MediaDevices API
- **Mobile Version**: Native camera access via mobile_scanner package
- Manual barcode entry fallback for both platforms
- Automatic platform detection with `kIsWeb` flag
- Camera permission handling for both environments

### Intelligent Billing System
- **Weight-Based Product Handling**: 
  - Automatic weight input dialog for kg/g/ltr/ml products
  - Shows price per unit (e.g., "₹50.00 per kg")
  - Edit button with weight input for cart items
  - Display shows "2.50 kg" instead of quantity counters
- **Count-Based Product Handling**:
  - Standard increment/decrement buttons for pieces
  - Whole number display and entry
- Real-time cart management with item editing
- Discount application (percentage-based)
- Multiple payment methods (Cash, UPI, Card, Bank Transfer)
- Invoice generation with unique invoice numbers
- Customer information capture (name, phone)
- Automatic inventory deduction on checkout

### Sales & Transaction Management
- Complete sales history with filtering
- Transaction details with line items
- Payment status tracking
- Customer purchase history
- Receipt generation and printing preparation
- Sales analytics and reporting

### Dashboard & Analytics
- Real-time sales statistics (daily, monthly)
- Top-selling products tracking
- Low stock alerts and warnings
- Recent transaction overview
- Revenue and profit analysis
- Customer count and engagement metrics

### Cross-Platform Support
- **Web Application**: Runs in any modern browser (Chrome, Firefox, Edge, Safari)
- **Mobile Apps**: Native Android APK and iOS IPA builds
- **Hybrid Camera**: Web uses HTML5, mobile uses native camera
- Responsive design adapts to screen sizes
- Material Design 3 theming
- Consistent user experience across platforms

## Technical Architecture

### Backend Stack
**Framework**: FastAPI (Python 3.8+)
- High-performance async web framework
- Automatic OpenAPI documentation
- Pydantic data validation
- CORS middleware for cross-origin requests

**Database**: SQLite
- Lightweight, serverless database
- User-specific data isolation
- Real-time inventory tracking
- Transaction support for data integrity

**API Design**:
- RESTful API architecture
- JWT-based authentication
- Header-based user identification (x-user-id)
- Comprehensive error handling and logging

**Key Endpoints**:
- `/api/login` - User authentication
- `/api/register` - New user registration
- `/api/products` - Product CRUD operations
- `/api/products/{id}` - Update product with decimal inventory support
- `/api/inventory` - Inventory management
- `/api/sales` - Sales transactions with decimal quantity support
- `/api/upload-qr` - UPI QR code upload
- `/users/me` - User profile with cache busting

### Frontend Stack
**Framework**: Flutter 3.35.7
- Cross-platform UI toolkit (web, Android, iOS)
- Hot reload for rapid development
- Material Design 3 components
- Provider state management

**Key Packages**:
- `provider` - State management
- `http` - API communication
- `mobile_scanner` (v3.5.5) - Native camera scanning
- `dart:html` - Web camera access
- `dart:ui_web` - Platform view registry for web

**Architecture Patterns**:
- Provider pattern for state management
- Repository pattern for API calls
- Model-View-ViewModel (MVVM) structure
- Responsive layout with adaptive widgets

**Special Implementations**:
- **Hybrid Barcode Scanner**: Automatic platform detection
  - Web: Custom HTML5 camera implementation
  - Mobile: Native mobile_scanner package
  - Seamless switching based on `kIsWeb` flag
- **Weight-Based Product System**: 
  - CartItem model uses `double quantity` instead of `int`
  - Dynamic UI based on product unit type
  - Decimal validation for weight inputs
  - Backend handles `float` quantities in sales

### Database Schema

**Users Table**
- Authentication credentials (email, password hash)
- Shop details (name, address, contact)
- UPI QR code URL
- Created/updated timestamps

**Products Table**
- Product information (name, barcode, SKU)
- Pricing (cost price, selling price)
- Unit type (pcs, kg, g, ltr, ml, box, pack, dozen)
- Tax and discount percentages
- User-specific ownership

**Inventory Table**
- Current stock (supports decimal values)
- Minimum and maximum stock levels
- Last updated timestamp
- Product relationship (foreign key)

**Sales Table**
- Invoice number and sale date
- Customer information (optional)
- Payment method and status
- Totals (subtotal, discount, tax, final amount)
- User ownership

**Sale Items Table**
- Product details and quantity (decimal support)
- Unit price and total price
- Discount and tax amounts
- Sale relationship (foreign key)

## Getting Started

### Quick Start (Windows)

**Option 1: PowerShell Launcher (Recommended)**
```powershell
# Right-click SmartPOS_Launcher.ps1 and select "Run with PowerShell"
# Or from terminal:
cd "c:\SRI\Sri works\APP project"
.\SmartPOS_Launcher.ps1
```

**Option 2: Batch Launcher**
```cmd
# Double-click SmartPOS_Launcher.bat
# Or from command prompt:
cd "c:\SRI\Sri works\APP project"
SmartPOS_Launcher.bat
```

**What the launcher does**:
1. Checks Python 3.8+ and Flutter SDK installation
2. Verifies project directory structure
3. Installs Python dependencies (uvicorn, fastapi, etc.)
4. Installs Flutter dependencies (pub get)
5. Starts backend server on http://127.0.0.1:8001
6. Starts frontend on http://127.0.0.1:8080
7. Opens browser automatically
8. Handles graceful shutdown

### Manual Setup

#### Prerequisites
- Python 3.8 or higher
- Flutter SDK 3.0 or higher
- Git (optional, for version control)
- Modern web browser (Chrome, Firefox, Edge)

#### Backend Setup

1. Navigate to backend directory:
```bash
cd smartpos/backend
```

2. Install dependencies:
```bash
pip install fastapi uvicorn python-multipart python-jose passlib bcrypt
```

3. Start the server:
```bash
python -m uvicorn simple_fastapi:app --host 0.0.0.0 --port 8001 --reload
```

4. Verify server is running:
- Open http://localhost:8001/docs for API documentation
- You should see the FastAPI Swagger UI

#### Frontend Setup

1. Navigate to frontend directory:
```bash
cd smartpos/frontend
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Build for web:
```bash
flutter build web
```

4. Start the web server:
```bash
cd build/web
python -m http.server 8080
```

5. Open application:
- Navigate to http://localhost:8080 in your browser
- Register a new user or login

### Building for Mobile

#### Android APK

1. Ensure Android SDK is configured:
```bash
flutter doctor
```

2. Build APK:
```bash
cd smartpos/frontend
flutter build apk --release
```

3. Find APK:
```
build/app/outputs/flutter-apk/app-release.apk
```

4. Install on device:
```bash
flutter install
# Or manually copy APK to device
```

**Camera Support**: The mobile APK will use the native `mobile_scanner` package, providing better camera performance than the web version. No additional configuration needed!

#### iOS IPA (macOS only)

1. Configure Xcode and certificates:
```bash
flutter doctor
```

2. Build for iOS:
```bash
cd smartpos/frontend
flutter build ios --release
```

3. Archive and distribute via Xcode

## Configuration

### Backend Configuration

**File**: `smartpos/backend/simple_fastapi.py`

Key settings:
- **Port**: 8001 (default)
- **Database**: `smartpos.db` (SQLite)
- **CORS**: Enabled for all origins (configure for production)
- **Static Files**: `/uploads` directory for QR codes

### Frontend Configuration

**File**: `smartpos/frontend/lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8001';
}
```

For production, update to your server URL.

### Camera Permissions

**Web**: No additional configuration needed (uses getUserMedia)

**Android**: Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS**: Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for barcode scanning</string>
```

## Usage Guide

### First Time Setup

1. **Register Account**
   - Click "Register" on login screen
   - Enter email, password, and shop details
   - Click "Create Account"

2. **Configure Settings**
   - Navigate to Settings screen
   - Upload UPI QR code for payments
   - Update shop information

3. **Add Products**
   - Go to Inventory Management
   - Click "Add Product"
   - Select unit type (pcs for count, kg/ltr for weight)
   - Enter pricing and initial quantity
   - For weight products, you can enter decimals (e.g., 10.5)

### Daily Operations

**Adding Weight-Based Products**:
1. Scan or enter barcode
2. For kg/g/ltr/ml products, a dialog appears
3. Enter weight (e.g., 2.5)
4. Product added to cart with that weight

**Adding Count-Based Products**:
1. Scan or enter barcode
2. Product automatically adds 1 piece to cart
3. Use +/- buttons to adjust quantity

**Processing Sales**:
1. Go to Billing screen
2. Scan or add products
   - Weight products show "2.50 kg"
   - Count products show "5 pcs"
3. Edit items by clicking Edit icon (weight) or +/- buttons (count)
4. Apply discounts if needed
5. Select payment method
6. Click "Checkout"
7. Inventory automatically deducts sold quantities

**Managing Inventory**:
1. Navigate to Inventory Management
2. View all products with current stock
3. Click "Add Stock" or "Remove Stock"
   - Weight products accept decimals (e.g., 5.5)
   - Count products accept whole numbers
4. Monitor low stock alerts

## API Documentation

### Authentication Endpoints

**POST** `/api/register`
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "Shop Name"
}
```

**POST** `/api/login`
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```
Returns: `{ "user_id": 1, "email": "...", "name": "..." }`

### Product Management

**GET** `/api/products`
- Headers: `x-user-id: 1`
- Returns: Array of products with inventory

**POST** `/api/products`
```json
{
  "name": "Product Name",
  "barcode": "123456",
  "price": 100.00,
  "selling_price": 120.00,
  "cost_price": 80.00,
  "unit": "kg",
  "initial_stock": 10.5,
  "minimum_stock": 5.0
}
```

**PUT** `/api/products/{product_id}`
```json
{
  "name": "Updated Name",
  "unit": "kg",
  "selling_price": 130.00,
  "stock": 15.5,
  "minimum_stock": 3.0
}
```

### Sales Endpoints

**POST** `/api/sales`
```json
{
  "invoice_number": "INV-001",
  "payment_method": "Cash",
  "customer_name": "John Doe",
  "customer_phone": "1234567890",
  "total_amount": 250.00,
  "items": [
    {
      "product_id": 1,
      "quantity": 2.5,
      "price": 100.00,
      "total": 250.00
    }
  ]
}
```
Note: Quantity can be decimal for weight-based products. Backend automatically updates inventory.

**GET** `/api/sales`
- Headers: `x-user-id: 1`
- Returns: Array of sales with items

## Troubleshooting

### Backend Issues

**Server won't start**:
- Check if port 8001 is already in use
- Verify Python version: `python --version` (should be 3.8+)
- Install dependencies: `pip install -r requirements.txt`

**Database errors**:
- Delete `smartpos.db` and restart (will recreate)
- Check file permissions in backend directory

### Frontend Issues

**Build fails**:
- Run `flutter pub get` to install dependencies
- Run `flutter clean` then `flutter build web`
- Check Flutter version: `flutter --version`

**Camera not working (web)**:
- Use HTTPS or localhost only
- Check browser permissions for camera access
- Try different browser (Chrome recommended)

**Camera not working (mobile)**:
- Check AndroidManifest.xml has camera permission
- Verify mobile_scanner package is installed
- Test on physical device (emulator cameras are limited)

### Common Errors

**"Product not found"**:
- Verify barcode is correct
- Check product exists in your account
- Ensure you're logged in

**"Insufficient stock"**:
- Check current inventory levels
- Add stock before selling
- For weight products, ensure enough kg/ltr available

**"Invalid quantity"**:
- Weight products: Use decimals (2.5, not "2,5")
- Count products: Use whole numbers
- Ensure positive values only

## Weight-Based vs Count-Based Products

### Weight-Based Units
- **Kilogram (kg)**, **Gram (g)**, **Litre (ltr)**, **Millilitre (ml)**
- Accept decimal quantities (e.g., 2.5, 0.75, 10.25)
- Cart shows: "2.50 kg" or "1.75 ltr"
- Billing prompts for weight entry
- No +/- buttons, only Edit button
- Backend stores as float, deducts decimal amounts

### Count-Based Units
- **Pieces (pcs)**, **Box**, **Pack**, **Dozen**
- Accept whole numbers only
- Cart shows: "5 pcs" or "3 box"
- Billing auto-adds 1 piece
- Has +/- increment buttons
- Backend handles as integers

## Mobile vs Web Differences

| Feature | Web Version | Mobile APK |
|---------|-------------|------------|
| **Camera** | HTML5 getUserMedia | Native camera API |
| **Performance** | Good | Excellent |
| **Permissions** | Browser prompt | OS-level permissions |
| **Scanner** | WebBarcodeScanner | mobile_scanner package |
| **Offline** | Requires connection | Can work offline (future) |
| **Installation** | Browser-based | Installed app |
| **Updates** | Automatic | Manual APK update |

**Important**: The mobile APK will have BETTER camera performance than the web version because it uses native camera access through the mobile_scanner package.

## Project Structure

```
APP project/
├── README.md                          # This file
├── SmartPOS_Launcher.bat              # Windows batch launcher
├── SmartPOS_Launcher.ps1              # PowerShell launcher (recommended)
└── smartpos/
    ├── backend/
    │   ├── simple_fastapi.py          # Main API server
    │   ├── requirements.txt           # Python dependencies
    │   ├── smartpos.db                # SQLite database
    │   ├── init_db.py                 # Database initialization
    │   ├── add_mock_data.py           # Sample data generator
    │   └── uploads/                   # QR code uploads
    └── frontend/
        ├── lib/
        │   ├── main.dart              # App entry point
        │   ├── config/
        │   │   └── api_config.dart    # API base URL
        │   ├── models/
        │   │   ├── product.dart       # Product model
        │   │   ├── cart_item.dart     # Cart model (double quantity)
        │   │   ├── inventory.dart
        │   │   └── sale.dart
        │   ├── providers/
        │   │   ├── auth_provider.dart
        │   │   ├── cart_provider.dart # Cart with decimal support
        │   │   └── inventory_provider.dart
        │   ├── screens/
        │   │   ├── login_screen.dart
        │   │   ├── dashboard_screen.dart
        │   │   ├── billing_screen.dart           # Billing with weight dialogs
        │   │   ├── billing_management_screen.dart # Enhanced cart display
        │   │   ├── inventory_management_screen.dart # Decimal stock input
        │   │   ├── add_edit_product_screen.dart  # Unit dropdown + decimals
        │   │   └── settings_screen.dart
        │   ├── services/
        │   │   └── api_service.dart   # HTTP client
        │   └── widgets/
        │       ├── barcode_scanner_widget.dart  # Hybrid wrapper
        │       └── web_barcode_scanner.dart     # Web camera
        ├── pubspec.yaml               # Flutter dependencies
        └── build/
            └── web/                   # Built web app
```

## Security Considerations

### Current Implementation
- JWT-based authentication
- Password hashing (to be implemented)
- User-specific data isolation
- Header-based user identification

### For Production
- [ ] Implement proper password hashing (bcrypt/argon2)
- [ ] Add HTTPS/SSL certificates
- [ ] Configure CORS for specific domains only
- [ ] Implement rate limiting
- [ ] Add input validation and sanitization
- [ ] Set up database backups
- [ ] Implement session management
- [ ] Add API versioning

## Performance Optimization

- SQLite for fast local database access
- Provider for efficient state management
- Image caching for QR codes with timestamp busting
- Lazy loading for product lists
- Debounced search inputs
- Optimized Flutter build (--release mode)

## Future Enhancements

### Planned Features
- Offline mode with local storage sync
- Thermal printer integration
- Receipt PDF generation
- Advanced analytics dashboard
- Customer loyalty program
- Multi-store support
- Cloud backup and sync
- Payment gateway integration
- Automated reports (daily/weekly/monthly)

### Technical Improvements
- PostgreSQL migration for multi-tenant support
- Redis caching layer
- WebSocket for real-time updates
- Docker containerization
- CI/CD pipeline
- Automated testing suite
- API rate limiting
- Enhanced security measures

## Contributing

This project is currently in active development. For feature requests or bug reports, please contact the development team.

## License

Private project - All rights reserved.

## Support

For questions, issues, or feature requests:
- Email: srisu0306@gmail.com
- GitHub: Vattsa-11/SmartPOS

---

**Built with**:  Flutter 3.35.7 | FastAPI | SQLite | Python 3.8+

**Last Updated**: October 2025
