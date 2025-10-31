# SmartPOS - Modern Point of Sale System

A comprehensive retail management solution built with Flutter and FastAPI, designed for businesses of all sizes - from small shops to large enterprises. Features real-time inventory tracking, barcode scanning, weight-based product support, customer management, and seamless cross-platform deployment.

**Last Updated**: October 31, 2025  
**Version**: 1.2.0  
**Status**: Production Ready ✅  
**Target Audience**: Small, Medium & Large Businesses 🏪

## Overview

SmartPOS is a production-ready point of sale system designed for **all types of businesses** - from small street vendors to medium retail shops to large enterprises. Whether you're running a small kirana store, a local grocery shop, or a growing retail chain, SmartPOS provides an affordable, easy-to-use solution. With support for both web and mobile platforms, it offers a unified experience across devices while maintaining powerful features for inventory management, sales processing, customer tracking, and business analytics.

## 🚀 Key Features

### User Management & Authentication
- ✅ Secure JWT-based authentication system
- ✅ Multi-user support with complete data isolation
- ✅ User registration and login workflows
- ✅ Profile management with shop details and UPI QR code upload
- ✅ Settings screen for business customization

### Product Management
- ✅ Complete CRUD operations for product catalog
- ✅ **Unit Type Support**: Pieces (pcs), Kilogram (kg), Gram (g), Litre (ltr), Millilitre (ml), Box, Pack, Dozen
- ✅ **Weight-Based Products**: Full support for decimal quantities (e.g., 2.5 kg, 1.75 ltr)
- ✅ Barcode scanning with hybrid implementation (web and mobile)
- ✅ Dynamic pricing with cost price, selling price, and discount management
- ✅ Product search and filtering capabilities
- ✅ Minimum and maximum stock level configuration
- ✅ Tax percentage and discount percentage tracking

### Advanced Inventory System
- ✅ Real-time stock monitoring with automatic updates
- ✅ **Decimal Quantity Support**: Enter 2.5 kg or 0.75 ltr for weight-based products
- ✅ Stock adjustment dialogs with weight/count-specific input
- ✅ Low stock alerts and reorder level management
- ✅ Inventory history and audit trail
- ✅ Product-specific stock tracking per user
- ✅ Automatic inventory deduction after sales (supports decimal quantities)

### Barcode Scanning (Hybrid)
- ✅ **Web Version**: Custom HTML5 camera scanner using MediaDevices API
- ✅ **Mobile Version**: Native camera access via mobile_scanner package
- ✅ Manual barcode entry fallback for both platforms
- ✅ Automatic platform detection with `kIsWeb` flag
- ✅ Camera permission handling for both environments

### Intelligent Billing System
- ✅ **Mobile-Optimized UI**: DraggableScrollableSheet for checkout section
  - Minimizes to 15% showing only total
  - Swipe up to 50% or 85% for full checkout
  - Products remain visible on top
- ✅ **Weight-Based Product Handling**: 
  - Automatic weight input dialog for kg/g/ltr/ml products
  - Shows price per unit (e.g., "₹50.00 per kg")
  - Edit button with weight input for cart items
  - Display shows "2.50 kg" instead of quantity counters
- ✅ **Count-Based Product Handling**:
  - Standard increment/decrement buttons for pieces
  - Whole number display and entry
- ✅ Real-time cart management with item editing
- ✅ Discount application (percentage-based)
- ✅ Multiple payment methods (Cash, UPI, Card, Bank Transfer)
- ✅ Invoice generation with unique invoice numbers
- ✅ Customer information capture (name, phone)
- ✅ Automatic inventory deduction on checkout
- ✅ **Print Invoice**: Opens printable invoice in new window
- ✅ **QR Code Display**: UPI payment QR code in checkout

### Customer Relationship Management
- ✅ Complete customer database with contact details
- ✅ **Purchase Count Tracking**: Displays number of purchases per customer
- ✅ **Total Spent Tracking**: Cumulative purchase amount per customer
- ✅ Last purchase date tracking
- ✅ Customer search and filtering
- ✅ Credit limit and balance management
- ✅ Customer type categorization (Regular, VIP, Wholesale)
- ✅ Customer-specific purchase history

### Sales & Transaction Management
- ✅ Complete sales history with filtering
- ✅ Transaction details with line items
- ✅ Payment status tracking
- ✅ Customer purchase history
- ✅ Receipt generation and printing
- ✅ Sales analytics and reporting

### Dashboard & Analytics
- ✅ Real-time sales statistics (daily, monthly)
- ✅ **Recent Activity Feed**: Shows last 5 sales transactions with auto-refresh
- ✅ **Top Customers Table**: Displays customers with purchase count and total spent
- ✅ Low stock alerts and warnings
- ✅ Revenue and profit analysis
- ✅ Customer count and engagement metrics
- ✅ **Auto-refresh**: Dashboard updates automatically after new sale

