"""
Hybrid Database Manager - SQLite + Supabase
============================================
- Local SQLite: Fast, offline-first, user-specific data
- Supabase: Cloud backup, sync across devices, all users' data
"""

import sqlite3
from supabase_config import supabase
from datetime import datetime
from typing import Dict, List, Optional, Any
import json

class DatabaseManager:
    def __init__(self, user_id: int = None):
        """
        Initialize database manager for a specific user
        
        Args:
            user_id: The user ID for filtering data (None for multi-user operations)
        """
        self.user_id = user_id
        self.local_db = 'smartpos.db'
        self.supabase = supabase
        self._ensure_local_tables()
    
    def _ensure_local_tables(self):
        """Ensure all required tables exist in local SQLite database"""
        conn = self._get_local_conn()
        cursor = conn.cursor()
        
        # Create profiles table if it doesn't exist (mirrors Supabase profiles)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS profiles (
                id INTEGER PRIMARY KEY,
                username TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                role TEXT DEFAULT 'user',
                owner_name TEXT,
                shop_name TEXT,
                phone TEXT,
                address TEXT,
                business_type TEXT,
                currency TEXT DEFAULT 'INR',
                upi_id TEXT,
                upi_qr_url TEXT,
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        conn.commit()
        conn.close()
    
    def _get_local_conn(self):
        """Get local SQLite connection with timeout"""
        conn = sqlite3.connect(self.local_db, timeout=10.0)
        conn.row_factory = sqlite3.Row
        return conn
    
    # ==================== USER OPERATIONS ====================
    
    def authenticate_user(self, identifier: str, password_hash: str) -> Optional[Dict]:
        """
        Authenticate user from Supabase (central auth)
        
        Args:
            identifier: Username or email
            password_hash: Password to verify
        
        Returns:
            User dict if authenticated, None otherwise
        """
        try:
            # Check Supabase profiles table for user
            result = supabase.table('profiles').select('*').or_(
                f'username.eq.{identifier},email.eq.{identifier}'
            ).execute()
            
            if result.data and len(result.data) > 0:
                return result.data[0]
            
            return None
        except Exception as e:
            print(f"❌ Auth error: {e}")
            return None
    
    def create_user(self, user_data: Dict) -> Optional[Dict]:
        """
        Create user in Supabase profiles table (central registration)
        
        Args:
            user_data: User details (username, email, password_hash, etc.)
        
        Returns:
            Created user dict or None
        """
        try:
            user_data['created_at'] = datetime.now().isoformat()
            result = supabase.table('profiles').insert(user_data).execute()
            
            if result.data and len(result.data) > 0:
                return result.data[0]
            
            return None
        except Exception as e:
            print(f"❌ User creation error: {e}")
            return None
    
    def get_user_by_id(self, user_id: int) -> Optional[Dict]:
        """Get user by ID from Supabase profiles table"""
        try:
            result = supabase.table('profiles').select('*').eq('id', user_id).execute()
            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            print(f"❌ Get user error: {e}")
            return None
    
    def update_user(self, user_id: int, updates: Dict) -> Optional[Dict]:
        """Update user in Supabase profiles table"""
        try:
            updates['updated_at'] = datetime.now().isoformat()
            result = supabase.table('profiles').update(updates).eq('id', user_id).execute()
            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            print(f"❌ Update user error: {e}")
            return None
    
    # ==================== PRODUCT OPERATIONS ====================
    
    def get_products(self, use_local: bool = True) -> List[Dict]:
        """
        Get products for current user
        
        Args:
            use_local: If True, get from local SQLite; if False, get from Supabase
        
        Returns:
            List of products with inventory data
        """
        if not self.user_id:
            raise ValueError("user_id required for product operations")
        
        try:
            if use_local:
                # Get from local SQLite
                conn = self._get_local_conn()
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
                """, (self.user_id,))
                
                rows = cursor.fetchall()
                conn.close()
                
                products = [dict(row) for row in rows]
            else:
                # Get from Supabase
                products_result = supabase.table('products').select('*').eq('user_id', self.user_id).execute()
                
                if not products_result.data:
                    return []
                
                products = []
                for product in products_result.data:
                    # Get inventory for each product
                    inventory_result = supabase.table('inventory').select('*').eq('product_id', product['id']).execute()
                    
                    if inventory_result.data and len(inventory_result.data) > 0:
                        inventory = inventory_result.data[0]
                        product['current_stock'] = inventory.get('current_stock', 0)
                        product['minimum_stock'] = inventory.get('minimum_stock', 0)
                    else:
                        product['current_stock'] = 0
                        product['minimum_stock'] = 0
                    
                    products.append(product)
            
            return products
        
        except Exception as e:
            print(f"❌ Get products error: {e}")
            return []
    
    def get_product_by_barcode(self, barcode: str, use_local: bool = True) -> Optional[Dict]:
        """Get product by barcode"""
        if not self.user_id:
            raise ValueError("user_id required")
        
        try:
            if use_local:
                conn = self._get_local_conn()
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT 
                        p.*,
                        COALESCE(i.current_stock, 0) as current_stock,
                        COALESCE(i.minimum_stock, 0) as minimum_stock
                    FROM products p
                    LEFT JOIN inventory i ON p.id = i.product_id
                    WHERE p.barcode = ? AND p.user_id = ?
                """, (barcode, self.user_id))
                
                row = cursor.fetchone()
                conn.close()
                
                return dict(row) if row else None
            else:
                # Get from Supabase
                result = supabase.table('products').select('*').eq('barcode', barcode).eq('user_id', self.user_id).execute()
                
                if not result.data or len(result.data) == 0:
                    return None
                
                product = result.data[0]
                
                # Get inventory
                inventory_result = supabase.table('inventory').select('*').eq('product_id', product['id']).execute()
                if inventory_result.data and len(inventory_result.data) > 0:
                    product['current_stock'] = inventory_result.data[0].get('current_stock', 0)
                    product['minimum_stock'] = inventory_result.data[0].get('minimum_stock', 0)
                
                return product
        
        except Exception as e:
            print(f"❌ Get product by barcode error: {e}")
            return None
    
    def create_product(self, product_data: Dict, initial_stock: float = 0, minimum_stock: float = 0) -> Optional[Dict]:
        """
        Create product in BOTH local SQLite and Supabase
        
        Args:
            product_data: Product details
            initial_stock: Initial inventory quantity
            minimum_stock: Minimum stock level
        
        Returns:
            Created product dict or None
        """
        if not self.user_id:
            raise ValueError("user_id required")
        
        product_data['user_id'] = self.user_id
        product_data['created_at'] = datetime.now().isoformat()
        
        try:
            # 1. Create in Supabase first (to get consistent ID)
            supabase_result = supabase.table('products').insert(product_data).execute()
            
            if not supabase_result.data or len(supabase_result.data) == 0:
                print("❌ Failed to create product in Supabase")
                return None
            
            product = supabase_result.data[0]
            product_id = product['id']
            
            # 2. Create inventory in Supabase
            inventory_data = {
                'product_id': product_id,
                'current_stock': initial_stock,
                'minimum_stock': minimum_stock,
                'maximum_stock': 1000,
                'updated_at': datetime.now().isoformat()
            }
            supabase.table('inventory').insert(inventory_data).execute()
            
            # 3. Create in local SQLite (use INSERT OR REPLACE to handle duplicates)
            conn = self._get_local_conn()
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT OR REPLACE INTO products (
                    id, user_id, name, barcode, price, selling_price, cost_price,
                    category_id, unit, discount_percentage, tax_percentage,
                    is_featured, description, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                product_id, self.user_id, product_data.get('name'),
                product_data.get('barcode'), product_data.get('price'),
                product_data.get('selling_price'), product_data.get('cost_price'),
                product_data.get('category_id'), product_data.get('unit', 'pcs'),
                product_data.get('discount_percentage', 0), product_data.get('tax_percentage', 0),
                product_data.get('is_featured', 0), product_data.get('description'),
                product_data['created_at']
            ))
            
            # 4. Create inventory in local SQLite (use INSERT OR REPLACE)
            cursor.execute("""
                INSERT OR REPLACE INTO inventory (product_id, current_stock, minimum_stock, maximum_stock, updated_at)
                VALUES (?, ?, ?, ?, ?)
            """, (product_id, initial_stock, minimum_stock, 1000, datetime.now().isoformat()))
            
            conn.commit()
            conn.close()
            
            product['current_stock'] = initial_stock
            product['minimum_stock'] = minimum_stock
            
            print(f"✅ Product created in both databases: {product_data.get('name')}")
            return product
        
        except Exception as e:
            print(f"❌ Create product error: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def update_product(self, product_id: int, product_data: Dict, stock: float = None, minimum_stock: float = None) -> Optional[Dict]:
        """Update product in BOTH databases"""
        if not self.user_id:
            raise ValueError("user_id required")
        
        try:
            # 1. Update in Supabase
            update_data = {k: v for k, v in product_data.items() if v is not None}
            update_data['updated_at'] = datetime.now().isoformat()
            
            supabase_result = supabase.table('products').update(update_data).eq('id', product_id).eq('user_id', self.user_id).execute()
            
            if not supabase_result.data or len(supabase_result.data) == 0:
                return None
            
            # 2. Update inventory in Supabase if stock provided
            if stock is not None or minimum_stock is not None:
                inventory_update = {'updated_at': datetime.now().isoformat()}
                if stock is not None:
                    inventory_update['current_stock'] = stock
                if minimum_stock is not None:
                    inventory_update['minimum_stock'] = minimum_stock
                
                supabase.table('inventory').update(inventory_update).eq('product_id', product_id).execute()
            
            # 3. Update in local SQLite
            conn = self._get_local_conn()
            cursor = conn.cursor()
            
            # Build dynamic UPDATE query
            set_clauses = []
            values = []
            for key, value in update_data.items():
                if key != 'user_id':  # Don't update user_id
                    set_clauses.append(f"{key} = ?")
                    values.append(value)
            
            if set_clauses:
                values.extend([product_id, self.user_id])
                cursor.execute(f"""
                    UPDATE products 
                    SET {', '.join(set_clauses)}
                    WHERE id = ? AND user_id = ?
                """, values)
            
            # 4. Update inventory in local SQLite
            if stock is not None or minimum_stock is not None:
                inv_set = []
                inv_values = []
                if stock is not None:
                    inv_set.append("current_stock = ?")
                    inv_values.append(stock)
                if minimum_stock is not None:
                    inv_set.append("minimum_stock = ?")
                    inv_values.append(minimum_stock)
                inv_set.append("updated_at = ?")
                inv_values.append(datetime.now().isoformat())
                inv_values.append(product_id)
                
                cursor.execute(f"""
                    UPDATE inventory 
                    SET {', '.join(inv_set)}
                    WHERE product_id = ?
                """, inv_values)
            
            conn.commit()
            conn.close()
            
            print(f"✅ Product updated in both databases: {product_id}")
            return supabase_result.data[0]
        
        except Exception as e:
            print(f"❌ Update product error: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def update_inventory_stock(self, product_id: int, stock_change: float) -> bool:
        """
        Update inventory stock in BOTH databases
        
        Args:
            product_id: Product ID
            stock_change: Amount to add (positive) or subtract (negative)
        
        Returns:
            True if successful, False otherwise
        """
        try:
            # 1. Get current stock from local
            conn = self._get_local_conn()
            cursor = conn.cursor()
            cursor.execute("SELECT current_stock FROM inventory WHERE product_id = ?", (product_id,))
            row = cursor.fetchone()
            
            if not row:
                conn.close()
                return False
            
            current_stock = row['current_stock']
            new_stock = current_stock + stock_change
            
            if new_stock < 0:
                conn.close()
                return False
            
            # 2. Update Supabase
            supabase.table('inventory').update({
                'current_stock': new_stock,
                'updated_at': datetime.now().isoformat()
            }).eq('product_id', product_id).execute()
            
            # 3. Update local SQLite
            cursor.execute("""
                UPDATE inventory 
                SET current_stock = ?, updated_at = ?
                WHERE product_id = ?
            """, (new_stock, datetime.now().isoformat(), product_id))
            
            conn.commit()
            conn.close()
            
            print(f"✅ Inventory updated in both databases: Product {product_id}, Change {stock_change}, New stock {new_stock}")
            return True
        
        except Exception as e:
            print(f"❌ Update inventory error: {e}")
            return False
    
    # ==================== SALES OPERATIONS ====================
    
    def create_sale(self, sale_data: Dict, items: List[Dict]) -> Optional[Dict]:
        """
        Create sale in BOTH databases and update inventory
        
        Args:
            sale_data: Sale details (total_amount, payment_method, etc.)
            items: List of sale items (product_id, quantity, price, total)
        
        Returns:
            Created sale dict or None
        """
        if not self.user_id:
            raise ValueError("user_id required")
        
        sale_data['user_id'] = self.user_id
        sale_data['created_at'] = datetime.now().isoformat()
        
        try:
            # 1. Create sale in Supabase
            supabase_result = supabase.table('sales').insert(sale_data).execute()
            
            if not supabase_result.data or len(supabase_result.data) == 0:
                return None
            
            sale = supabase_result.data[0]
            sale_id = sale['id']
            
            # 2. Create sale in local SQLite
            conn = self._get_local_conn()
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO sales (
                    id, user_id, invoice_number, total_amount, tax_amount, discount_amount,
                    payment_method, customer_name, customer_phone, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                sale_id, self.user_id, sale_data.get('invoice_number'),
                sale_data.get('total_amount'), sale_data.get('tax_amount', 0),
                sale_data.get('discount_amount', 0), sale_data.get('payment_method', 'cash'),
                sale_data.get('customer_name'), sale_data.get('customer_phone'),
                sale_data['created_at']
            ))
            
            # 3. Create sale items and update inventory
            for item in items:
                item_data = {
                    'sale_id': sale_id,
                    'product_id': item['product_id'],
                    'quantity': item['quantity'],
                    'unit_price': item['price'],
                    'total_price': item['total'],
                    'created_at': datetime.now().isoformat()
                }
                
                # Insert in Supabase
                supabase.table('sale_items').insert(item_data).execute()
                
                # Insert in local SQLite
                cursor.execute("""
                    INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, total_price, created_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (sale_id, item['product_id'], item['quantity'], item['price'], item['total'], item_data['created_at']))
                
                # Update inventory (subtract quantity) in BOTH databases
                self.update_inventory_stock(item['product_id'], -item['quantity'])
            
            conn.commit()
            conn.close()
            
            # Get sale items for response
            items_result = supabase.table('sale_items').select('*').eq('sale_id', sale_id).execute()
            sale['items'] = items_result.data if items_result.data else []
            
            print(f"✅ Sale created in both databases: Invoice {sale_data.get('invoice_number')}")
            return sale
        
        except Exception as e:
            print(f"❌ Create sale error: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def get_sales(self, use_local: bool = True, limit: int = 100) -> List[Dict]:
        """Get sales for current user"""
        if not self.user_id:
            raise ValueError("user_id required")
        
        try:
            if use_local:
                conn = self._get_local_conn()
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT * FROM sales 
                    WHERE user_id = ? 
                    ORDER BY created_at DESC 
                    LIMIT ?
                """, (self.user_id, limit))
                
                rows = cursor.fetchall()
                conn.close()
                
                return [dict(row) for row in rows]
            else:
                result = supabase.table('sales').select('*').eq('user_id', self.user_id).order('created_at', desc=True).limit(limit).execute()
                return result.data if result.data else []
        
        except Exception as e:
            print(f"❌ Get sales error: {e}")
            return []
    
    # ==================== SYNC OPERATIONS ====================
    
    def sync_user_data_from_cloud(self):
        """
        Sync user's data from Supabase to local SQLite
        Called when user logs in or manually syncs
        """
        if not self.user_id:
            raise ValueError("user_id required for sync")
        
        print(f"🔄 Syncing user {self.user_id} data from Supabase to local...")
        
        try:
            conn = self._get_local_conn()
            cursor = conn.cursor()
            
            # 0. Sync user profile first
            user_profile = supabase.table('profiles').select('*').eq('id', self.user_id).execute()
            
            if user_profile.data and len(user_profile.data) > 0:
                profile = user_profile.data[0]
                cursor.execute("SELECT id FROM profiles WHERE id = ?", (self.user_id,))
                exists = cursor.fetchone()
                
                if exists:
                    # Update existing profile
                    cursor.execute("""
                        UPDATE profiles SET
                            username = ?, email = ?, password_hash = ?, role = ?,
                            owner_name = ?, shop_name = ?, phone = ?, address = ?,
                            business_type = ?, currency = ?, upi_id = ?, upi_qr_url = ?,
                            is_active = ?, updated_at = ?
                        WHERE id = ?
                    """, (
                        profile.get('username'), profile.get('email'), profile.get('password_hash'),
                        profile.get('role'), profile.get('owner_name'), profile.get('shop_name'),
                        profile.get('phone'), profile.get('address'), profile.get('business_type'),
                        profile.get('currency'), profile.get('upi_id'), profile.get('upi_qr_url'),
                        profile.get('is_active'), profile.get('updated_at'), self.user_id
                    ))
                else:
                    # Insert new profile
                    cursor.execute("""
                        INSERT INTO profiles (
                            id, username, email, password_hash, role, owner_name, shop_name,
                            phone, address, business_type, currency, upi_id, upi_qr_url,
                            is_active, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        profile['id'], profile.get('username'), profile.get('email'),
                        profile.get('password_hash'), profile.get('role'), profile.get('owner_name'),
                        profile.get('shop_name'), profile.get('phone'), profile.get('address'),
                        profile.get('business_type'), profile.get('currency'), profile.get('upi_id'),
                        profile.get('upi_qr_url'), profile.get('is_active'), profile.get('created_at'),
                        profile.get('updated_at')
                    ))
                    print(f"✅ Synced user profile to local database")
            
            # 1. Sync products
            products = supabase.table('products').select('*').eq('user_id', self.user_id).execute()
            
            for product in products.data:
                cursor.execute("SELECT id FROM products WHERE id = ?", (product['id'],))
                exists = cursor.fetchone()
                
                if exists:
                    # Update existing
                    cursor.execute("""
                        UPDATE products SET
                            name = ?, barcode = ?, price = ?, selling_price = ?, cost_price = ?,
                            category_id = ?, unit = ?, discount_percentage = ?, tax_percentage = ?,
                            is_featured = ?, description = ?, updated_at = ?
                        WHERE id = ?
                    """, (
                        product.get('name'), product.get('barcode'), product.get('price'),
                        product.get('selling_price'), product.get('cost_price'), product.get('category_id'),
                        product.get('unit'), product.get('discount_percentage'), product.get('tax_percentage'),
                        product.get('is_featured'), product.get('description'), product.get('updated_at'),
                        product['id']
                    ))
                else:
                    # Insert new
                    cursor.execute("""
                        INSERT INTO products (
                            id, user_id, name, barcode, price, selling_price, cost_price,
                            category_id, unit, discount_percentage, tax_percentage,
                            is_featured, description, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        product['id'], product['user_id'], product.get('name'), product.get('barcode'),
                        product.get('price'), product.get('selling_price'), product.get('cost_price'),
                        product.get('category_id'), product.get('unit'), product.get('discount_percentage'),
                        product.get('tax_percentage'), product.get('is_featured'), product.get('description'),
                        product.get('created_at')
                    ))
            
            # 2. Sync inventory
            inventory_items = supabase.table('inventory').select('*').execute()
            
            for inv in inventory_items.data:
                # Check if this inventory belongs to user's product
                cursor.execute("SELECT id FROM products WHERE id = ? AND user_id = ?", (inv['product_id'], self.user_id))
                if cursor.fetchone():
                    cursor.execute("SELECT product_id FROM inventory WHERE product_id = ?", (inv['product_id'],))
                    exists = cursor.fetchone()
                    
                    if exists:
                        cursor.execute("""
                            UPDATE inventory SET
                                current_stock = ?, minimum_stock = ?, maximum_stock = ?, updated_at = ?
                            WHERE product_id = ?
                        """, (inv.get('current_stock'), inv.get('minimum_stock'), inv.get('maximum_stock'), inv.get('updated_at'), inv['product_id']))
                    else:
                        cursor.execute("""
                            INSERT INTO inventory (product_id, current_stock, minimum_stock, maximum_stock, updated_at)
                            VALUES (?, ?, ?, ?, ?)
                        """, (inv['product_id'], inv.get('current_stock'), inv.get('minimum_stock'), inv.get('maximum_stock'), inv.get('updated_at')))
            
            # 3. Sync sales (last 100)
            sales = supabase.table('sales').select('*').eq('user_id', self.user_id).order('created_at', desc=True).limit(100).execute()
            
            for sale in sales.data:
                cursor.execute("SELECT id FROM sales WHERE id = ?", (sale['id'],))
                exists = cursor.fetchone()
                
                if not exists:
                    cursor.execute("""
                        INSERT INTO sales (
                            id, user_id, invoice_number, total_amount, tax_amount, discount_amount,
                            payment_method, customer_name, customer_phone, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        sale['id'], sale['user_id'], sale.get('invoice_number'), sale.get('total_amount'),
                        sale.get('tax_amount'), sale.get('discount_amount'), sale.get('payment_method'),
                        sale.get('customer_name'), sale.get('customer_phone'), sale.get('created_at')
                    ))
            
            conn.commit()
            conn.close()
            
            print(f"✅ Sync complete for user {self.user_id}")
            return True
        
        except Exception as e:
            print(f"❌ Sync error: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def clear_local_user_data(self):
        """
        Clear all data for current user from local SQLite
        Called on logout
        """
        if not self.user_id:
            return
        
        try:
            conn = self._get_local_conn()
            cursor = conn.cursor()
            
            # Delete user's products (cascade will handle inventory)
            cursor.execute("DELETE FROM products WHERE user_id = ?", (self.user_id,))
            
            # Delete user's sales (cascade will handle sale_items)
            cursor.execute("DELETE FROM sales WHERE user_id = ?", (self.user_id,))
            
            conn.commit()
            conn.close()
            
            print(f"✅ Local data cleared for user {self.user_id}")
        
        except Exception as e:
            print(f"❌ Clear local data error: {e}")
