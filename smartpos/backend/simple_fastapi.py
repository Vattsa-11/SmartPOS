#!/usr/bin/env python3
"""
Ultra-simple FastAPI server - No complex dependencies
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware
from database_manager import DatabaseManager
import sqlite3
import json
import os
import shutil
from datetime import datetime

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        print(f"🌐 Incoming request: {request.method} {request.url}")
        try:
            response = await call_next(request)
            print(f"✅ Response status: {response.status_code}")
            return response
        except Exception as e:
            print(f"❌ Error processing request: {e}")
            import traceback
            traceback.print_exc()
            raise

try:
    import bcrypt
    HAS_BCRYPT = True
except ImportError:
    HAS_BCRYPT = False
    print("⚠️ bcrypt not installed, using plain text password comparison")

# Create FastAPI app
app = FastAPI()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Mount uploads directory for static file serving
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Add logging middleware FIRST
app.add_middleware(LoggingMiddleware)

# Add CORS - MUST be before routes
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"]
)

# Simple authentication dependency
# For now, we'll use a header-based auth (user_id in header)
# In production, this should use JWT tokens
from fastapi import Header

async def get_current_user(x_user_id: str = Header(None)):
    """
    Simple user authentication via header.
    Frontend should send user ID in x-user-id header.
    """
    if not x_user_id:
        raise HTTPException(status_code=401, detail="User ID required in x-user-id header")
    
    try:
        user_id = int(x_user_id)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid user ID")
    
    # Verify user exists using Supabase (central auth)
    db = DatabaseManager()
    user = db.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    return {"id": user["id"], "username": user["username"], "email": user["email"]}

@app.get("/")
def root():
    return {"message": "SmartPOS Simple API", "status": "running"}

@app.get("/health")
def health():
    # Test both databases
    db = DatabaseManager(user_id=1)  # Test with user 1
    local_products = len(db.get_products(use_local=True))
    cloud_products = len(db.get_products(use_local=False))
    return {
        "status": "healthy", 
        "local_products": local_products,
        "cloud_products": cloud_products,
        "database": "Hybrid (SQLite + Supabase)"
    }

# Auth endpoints
@app.post("/auth/json-login")
def json_login(credentials: dict):
    """JSON-based login endpoint - Authenticates from Supabase, syncs to local"""
    print(f"🔐 Login attempt with credentials: {credentials}")
    
    # Accept both username and email
    identifier = credentials.get("username") or credentials.get("email", "")
    password = credentials.get("password", "")
    
    if not identifier or not password:
        raise HTTPException(status_code=400, detail="Username/Email and password required")
    
    # Authenticate from Supabase (central authentication)
    db = DatabaseManager()
    user = db.authenticate_user(identifier, password)
    
    if not user:
        print(f"❌ User not found: {identifier}")
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Password verification - check if it's bcrypt hash or plain text
    password_hash = user.get("password_hash", "")
    password_valid = False
    
    if HAS_BCRYPT and password_hash and password_hash.startswith('$2b$'):
        # Bcrypt hash verification
        try:
            password_valid = bcrypt.checkpw(password.encode('utf-8'), password_hash.encode('utf-8'))
        except Exception as e:
            print(f"❌ Bcrypt error: {e}")
            password_valid = False
    else:
        # Plain text comparison (for simple passwords or when bcrypt not available)
        password_valid = (password_hash == password)
    
    if not password_valid:
        print(f"❌ Invalid password for user: {identifier}")
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # ✨ Sync user data from Supabase to local SQLite
    user_db = DatabaseManager(user_id=user['id'])
    sync_success = user_db.sync_user_data_from_cloud()
    
    if sync_success:
        print(f"✅ User data synced to local database")
    else:
        print(f"⚠️ Sync failed, but login proceeding")
    
    # Get user details safely with defaults
    role = user.get("role", "user")
    upi_id = user.get("upi_id")
    upi_qr_url = user.get("upi_qr_url")
    owner_name = user.get("owner_name", user.get("username", ""))
    phone = user.get("phone", "")
    shop_name = user.get("shop_name", "")
    
    print(f"✅ Login successful for user: {user['username']}")
    return {
        "success": True,
        "message": "Login successful",
        "access_token": "dummy-token",  # Add for consistency with frontend expectations
        "user": {
            "id": str(user["id"]),
            "username": user["username"],
            "email": user["email"],
            "owner_name": owner_name,
            "phone": phone,
            "shop_name": shop_name,
            "upi_id": upi_id,
            "upi_qr_url": upi_qr_url,
            "role": role
        }
    }

@app.post("/auth/register")
def register(user_data: dict):
    """Register new user in Supabase profiles table (central registration)"""
    print(f"📝 Registration request: {user_data}")
    
    # Accept both username and email (frontend sends email)
    email = user_data.get("email", "")
    username = user_data.get("username") or email.split('@')[0]  # Use email prefix as username if not provided
    password = user_data.get("password", "")
    
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password required")
    
    # Hash password with bcrypt if available
    if HAS_BCRYPT:
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    else:
        password_hash = password  # Plain text fallback (not recommended for production)
    
    # Create user in Supabase profiles table
    db = DatabaseManager()
    new_user_data = {
        'username': username,
        'password_hash': password_hash,
        'email': email,
        'owner_name': user_data.get("owner_name", ""),
        'shop_name': user_data.get("shop_name", ""),
        'phone': user_data.get("phone", ""),
        'business_type': user_data.get("business_type", "Retail"),
        'currency': user_data.get("currency", "INR"),
        'is_active': True
    }
    
    user = db.create_user(new_user_data)
    
    if not user:
        raise HTTPException(status_code=400, detail="Registration failed. Email or username may already exist.")
    
    print(f"✅ User registered in Supabase: {username} (ID: {user['id']})")
    return {
        "success": True,
        "message": "Registration successful",
        "access_token": "dummy-token",  # Add access_token for consistency
        "user": {
            "id": str(user['id']),
            "username": user['username'],
            "email": user['email'],
            "owner_name": user.get('owner_name', ''),
            "phone": user.get('phone', ''),
            "shop_name": user.get('shop_name', ''),
            "upi_id": user.get('upi_id'),
            "upi_qr_url": user.get('upi_qr_url'),
            "role": user.get('role', 'user')
        }
    }

@app.get("/api/products")
def get_products(current_user: dict = Depends(get_current_user)):
    print(f"📊 Getting products for user {current_user['id']}...")
    try:
        # Use DatabaseManager to get products from local SQLite (fast!)
        db = DatabaseManager(user_id=current_user['id'])
        products = db.get_products(use_local=True)
        
        # Format for API response
        formatted_products = []
        for product in products:
            formatted_products.append({
                "id": product["id"],
                "name": product["name"],
                "barcode": product.get("barcode", ""),
                "price": float(product.get("price", 0)),
                "selling_price": float(product.get("selling_price", 0)),
                "cost_price": float(product.get("cost_price", 0)),
                "current_stock": product.get("current_stock", 0),
                "minimum_stock": product.get("minimum_stock", 0),
                "category": "",
                "category_id": product.get("category_id"),
                "description": product.get("description", ""),
                "created_at": product.get("created_at"),
                "unit": product.get("unit", "pcs"),
                "discount_percentage": float(product.get("discount_percentage", 0)),
                "tax_percentage": float(product.get("tax_percentage", 0)),
                "is_featured": bool(product.get("is_featured", False)),
                "updated_at": product.get("updated_at", product.get("created_at"))
            })
        
        print(f"✅ Returning {len(formatted_products)} products from local DB")
        return formatted_products
    except Exception as e:
        print(f"❌ Error in get_products: {e}")
        import traceback
        traceback.print_exc()
        raise

@app.post("/api/products")
def create_product(product_data: dict, current_user: dict = Depends(get_current_user)):
    print(f"📝 Creating product for user {current_user['id']} with data: {product_data}")
    
    try:
        # Prepare product data
        name = product_data.get("name", "New Product")
        barcode = product_data.get("barcode", f"AUTO-{int(datetime.now().timestamp())}")
        price = float(product_data.get("price", 0))
        selling_price = float(product_data.get("selling_price", price))
        cost_price = float(product_data.get("cost_price", 0))
        category_id = product_data.get("category_id", None)
        description = product_data.get("description", "")
        unit = product_data.get("unit", "pcs")
        discount_percentage = float(product_data.get("discount_percentage", 0))
        tax_percentage = float(product_data.get("tax_percentage", 0))
        is_featured = bool(product_data.get("is_featured", False))
        
        # Initial stock values - support decimals for weight-based products
        initial_stock = float(product_data.get("initial_stock", 0))
        minimum_stock = float(product_data.get("minimum_stock", 5))
        
        print(f"📌 Product: {name}, Price: {price}, Stock: {initial_stock} {unit}")
        
        # Use DatabaseManager to create in BOTH databases
        db = DatabaseManager(user_id=current_user['id'])
        
        product_dict = {
            'name': name,
            'barcode': barcode,
            'price': price,
            'selling_price': selling_price,
            'cost_price': cost_price,
            'category_id': category_id,
            'description': description,
            'unit': unit,
            'discount_percentage': discount_percentage,
            'tax_percentage': tax_percentage,
            'is_featured': is_featured
        }
        
        # Create product in both SQLite and Supabase
        created_product = db.create_product(product_dict, initial_stock, minimum_stock)
        
        if not created_product:
            raise HTTPException(status_code=500, detail="Failed to create product")
        
        # Format response
        result = {
            "id": created_product['id'],
            "name": created_product['name'],
            "barcode": created_product.get('barcode', ''),
            "price": float(created_product.get('price', 0)),
            "selling_price": float(created_product.get('selling_price', 0)),
            "cost_price": float(created_product.get('cost_price', 0)),
            "current_stock": created_product.get('current_stock', 0),
            "stock": created_product.get('current_stock', 0),
            "minimum_stock": created_product.get('minimum_stock', 0),
            "category": "",
            "category_id": created_product.get('category_id'),
            "description": created_product.get('description', ''),
            "created_at": created_product.get('created_at'),
            "unit": created_product.get('unit', 'pcs'),
            "discount_percentage": float(created_product.get('discount_percentage', 0)),
            "tax_percentage": float(created_product.get('tax_percentage', 0)),
            "is_featured": bool(created_product.get('is_featured', False)),
            "updated_at": created_product.get('updated_at', created_product.get('created_at'))
        }
        
        print(f"✅ Created product in BOTH databases - ID {result['id']}: {name}")
        return result
        
    except Exception as e:
        print(f"❌ Error creating product: {e}")
        print(f"❌ Product data received: {product_data}")
        import traceback
        traceback.print_exc()
        raise

@app.put("/api/products/{product_id}")
def update_product(product_id: int, product_data: dict, current_user: dict = Depends(get_current_user)):
    """Update a product"""
    print(f"✏️ Updating product {product_id} for user {current_user['id']}")
    print(f"📦 Product data received: {product_data}")
    
    try:
        conn = sqlite3.connect('smartpos.db')
        cursor = conn.cursor()
        
        # Verify product belongs to user
        cursor.execute("SELECT id FROM products WHERE id = ? AND user_id = ?", (product_id, current_user['id']))
        if not cursor.fetchone():
            conn.close()
            raise HTTPException(status_code=404, detail="Product not found or access denied")
        
        # Update product details
        name = product_data.get("name")
        barcode = product_data.get("barcode")
        price = float(product_data.get("price", 0)) if product_data.get("price") else None
        selling_price = float(product_data.get("selling_price", price)) if product_data.get("selling_price") else price
        cost_price = float(product_data.get("cost_price", 0)) if product_data.get("cost_price") else 0
        description = product_data.get("description", "")
        unit = product_data.get("unit", "pcs")
        updated_at = datetime.now().isoformat()
        
        print(f"📝 Updating: name={name}, barcode={barcode}, price={price}, selling_price={selling_price}")
        
        cursor.execute("""
            UPDATE products
            SET name = ?, barcode = ?, price = ?, selling_price = ?, cost_price = ?,
                description = ?, unit = ?, updated_at = ?
            WHERE id = ? AND user_id = ?
        """, (name, barcode, price, selling_price, cost_price, description, unit, updated_at, product_id, current_user['id']))
        
        rows_affected = cursor.rowcount
        print(f"📊 Rows affected: {rows_affected}")
        
        # Also update inventory if stock data is provided
        if 'initial_stock' in product_data or 'stock' in product_data:
            stock = int(product_data.get('initial_stock') or product_data.get('stock', 0))
            minimum_stock = int(product_data.get('minimum_stock', 0))
            
            print(f"📦 Updating inventory: stock={stock}, min_stock={minimum_stock}")
            
            cursor.execute("""
                UPDATE inventory
                SET current_stock = ?, minimum_stock = ?, updated_at = ?
                WHERE product_id = ?
            """, (stock, minimum_stock, updated_at, product_id))
            
            print(f"📊 Inventory rows affected: {cursor.rowcount}")
        
        conn.commit()
        
        # Fetch the updated product to return
        cursor.execute("""
            SELECT 
                p.id, p.name, p.barcode, p.price, p.selling_price, p.cost_price,
                p.description, p.unit, p.updated_at,
                COALESCE(i.current_stock, 0) as stock,
                COALESCE(i.minimum_stock, 0) as minimum_stock
            FROM products p
            LEFT JOIN inventory i ON p.id = i.product_id
            WHERE p.id = ?
        """, (product_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if row:
            result = {
                "id": row[0],
                "name": row[1],
                "barcode": row[2],
                "price": float(row[3]) if row[3] else 0,
                "sellingPrice": float(row[4]) if row[4] else 0,
                "selling_price": float(row[4]) if row[4] else 0,
                "cost_price": float(row[5]) if row[5] else 0,
                "description": row[6],
                "unit": row[7],
                "updated_at": row[8],
                "stock": row[9],
                "minimum_stock": row[10],
                "minimumStock": row[10]
            }
            print(f"✅ Product {product_id} updated successfully: {result}")
            return result
        else:
            print(f"⚠️ Product {product_id} updated but not found in query")
            return {"id": product_id, "success": True}
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error updating product: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/sales")
def get_sales(current_user: dict = Depends(get_current_user)):
    """Get all sales with items for the current user from local database"""
    print(f"📊 Getting sales for user {current_user['id']}...")
    
    try:
        # Use DatabaseManager to get sales from local database
        db = DatabaseManager(user_id=current_user['id'])
        conn = db._get_local_conn()
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Get all sales for this user
        cursor.execute("""
            SELECT 
                s.id, s.customer_id, s.invoice_number,
                s.subtotal, s.discount_amount, s.tax_amount, s.total_amount,
                s.payment_method, s.payment_status, s.sale_date, s.created_at,
                c.name as customer_name, c.phone as customer_phone
            FROM sales s
            LEFT JOIN customers c ON s.customer_id = c.id
            WHERE s.user_id = ?
            ORDER BY s.id DESC
        """, (current_user['id'],))
        
        sales_rows = cursor.fetchall()
        
        sales = []
        for sale_row in sales_rows:
            sale_id = sale_row["id"]
            
            # Get sale items for this sale
            cursor.execute("""
                SELECT 
                    si.id, si.product_id, si.quantity, si.unit_price, si.total_price,
                    p.name as product_name
                FROM sale_items si
                LEFT JOIN products p ON si.product_id = p.id
                WHERE si.sale_id = ?
            """, (sale_id,))
            
            items_rows = cursor.fetchall()
            items = []
            for item_row in items_rows:
                items.append({
                    "id": item_row["id"],
                    "product_id": item_row["product_id"],
                    "product_name": item_row["product_name"] or "Unknown Product",
                    "quantity": item_row["quantity"],
                    "price": float(item_row["unit_price"]),
                    "total": float(item_row["total_price"])
                })
            
            sales.append({
                "id": sale_id,
                "invoice_number": sale_row["invoice_number"] or f"INV-{sale_id}",
                "total_amount": float(sale_row["total_amount"]),
                "tax_amount": float(sale_row["tax_amount"] or 0),
                "discount_amount": float(sale_row["discount_amount"] or 0),
                "payment_method": sale_row["payment_method"],
                "customer_name": sale_row["customer_name"],
                "customer_phone": sale_row["customer_phone"],
                "sale_date": sale_row["sale_date"] or sale_row["created_at"],
                "created_at": sale_row["created_at"],
                "items": items
            })
        
        conn.close()
        print(f"✅ Returning {len(sales)} sales with items")
        return sales
    except Exception as e:
        print(f"❌ Error getting sales: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/sales")
def create_sale(sale_data: dict, current_user: dict = Depends(get_current_user)):
    """Create a new sale"""
    print(f"💰 Creating sale for user {current_user['id']} with data: {sale_data}")
    
    try:
        conn = sqlite3.connect('smartpos.db')
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        user_id = current_user['id']
        
        # Extract sale information
        invoice_number = sale_data.get('invoice_number', f"INV-{datetime.now().timestamp()}")
        payment_method = sale_data.get('payment_method', 'Cash')
        customer_name = sale_data.get('customer_name')
        customer_phone = sale_data.get('customer_phone')
        subtotal = float(sale_data.get('total_amount', 0))
        tax_amount = float(sale_data.get('tax_amount', 0))
        discount_amount = float(sale_data.get('discount_amount', 0))
        total_amount = subtotal
        
        sale_date = datetime.now().isoformat()
        
        # Find or create customer if details provided
        customer_id = None
        if customer_name and customer_phone:
            # Check if customer exists for this user
            cursor.execute("""
                SELECT id FROM customers WHERE phone = ? AND user_id = ?
            """, (customer_phone, user_id))
            existing_customer = cursor.fetchone()
            
            if existing_customer:
                customer_id = existing_customer["id"]
            else:
                # Create new customer
                cursor.execute("""
                    INSERT INTO customers (
                        user_id, name, phone, email, customer_type,
                        is_active, current_balance, total_purchases, created_at
                    )
                    VALUES (?, ?, ?, '', 'Regular', 1, 0, 0, datetime('now'))
                """, (user_id, customer_name, customer_phone))
                customer_id = cursor.lastrowid
                print(f"✅ Created new customer: {customer_name} (ID: {customer_id})")
        
        # Insert sale
        cursor.execute("""
            INSERT INTO sales (
                user_id, customer_id, invoice_number,
                subtotal, discount_amount, tax_amount, total_amount,
                payment_method, payment_status, paid_amount, change_amount,
                sale_date, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Completed', ?, 0, ?, ?)
        """, (
            user_id, customer_id, invoice_number,
            subtotal, discount_amount, tax_amount, total_amount,
            payment_method, total_amount,
            sale_date, sale_date
        ))
        
        sale_id = cursor.lastrowid
        print(f"✅ Created sale with ID: {sale_id}")
        
        # Insert sale items and update inventory
        items = sale_data.get('items', [])
        for item in items:
            product_id = item.get('product_id')
            quantity = float(item.get('quantity', 1))  # Changed to float to support decimal quantities
            unit_price = float(item.get('price', 0))
            total_price = float(item.get('total', unit_price * quantity))
            
            # Insert sale item
            cursor.execute("""
                INSERT INTO sale_items (
                    sale_id, product_id, quantity,
                    unit_price, discount_amount, tax_amount, total_price,
                    created_at
                )
                VALUES (?, ?, ?, ?, 0, 0, ?, datetime('now'))
            """, (sale_id, product_id, quantity, unit_price, total_price))
            
            # Update inventory - check stock first
            cursor.execute("""
                SELECT current_stock FROM inventory WHERE product_id = ?
            """, (product_id,))
            inventory = cursor.fetchone()
            
            if inventory and inventory["current_stock"] >= quantity:
                cursor.execute("""
                    UPDATE inventory
                    SET current_stock = current_stock - ?,
                        updated_at = datetime('now')
                    WHERE product_id = ?
                """, (quantity, product_id))
                print(f"✅ Updated inventory for product {product_id}: -{quantity}")
            else:
                print(f"⚠️ Warning: Insufficient stock for product {product_id}")
        
        # Update customer total purchases if customer exists
        if customer_id:
            cursor.execute("""
                UPDATE customers
                SET total_purchases = total_purchases + ?,
                    last_purchase_at = datetime('now')
                WHERE id = ?
            """, (total_amount, customer_id))
            
            # Also increment purchase count
            # First check if purchase_count column exists
            cursor.execute("PRAGMA table_info(customers)")
            columns = [row[1] for row in cursor.fetchall()]
            
            if 'purchase_count' in columns:
                cursor.execute("""
                    UPDATE customers
                    SET purchase_count = purchase_count + 1
                    WHERE id = ?
                """, (customer_id,))
            else:
                # Add the column if it doesn't exist
                cursor.execute("ALTER TABLE customers ADD COLUMN purchase_count INTEGER DEFAULT 0")
                cursor.execute("""
                    UPDATE customers
                    SET purchase_count = 1
                    WHERE id = ?
                """, (customer_id,))
        
        conn.commit()
        
        # Return created sale with items
        cursor.execute("""
            SELECT 
                s.id, s.customer_id, s.invoice_number,
                s.subtotal, s.discount_amount, s.tax_amount, s.total_amount,
                s.payment_method, s.payment_status, s.sale_date, s.created_at,
                c.name as customer_name, c.phone as customer_phone
            FROM sales s
            LEFT JOIN customers c ON s.customer_id = c.id
            WHERE s.id = ?
        """, (sale_id,))
        
        sale_row = cursor.fetchone()
        
        # Get sale items
        cursor.execute("""
            SELECT 
                si.id, si.product_id, si.quantity, si.unit_price, si.total_price,
                p.name as product_name
            FROM sale_items si
            LEFT JOIN products p ON si.product_id = p.id
            WHERE si.sale_id = ?
        """, (sale_id,))
        
        items_rows = cursor.fetchall()
        items = []
        for item_row in items_rows:
            items.append({
                "id": item_row["id"],
                "product_id": item_row["product_id"],
                "product_name": item_row["product_name"] or "Unknown Product",
                "quantity": item_row["quantity"],
                "price": float(item_row["unit_price"]),
                "total": float(item_row["total_price"])
            })
        
        result = {
            "id": sale_id,
            "invoice_number": sale_row["invoice_number"],
            "total_amount": float(sale_row["total_amount"]),
            "tax_amount": float(sale_row["tax_amount"] or 0),
            "discount_amount": float(sale_row["discount_amount"] or 0),
            "payment_method": sale_row["payment_method"],
            "customer_name": sale_row["customer_name"],
            "customer_phone": sale_row["customer_phone"],
            "sale_date": sale_row["sale_date"],
            "created_at": sale_row["created_at"],
            "items": items
        }
        
        conn.close()
        print(f"✅ Sale created successfully: {result}")
        return result
        
    except Exception as e:
        print(f"❌ Error creating sale: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/customers")
def get_customers(current_user: dict = Depends(get_current_user)):
    """Get all customers for the current user"""
    print(f"👥 Getting customers for user {current_user['id']}...")
    conn = sqlite3.connect('smartpos.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # First check if purchase_count column exists, add it if not
    cursor.execute("PRAGMA table_info(customers)")
    columns = [row[1] for row in cursor.fetchall()]
    if 'purchase_count' not in columns:
        cursor.execute("ALTER TABLE customers ADD COLUMN purchase_count INTEGER DEFAULT 1")
        conn.commit()
        print("✅ Added purchase_count column to customers table")
    
    cursor.execute("""
        SELECT 
            id, user_id, name, phone, email, address,
            customer_type, credit_limit, current_balance, total_purchases,
            purchase_count, last_purchase_at, is_active, created_at, updated_at
        FROM customers
        WHERE user_id = ?
        ORDER BY id DESC
    """, (current_user['id'],))
    
    rows = cursor.fetchall()
    conn.close()
    
    customers = []
    for row in rows:
        customers.append({
            "id": row["id"],
            "user_id": row["user_id"],
            "name": row["name"],
            "phone": row["phone"] if row["phone"] else None,
            "email": row["email"] if row["email"] else None,
            "address": row["address"] if row["address"] else None,
            "customer_type": row["customer_type"] if row["customer_type"] else "regular",
            "credit_limit": float(row["credit_limit"]) if row["credit_limit"] else 0.0,
            "current_balance": float(row["current_balance"]) if row["current_balance"] else 0.0,
            "total_purchases": float(row["total_purchases"]) if row["total_purchases"] else 0.0,
            "purchase_count": int(row["purchase_count"]) if row["purchase_count"] is not None else 0,
            "last_purchase_at": row["last_purchase_at"] if row["last_purchase_at"] else None,
            "is_active": bool(row["is_active"]) if row["is_active"] is not None else True,
            "created_at": row["created_at"],
            "updated_at": row["updated_at"] if row["updated_at"] else row["created_at"]
        })
    
    print(f"✅ Returning {len(customers)} customers")
    return customers

@app.post("/api/upload-qr")
async def upload_qr(file: UploadFile = File(...), current_user: dict = Depends(get_current_user)):
    """Upload UPI QR code image"""
    user_id = current_user['id']
    print(f"📤 Uploading QR code for user: {user_id}")
    print(f"📎 File details - Name: {file.filename}, Type: {file.content_type}")
    
    conn = None
    try:
        # Validate file type - check both content type and extension
        valid_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        file_ext = os.path.splitext(file.filename)[1].lower() if file.filename else ''
        
        is_valid_type = file.content_type and file.content_type.startswith('image/')
        is_valid_ext = file_ext in valid_extensions
        
        if not (is_valid_type or is_valid_ext):
            print(f"❌ Invalid file - Type: {file.content_type}, Extension: {file_ext}")
            raise HTTPException(
                status_code=400, 
                detail=f"File must be an image (jpg, png, gif, etc.). Got type: {file.content_type}, extension: {file_ext}"
            )
        
        # Get DatabaseManager for the user
        db = DatabaseManager(user_id=user_id)
        conn = db._get_local_conn()
        cursor = conn.cursor()
        
        # Create unique filename
        file_extension = file.filename.split('.')[-1]
        new_filename = f"qr_{user_id}_{datetime.now().timestamp()}.{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, new_filename)
        
        # Save file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Update user's UPI QR URL in database
        qr_url = f"/uploads/{new_filename}"
        print(f"💾 Saving QR URL to database: {qr_url} for user {user_id}")
        
        # Update in local SQLite profiles table
        cursor.execute("""
            UPDATE profiles
            SET upi_qr_url = ?
            WHERE id = ?
        """, (qr_url, user_id))
        
        rows_updated = cursor.rowcount
        conn.commit()
        conn.close()
        conn = None  # Mark as closed
        
        # Also update in Supabase - use upi_qr_code instead of upi_qr_url
        try:
            db.supabase.table('profiles').update({
                'upi_qr_code': qr_url  # Note: column is upi_qr_code in Supabase
            }).eq('id', user_id).execute()
            print(f"✅ QR URL synced to Supabase")
        except Exception as e:
            print(f"⚠️ Failed to sync QR to Supabase: {e}")
        
        print(f"📊 Rows updated: {rows_updated}")
        print(f"✅ QR code uploaded successfully: {qr_url}")
        
        return {
            "success": True,
            "message": "QR code uploaded successfully",
            "upi_qr_url": qr_url
        }
        
    except Exception as e:
        print(f"❌ Error uploading QR code: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

@app.get("/users/me")
def get_current_user_profile(current_user: dict = Depends(get_current_user)):
    """Get current user's profile with latest data"""
    print(f"👤 Getting profile for user {current_user['id']}...")
    
    # Use DatabaseManager to query profiles table (hybrid DB)
    db = DatabaseManager(user_id=current_user['id'])
    conn = db._get_local_conn()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Query profiles table (not users)
    cursor.execute("SELECT * FROM profiles WHERE id = ?", (current_user['id'],))
    user = cursor.fetchone()
    conn.close()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get fields safely
    try:
        role = user["role"] if "role" in user.keys() else "user"
        upi_id = user["upi_id"] if "upi_id" in user.keys() else None
        upi_qr_url = user["upi_qr_url"] if "upi_qr_url" in user.keys() else None
        owner_name = user["owner_name"] if "owner_name" in user.keys() else user["username"]
        phone = user["phone"] if "phone" in user.keys() else ""
        shop_name = user["shop_name"] if "shop_name" in user.keys() else ""
    except:
        role = "user"
        upi_id = None
        upi_qr_url = None
        owner_name = user["username"]
        phone = ""
        shop_name = ""
    
    result = {
        "id": str(user["id"]),
        "username": user["username"],
        "email": user["email"],
        "owner_name": owner_name,
        "phone": phone,
        "shop_name": shop_name,
        "upi_id": upi_id,
        "upi_qr_url": upi_qr_url,
        "role": role
    }
    
    print(f"✅ Returning user profile with QR URL: {upi_qr_url}")
    return result

@app.put("/users/{user_id}/upi-settings")
def update_upi_settings(user_id: int, data: dict, current_user: dict = Depends(get_current_user)):
    """Update UPI settings for user"""
    print(f"💳 Updating UPI settings for user {user_id}: {data}")
    
    # Verify user is updating their own settings
    if current_user['id'] != user_id:
        raise HTTPException(status_code=403, detail="Cannot update other user's settings")
    
    conn = None
    try:
        # Use DatabaseManager for hybrid DB
        db = DatabaseManager(user_id=user_id)
        conn = db._get_local_conn()
        cursor = conn.cursor()
        
        upi_id = data.get('upi_id', '')
        
        # Update in local SQLite profiles table
        cursor.execute("""
            UPDATE profiles
            SET upi_id = ?
            WHERE id = ?
        """, (upi_id, user_id))
        
        conn.commit()
        conn.close()
        conn = None  # Mark as closed
        
        # Also update in Supabase
        try:
            db.supabase.table('profiles').update({
                'upi_id': upi_id
            }).eq('id', user_id).execute()
            print(f"✅ UPI ID synced to Supabase")
        except Exception as e:
            print(f"⚠️ Failed to sync UPI to Supabase: {e}")
        
        print(f"✅ UPI settings updated successfully")
        return {
            "success": True,
            "message": "UPI settings updated successfully"
        }
        
    except Exception as e:
        print(f"❌ Error updating UPI settings: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

@app.post("/api/update-upi")
def update_upi(data: dict):
    """Update UPI ID for user"""
    print(f"💳 Updating UPI ID: {data}")
    
    try:
        user_id = data.get('user_id')
        upi_id = data.get('upi_id', '')
        
        # Use DatabaseManager for hybrid DB
        db = DatabaseManager(user_id=user_id if user_id else 1)
        conn = db._get_local_conn()
        cursor = conn.cursor()
        
        if not user_id:
            # Get first user from profiles table
            cursor.execute("SELECT id FROM profiles LIMIT 1")
            user_result = cursor.fetchone()
            if not user_result:
                conn.close()
                raise HTTPException(status_code=400, detail="No user found")
            user_id = user_result[0]
        
        # Update in local SQLite profiles table
        cursor.execute("""
            UPDATE profiles
            SET upi_id = ?
            WHERE id = ?
        """, (upi_id, user_id))
        
        conn.commit()
        
        # Also update in Supabase
        try:
            db.supabase.table('profiles').update({
                'upi_id': upi_id
            }).eq('id', user_id).execute()
            print(f"✅ UPI ID synced to Supabase")
        except Exception as e:
            print(f"⚠️ Failed to sync UPI to Supabase: {e}")
        
        conn.close()
        
        print(f"✅ UPI ID updated successfully")
        return {
            "success": True,
            "message": "UPI ID updated successfully"
        }
        
    except Exception as e:
        print(f"❌ Error updating UPI ID: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/inventory")
def get_inventory(current_user: dict = Depends(get_current_user)):
    """Get inventory with stock information for the current user"""
    print(f"📦 Getting inventory for user {current_user['id']}...")
    conn = sqlite3.connect('smartpos.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT 
            p.id, p.name, p.barcode, p.price, p.selling_price, p.cost_price,
            p.category_id, p.created_at, p.unit, p.discount_percentage,
            p.tax_percentage, p.is_featured, p.updated_at, p.description,
            COALESCE(i.current_stock, 0) as current_stock,
            COALESCE(i.minimum_stock, 0) as minimum_stock
        FROM products p
        LEFT JOIN inventory i ON p.id = i.product_id
        WHERE p.user_id = ?
        ORDER BY p.id DESC
    """, (current_user['id'],))
    
    rows = cursor.fetchall()
    conn.close()
    
    products = []
    for row in rows:
        products.append({
            "id": row["id"],
            "name": row["name"],
            "barcode": row["barcode"] if row["barcode"] else "",
            "price": float(row["price"]) if row["price"] else 0.0,
            "selling_price": float(row["selling_price"]) if row["selling_price"] else 0.0,
            "cost_price": float(row["cost_price"]) if row["cost_price"] else 0.0,
            "current_stock": row["current_stock"],
            "stock": row["current_stock"],
            "minimum_stock": row["minimum_stock"],
            "category": "",
            "category_id": row["category_id"] if row["category_id"] else None,
            "description": row["description"] if row["description"] else "",
            "created_at": row["created_at"],
            "unit": row["unit"] if row["unit"] else "pcs",
            "discount_percentage": float(row["discount_percentage"]) if row["discount_percentage"] else 0.0,
            "tax_percentage": float(row["tax_percentage"]) if row["tax_percentage"] else 0.0,
            "is_featured": bool(row["is_featured"]) if row["is_featured"] else False,
            "updated_at": row["created_at"]
        })
    
    print(f"✅ Returning {len(products)} inventory items")
    return products

@app.put("/api/inventory/{product_id}")
def update_inventory(product_id: int, update_data: dict, current_user: dict = Depends(get_current_user)):
    """Update inventory stock for a product"""
    print(f"📝 Updating inventory for product {product_id} by user {current_user['id']} with data: {update_data}")
    
    try:
        conn = sqlite3.connect('smartpos.db')
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Check if product exists and belongs to the user
        cursor.execute("SELECT id FROM products WHERE id = ? AND user_id = ?", (product_id, current_user['id']))
        product = cursor.fetchone()
        
        if not product:
            conn.close()
            print(f"❌ Product {product_id} not found or doesn't belong to user")
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Check if inventory record exists
        cursor.execute("SELECT id, current_stock FROM inventory WHERE product_id = ?", (product_id,))
        inventory = cursor.fetchone()
        
        # Get the new stock value from update_data
        new_stock = update_data.get('stock')
        
        if new_stock is None:
            conn.close()
            print(f"❌ No stock value provided")
            raise HTTPException(status_code=400, detail="Stock value required")
        
        new_stock = int(new_stock)
        
        if new_stock < 0:
            conn.close()
            print(f"❌ Stock cannot be negative")
            raise HTTPException(status_code=400, detail="Stock cannot be negative")
        
        updated_at = datetime.now().isoformat()
        
        if inventory:
            # Update existing inventory
            old_stock = inventory["current_stock"]
            cursor.execute("""
                UPDATE inventory 
                SET current_stock = ?, updated_at = ?
                WHERE product_id = ?
            """, (new_stock, updated_at, product_id))
            print(f"✅ Updated inventory for product {product_id}: {old_stock} → {new_stock}")
        else:
            # Create new inventory record
            minimum_stock = update_data.get('minimum_stock', 5)
            cursor.execute("""
                INSERT INTO inventory (product_id, current_stock, minimum_stock, updated_at)
                VALUES (?, ?, ?, ?)
            """, (product_id, new_stock, minimum_stock, updated_at))
            print(f"✅ Created inventory for product {product_id} with stock: {new_stock}")
        
        conn.commit()
        
        # Return updated product with inventory info
        cursor.execute("""
            SELECT 
                p.id, p.name, p.barcode, p.price, p.selling_price, p.cost_price,
                p.category_id, p.created_at, p.unit, p.discount_percentage,
                p.tax_percentage, p.is_featured, p.updated_at, p.description,
                COALESCE(i.current_stock, 0) as current_stock,
                COALESCE(i.minimum_stock, 0) as minimum_stock
            FROM products p
            LEFT JOIN inventory i ON p.id = i.product_id
            WHERE p.id = ?
        """, (product_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            raise HTTPException(status_code=404, detail="Product not found after update")
        
        result = {
            "id": row["id"],
            "name": row["name"],
            "barcode": row["barcode"] if row["barcode"] else "",
            "price": float(row["price"]) if row["price"] else 0.0,
            "selling_price": float(row["selling_price"]) if row["selling_price"] else 0.0,
            "cost_price": float(row["cost_price"]) if row["cost_price"] else 0.0,
            "current_stock": row["current_stock"],
            "stock": row["current_stock"],
            "minimum_stock": row["minimum_stock"],
            "category": "",
            "category_id": row["category_id"] if row["category_id"] else None,
            "description": row["description"] if row["description"] else "",
            "created_at": row["created_at"],
            "unit": row["unit"] if row["unit"] else "pcs",
            "discount_percentage": float(row["discount_percentage"]) if row["discount_percentage"] else 0.0,
            "tax_percentage": float(row["tax_percentage"]) if row["tax_percentage"] else 0.0,
            "is_featured": bool(row["is_featured"]) if row["is_featured"] else False,
            "updated_at": updated_at
        }
        
        print(f"✅ Inventory updated successfully for product {product_id}")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error updating inventory: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