### Reports & Analytics
- ✅ **Dark Theme Consistency**: All stat cards use dark backgrounds
- ✅ **Three Tab System**:
  - **Sales Tab**: Total sales, transactions, items sold, average sale value
  - **Inventory Tab**: Total items, low stock count, out of stock, total inventory value
  - **Customers Tab**: Total customer count with growth metrics
- ✅ Date range filtering for custom reports
- ✅ Visual statistics with color-coded cards
- ✅ Export capabilities (future enhancement)

### Settings & Configuration
- ✅ **Simplified UI**: Removed technical database information
- ✅ **Cloud Sync Status**: Simple user-friendly sync indicator
- ✅ **UPI QR Code Management**: Upload and manage payment QR codes
- ✅ Shop information editing
- ✅ User profile management
- ✅ Clean, minimalist interface

### Cross-Platform Support
- ✅ **Web Application**: Runs in any modern browser (Chrome, Firefox, Edge, Safari)
- ✅ **Mobile Apps**: Native Android APK and iOS IPA builds ready
- ✅ **Hybrid Camera**: Web uses HTML5, mobile uses native camera
- ✅ **Responsive Design**: Adapts to all screen sizes (5" phones to 7"+ tablets)
- ✅ Material Design 3 theming
- ✅ Consistent user experience across platforms

## 🛠️ Technical Architecture

### Hybrid Database Architecture

SmartPOS implements a **dual-database architecture** for maximum reliability and performance:

#### Local Database: SQLite (smartpos.db)
- Primary data source for all read operations
- Fast, serverless, and always available
- User-specific data isolation
- Transaction support for data integrity
- Connection timeout: 30 seconds
- Automatic connection cleanup

#### Cloud Database: Supabase (PostgreSQL)
- Secondary data source for cloud sync and backup
- Real-time synchronization capabilities
- Provides data redundancy
- Enables multi-device access
- Remote backup and disaster recovery

#### Write Strategy: Dual-Write Pattern
```
User creates product
    ↓
Write to Local SQLite (fast response)
    ↓
Write to Supabase Cloud (backup)
    ↓
Return success to user
```

#### Read Strategy: Local-First Pattern
```
User requests products
    ↓
Read from Local SQLite (instant)
    ↓
Return data to user
    ↓
(Supabase serves as backup only)
```

#### Benefits
- ✅ **High Availability**: Works even when cloud is down
- ✅ **Fast Performance**: Local reads are instant (<1ms vs 50-200ms)
- ✅ **Data Safety**: Dual storage prevents data loss
- ✅ **Offline Capability**: Full functionality without internet
- ✅ **Cloud Backup**: Automatic cloud synchronization
- ✅ **Multi-Device Ready**: Foundation for future sync features

### Backend Stack

**Framework**: FastAPI (Python 3.8+)
- High-performance async web framework
- Automatic OpenAPI documentation
- Pydantic data validation
- CORS middleware for cross-origin requests

**Database**: Hybrid SQLite + Supabase PostgreSQL
- SQLite for local-first performance
- Supabase for cloud backup and sync
- Automatic dual-write pattern
- Connection pooling and error handling

**API Design**:
- RESTful API architecture
- JWT-based authentication
- Comprehensive error handling and logging
- Automatic inventory updates on sales

**Key Endpoints**:
- `/api/login` - User authentication
- `/api/register` - New user registration
- `/api/products` - Product CRUD operations
- `/api/inventory` - Inventory management
- `/api/sales` - Sales transactions with auto inventory update
- `/api/customers` - Customer management with purchase tracking
- `/api/upload-qr` - UPI QR code upload
- `/users/me` - User profile retrieval

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
- `qr_flutter` - QR code display
- `dart:html` - Web camera access

**Architecture Patterns**:
- Provider pattern for state management
- Repository pattern for API calls
- Model-View-ViewModel (MVVM) structure
- Responsive layout with adaptive widgets

**Special Implementations**:
- **Hybrid Barcode Scanner**: Automatic platform detection
- **DraggableScrollableSheet**: Mobile-optimized checkout
- **Weight Input Dialogs**: Decimal validation for weight products
- **Auto-refresh Navigation**: Dashboard updates after sales

### Database Schema

**Core Tables**:
- **profiles** - User authentication, shop details, UPI QR code
- **products** - Product catalog with unit types and pricing
- **inventory** - Stock levels with decimal support
- **sales** - Transaction records with customer info
- **sale_items** - Line items with decimal quantities
- **customers** - Customer database with purchase tracking
- **categories** - Product categorization

## 📦 Getting Started

### Quick Start (Windows)

**Option 1: PowerShell Launcher (Recommended)**
```powershell
cd "c:\SRI\Sri works\APP project"
.\SmartPOS_Launcher.ps1
```

