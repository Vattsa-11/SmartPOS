# SmartPOS - Point of Sale System

A complete POS (Point of Sale) system with mobile and web support built with Flutter frontend and FastAPI backend. This application provides comprehensive product management, inventory tracking, and user-specific data isolation for retail businesses.

## Current Features

###  User Management
- **Authentication System**: JWT-based authentication with secure token handling
- **Multi-User Support**: Each user has their own isolated database and product catalog
- **Registration & Login**: Complete user registration and login flow
- **Profile Management**: User profile management with shop details

###  Product Management
- **Complete CRUD Operations**: Create, Read, Update, Delete products
- **Rich Product Data**: Name, barcode, pricing (cost, selling, discount), inventory levels
- **Inventory Tracking**: Real-time stock monitoring with minimum/maximum levels
- **Product Categories**: Organize products by categories
- **Featured Products**: Mark products as featured for quick access
- **Tax & Discount Management**: Built-in tax and discount percentage calculations

###  Inventory System
- **Stock Management**: Track current stock, minimum stock levels, and maximum capacity
- **Low Stock Alerts**: Automatic alerts when products fall below minimum stock
- **Inventory Adjustments**: Track inventory changes with reason codes
- **Stock History**: Complete audit trail of inventory movements

###  Sales & Transactions
- **Point of Sale**: Complete sales transaction processing
- **Multiple Payment Methods**: Cash, Card, UPI, Credit, Bank Transfer
- **Invoice Generation**: Automatic invoice number generation
- **Receipt Management**: Digital receipts with complete transaction details
- **Payment Tracking**: Track partial payments and change calculations

###  Dashboard & Analytics
- **Real-time Statistics**: Today's sales, monthly sales, customer count
- **Product Analytics**: Track top-selling products and performance
- **Inventory Alerts**: Dashboard alerts for low stock items
- **Recent Transactions**: Quick view of recent sales

###  Web & Mobile Support
- **Flutter Web**: Responsive web application for desktop use
- **Mobile Ready**: Native mobile app experience
- **Cross-Platform**: Single codebase for web, Android, and iOS
- **Material Design**: Modern, intuitive user interface

## Technical Architecture

### Backend (FastAPI + SQLAlchemy)
- **FastAPI Framework**: High-performance, modern Python web framework
- **SQLite Database**: Lightweight, serverless database for each user
- **SQLAlchemy ORM**: Robust database modeling and relationships
- **Pydantic Schemas**: Type-safe API request/response validation
- **JWT Authentication**: Secure token-based authentication
- **CORS Enabled**: Cross-origin resource sharing for web deployment

### Frontend (Flutter)
- **Flutter Framework**: Google's UI toolkit for cross-platform development
- **Provider State Management**: Reactive state management for UI updates
- **HTTP Client**: RESTful API communication with backend
- **Material Design**: Google's design system implementation
- **Responsive Layout**: Adaptive UI for different screen sizes
- **Internationalization**: Multi-language support (English, Hindi)

## Database Schema

### Users Table
- User authentication and profile information
- Shop details and contact information
- Supabase integration for external auth

### Products Table
- Complete product information with pricing
- User-specific product catalogs
- Category relationships and featured status

### Inventory Table
- Real-time stock levels
- Minimum/maximum stock thresholds
- Product relationship mapping

### Sales & Transactions
- Complete sales records with line items
- Payment method and status tracking
- Customer information and receipt data

## Getting Started

### Prerequisites
- Python 3.8+ with pip
- Flutter SDK 3.0+
- Git for version control

### Backend Setup

1. **Navigate to backend directory:**
```bash
cd smartpos/backend
```

2. **Create virtual environment:**
```bash
python -m venv venv
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate
```

3. **Install dependencies:**
```bash
pip install -r requirements.txt
```

4. **Start the development server:**
```bash
# Main API (port 8000)
python main.py

# Or simplified API (port 8001)
python simple_api.py
```

5. **Access API documentation:**
- Main API: http://127.0.0.1:8000/docs
- Simple API: http://127.0.0.1:8001/docs

### Frontend Setup

1. **Navigate to frontend directory:**
```bash
cd smartpos/frontend
```

2. **Install Flutter dependencies:**
```bash
flutter pub get
```

3. **Run the application:**
```bash
# Web development
flutter run -d chrome

# Android device/emulator
flutter run -d android

# iOS device/simulator (Mac only)
flutter run -d ios
```

## API Endpoints

### Authentication
- `POST /api/login` - User login with email/password
- `POST /api/register` - User registration

### Product Management
- `GET /api/products` - List all products for authenticated user
- `POST /api/products` - Create new product
- `PUT /api/products/{id}` - Update existing product
- `DELETE /api/products/{id}` - Delete product (soft delete)

### Inventory Management
- `GET /api/inventory` - Get inventory levels for all products
- `PUT /api/inventory/{product_id}` - Update inventory levels

### Sales & Transactions
- `POST /sales` - Create new sale transaction
- `GET /sales` - List sales with filtering options
- `GET /sales/{id}` - Get specific sale details

### Dashboard
- `GET /dashboard` - Get dashboard statistics and analytics

## User Guide

### First Time Setup
1. **Register**: Create your account with email and shop details
2. **Login**: Access your personal dashboard
3. **Add Products**: Start building your product catalog
4. **Set Inventory**: Configure stock levels and alerts
5. **Start Selling**: Process sales transactions

### Daily Operations
1. **Check Dashboard**: Review daily sales and alerts
2. **Manage Inventory**: Update stock levels as needed
3. **Process Sales**: Handle customer transactions
4. **Monitor Alerts**: Address low stock warnings

## Development Notes

### Current Architecture Decisions
- **User Isolation**: Each user operates with their own data scope
- **Simple Authentication**: Development-friendly auth flow
- **Flexible API**: Both full-featured and simplified API endpoints
- **Database Per User**: SQLite provides user-specific data isolation

### Known Limitations
- Single-tenant architecture (not multi-tenant database)
- Development-mode authentication (simplified for testing)
- Basic receipt system (no printing integration yet)

## Future Roadmap

### Planned Features
- **Barcode Scanning**: Camera-based barcode recognition
- **Receipt Printing**: Thermal printer integration
- **Advanced Analytics**: Sales trends, profit analysis
- **Customer Management**: Customer database and loyalty
- **Multi-Store Support**: Chain store management
- **Offline Capability**: Work without internet connection
- **Cloud Backup**: Data synchronization and backup
- **Mobile Payment Integration**: Payment gateway APIs

### Technical Improvements
- **Multi-tenant Database**: Shared database with tenant isolation
- **Advanced Authentication**: OAuth2, social login
- **Caching Layer**: Redis for performance optimization
- **API Rate Limiting**: Request throttling and quotas
- **Automated Testing**: Unit and integration test suites
- **Docker Deployment**: Containerized deployment
- **Cloud Hosting**: AWS/Azure deployment configurations

## Contributing

This is a private development project. For questions or collaboration, please contact the development team.

## License

Private project - All rights reserved.