**Option 2: Batch Launcher**
```cmd
cd "c:\SRI\Sri works\APP project"
SmartPOS_Launcher.bat
```

**What the launcher does**:
1. ✅ Checks Python 3.8+ and Flutter SDK installation
2. ✅ Verifies project directory structure
3. ✅ Installs Python dependencies
4. ✅ Installs Flutter dependencies
5. ✅ Starts backend server on http://127.0.0.1:8001
6. ✅ Starts frontend on http://127.0.0.1:3000
7. ✅ Opens browser automatically
8. ✅ Handles graceful shutdown

### Manual Setup

#### Prerequisites
- Python 3.8 or higher
- Flutter SDK 3.0 or higher
- Modern web browser (Chrome recommended)
- Android Studio (for APK builds)

#### Backend Setup

```bash
cd smartpos/backend
pip install -r requirements.txt
python -m uvicorn simple_fastapi:app --host 0.0.0.0 --port 8001 --reload
```

Verify: http://localhost:8001/docs

#### Frontend Setup

```bash
cd smartpos/frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

Open: http://localhost:3000

### Test Account

**Email**: `void11reaper@gmail.com`  
**Password**: `test12345`

Pre-loaded with sample data:
- 5 products (Laptop, Mouse, Keyboard, Monitor, Headphones)
- 2 customers (John Doe, Jane Smith)
- 1 sample sale transaction

## 📱 Building for Mobile

### Android APK

```bash
cd smartpos/frontend
flutter build apk --release
```

Find APK: `build/app/outputs/flutter-apk/app-release.apk`

**APK Requirements**:
- Android Studio or Android SDK Command-line Tools
- `flutter doctor --android-licenses` (accept licenses)
- Update `android/app/build.gradle` with applicationId
- Generate signing key for production release

**Expected File Sizes**:
- Debug: ~50MB
- Release: ~20MB
- Split per ABI: ~15MB each

### iOS IPA (macOS only)

```bash
cd smartpos/frontend
flutter build ios --release
```

Archive and distribute via Xcode.

## 🎯 Usage Guide

### Daily Operations

**Processing Sales**:
1. Navigate to Billing Management
2. Search or scan products
3. For weight products: Enter weight in dialog (e.g., 2.5 kg)
4. For count products: Use +/- buttons
5. Enter customer name and phone (optional)
6. Select payment method
7. Click "Checkout"
8. Print invoice if needed

**Managing Inventory**:
1. Go to Inventory Management
2. Add/Edit products with decimal stock support
3. Set minimum stock levels for alerts
4. Monitor low stock warnings
5. Automatic deduction after sales

**Customer Management**:
1. Navigate to Customers screen
2. Add new customers with details
3. View purchase count and total spent
4. Track last purchase date
5. Manage credit limits and balances

**Viewing Reports**:
1. Open Reports Management
2. Select tab: Sales, Inventory, or Customers
3. View statistics with dark-themed cards
4. Filter by date range (future)

## 🧹 Project Structure

```
APP project/
├── README.md                          # This comprehensive guide
├── SmartPOS_Launcher.bat              # Windows launcher
├── SmartPOS_Launcher.ps1              # PowerShell launcher
└── smartpos/
    ├── backend/
    │   ├── simple_fastapi.py          # Main API server
    │   ├── database_manager.py        # Hybrid DB manager
    │   ├── supabase_config.py         # Cloud DB config
    │   ├── supabase_helpers.py        # Cloud utilities
    │   ├── supabase_schema_fresh.sql  # Database schema
    │   ├── requirements.txt           # Dependencies
    │   ├── smartpos.db                # Local SQLite
    │   └── uploads/                   # QR code storage
    └── frontend/
        ├── lib/
        │   ├── main.dart              # App entry
        │   ├── config/                # API configuration
        │   ├── models/                # Data models
        │   ├── providers/             # State management
        │   ├── screens/               # UI screens
        │   ├── services/              # API services
        │   ├── widgets/               # Reusable widgets
        │   ├── theme/                 # App theming
        │   └── utils/                 # Utilities
        ├── pubspec.yaml               # Dependencies
        └── build/                     # Compiled output
```

## 🔒 Security Considerations

### Current Implementation
- ✅ JWT-based authentication
- ✅ User-specific data isolation
- ✅ Secure password handling
- ✅ CORS configuration

### Production Recommendations
- [ ] Enable HTTPS/SSL certificates
- [ ] Configure CORS for specific domains only
- [ ] Implement rate limiting
- [ ] Add comprehensive input validation
- [ ] Set up automated database backups
- [ ] Implement session timeout
- [ ] Add API versioning
- [ ] Enable security headers

## 📊 Performance Optimization

- ✅ Local SQLite for instant reads (<1ms)
- ✅ Provider state management for efficient UI updates
- ✅ Image caching with timestamp busting
- ✅ Lazy loading for product lists
- ✅ Debounced search inputs
- ✅ Optimized Flutter production builds
- ✅ Connection pooling and cleanup
- ✅ Automatic navigation refresh

## 🎨 UI/UX Highlights

### Mobile Optimizations
- **DraggableScrollableSheet** for checkout (15%/50%/85% snap points)
- **Responsive Design** for 5" to 7"+ screens
- **Touch-Friendly** buttons and inputs
- **Dark Theme** throughout application

### Desktop/Web Optimizations
- **Large Screen Layouts** with multiple columns
- **Hover States** for better interactivity
- **Keyboard Shortcuts** support (future)
- **Wide Tables** for data display

## 🚀 Future Enhancements

### Planned Features
- [ ] **Multi-Language Support**: Hindi, Tamil, Telugu, Kannada, Malayalam, Bengali, Marathi, Gujarati
- [ ] **Thermal Printer Integration**: Direct receipt printing
- [ ] **PDF Exports**: Invoices and reports
- [ ] **Payment Gateway**: Online payment processing
- [ ] **SMS Notifications**: Customer purchase receipts
- [ ] **Email Reports**: Automated daily/weekly reports
- [ ] **Multi-Store**: Manage multiple locations
- [ ] **Employee Management**: Staff accounts with permissions
- [ ] **Loyalty Program**: Customer rewards system

### Technical Improvements
- [ ] **Offline Sync Queue**: Write operations when offline
- [ ] **Conflict Resolution**: Multi-device edit handling
- [ ] **WebSocket**: Real-time updates
- [ ] **Docker**: Containerized deployment
- [ ] **CI/CD Pipeline**: Automated testing and deployment
- [ ] **Redis Caching**: Performance layer
- [ ] **GraphQL API**: Alternative API option

## 📈 Changelog

### Version 1.2.0 (October 31, 2025)
- ✅ Fixed customer purchase count display issue
- ✅ Removed unnecessary backup and disabled files
- ✅ Consolidated documentation into single README
- ✅ Cleaned up project structure
- ✅ Updated backend to include purchase_count in customer API
- ✅ Improved mobile checkout with draggable sheet
- ✅ Enhanced dashboard with auto-refresh
- ✅ Simplified settings screen
- ✅ Fixed reports dark theme consistency

### Version 1.1.0
- ✅ Implemented DraggableScrollableSheet for mobile
- ✅ Added print functionality to invoices
- ✅ Auto-refresh dashboard after sales
- ✅ Simplified settings UI
- ✅ Dark backgrounds for reports stat cards

### Version 1.0.0
- ✅ Initial production release
- ✅ Complete CRUD for products, sales, customers
- ✅ Hybrid database architecture
- ✅ Barcode scanning support
- ✅ Weight-based product handling
- ✅ Mobile and web deployment

## 📝 Markdown Files in Project

**Total MD Files**: 1

1. **README.md** (Root) - This comprehensive documentation file

**Removed Files** (October 31, 2025):
- ❌ FILE_CLEANUP_SUMMARY.md - Merged into README
- ❌ SCHEMA_FIXES_SUMMARY.md - Merged into README
- ❌ HYBRID_DATABASE_ARCHITECTURE.md - Merged into README

**Rationale**: Single source of truth, easier maintenance, better discoverability

## 🆘 Troubleshooting

### Backend Issues

**Server won't start**:
- Check if port 8001 is in use: `netstat -ano | findstr :8001`
- Verify Python version: `python --version` (need 3.8+)
- Install dependencies: `pip install -r requirements.txt`

**Database locked errors**:
- Close all connections properly
- Increase timeout in database_manager.py
- Restart backend server

### Frontend Issues

**Build fails**:
```bash
flutter clean
flutter pub get
flutter build web
```

**Camera not working (web)**:
- Use HTTPS or localhost
- Check browser permissions
- Try Chrome browser

**Customer purchase count shows 0**:
- Fixed in v1.2.0 - update backend
- Restart backend server
- Refresh frontend

### Common Errors

**"Product not found"**:
- Verify barcode exists
- Check correct user account
- Ensure product is active

**"Insufficient stock"**:
- Check inventory levels
- Add stock before selling
- Verify decimal quantity for weight products

## 📞 Support

<<<<<<< HEAD
**Developer**: Sri  
**Email**: srisu0306@gmail.com  
**GitHub**: Vattsa-11/SmartPOS  
**Repository**: APP-project
=======
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
>>>>>>> 251d276a3c54b03fe0f19f227333c6888d4980cf

---

**Built with**: Flutter 3.35.7 | FastAPI | SQLite + Supabase | Python 3.13  
**Platforms**: Web, Android, iOS  
**License**: Private - All rights reserved

**Status**: ✅ Production Ready | 🚀 Actively Maintained | 📱 Mobile Optimized
