"""
Database helper functions for Supabase integration
Provides compatibility layer between SQLite-style code and Supabase
"""
from supabase_config import supabase
from typing import List, Dict, Any, Optional
from datetime import datetime

def dict_from_row(row: Dict) -> Dict:
    """Convert Supabase row to dict (already a dict, but keeping for compatibility)"""
    return row

def execute_query(table: str, operation: str, data: Dict = None, filters: Dict = None, 
                  select: str = "*", order_by: str = None, limit: int = None) -> Dict:
    """
    Execute a Supabase query with SQLite-like interface
    
    Args:
        table: Table name
        operation: 'select', 'insert', 'update', 'delete'
        data: Data for insert/update operations
        filters: WHERE conditions as dict
        select: Columns to select
        order_by: Column to order by
        limit: Number of rows to limit
    
    Returns:
        Dict with 'data' and 'error' keys
    """
    try:
        query = supabase.table(table)
        
        if operation == 'select':
            query = query.select(select)
            
            # Apply filters
            if filters:
                for key, value in filters.items():
                    query = query.eq(key, value)
            
            # Apply ordering
            if order_by:
                query = query.order(order_by)
            
            # Apply limit
            if limit:
                query = query.limit(limit)
            
            response = query.execute()
            return {'data': response.data, 'error': None}
        
        elif operation == 'insert':
            response = query.insert(data).execute()
            return {'data': response.data, 'error': None}
        
        elif operation == 'update':
            query = query.update(data)
            
            # Apply filters for update
            if filters:
                for key, value in filters.items():
                    query = query.eq(key, value)
            
            response = query.execute()
            return {'data': response.data, 'error': None}
        
        elif operation == 'delete':
            # Apply filters for delete
            if filters:
                for key, value in filters.items():
                    query = query.eq(key, value)
            
            response = query.delete().execute()
            return {'data': response.data, 'error': None}
        
        else:
            return {'data': None, 'error': f'Unknown operation: {operation}'}
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return {'data': None, 'error': str(e)}

def get_user_by_email(email: str) -> Optional[Dict]:
    """Get user by email"""
    result = execute_query('users', 'select', filters={'email': email})
    if result['data'] and len(result['data']) > 0:
        return result['data'][0]
    return None

def get_user_by_id(user_id: int) -> Optional[Dict]:
    """Get user by ID"""
    result = execute_query('users', 'select', filters={'id': user_id})
    if result['data'] and len(result['data']) > 0:
        return result['data'][0]
    return None

def create_user(user_data: Dict) -> Optional[Dict]:
    """Create a new user"""
    result = execute_query('users', 'insert', data=user_data)
    if result['data'] and len(result['data']) > 0:
        return result['data'][0]
    return None

def get_products_by_user(user_id: int) -> List[Dict]:
    """Get all products for a user with inventory data"""
    # Get products
    products_result = execute_query('products', 'select', filters={'user_id': user_id})
    
    if not products_result['data']:
        return []
    
    products = []
    for product in products_result['data']:
        # Get inventory for this product
        inventory_result = execute_query('inventory', 'select', filters={'product_id': product['id']})
        
        if inventory_result['data'] and len(inventory_result['data']) > 0:
            inventory = inventory_result['data'][0]
            product['stock'] = inventory.get('current_stock', 0)
            product['current_stock'] = inventory.get('current_stock', 0)
            product['minimum_stock'] = inventory.get('minimum_stock', 0)
            product['maximum_stock'] = inventory.get('maximum_stock', 1000)
        else:
            product['stock'] = 0
            product['current_stock'] = 0
            product['minimum_stock'] = 0
            product['maximum_stock'] = 1000
        
        products.append(product)
    
    return products

def get_product_by_barcode(barcode: str, user_id: int) -> Optional[Dict]:
    """Get product by barcode for a specific user"""
    result = execute_query('products', 'select', filters={'barcode': barcode, 'user_id': user_id})
    
    if result['data'] and len(result['data']) > 0:
        product = result['data'][0]
        
        # Get inventory
        inventory_result = execute_query('inventory', 'select', filters={'product_id': product['id']})
        if inventory_result['data'] and len(inventory_result['data']) > 0:
            inventory = inventory_result['data'][0]
            product['stock'] = inventory.get('current_stock', 0)
            product['current_stock'] = inventory.get('current_stock', 0)
            product['minimum_stock'] = inventory.get('minimum_stock', 0)
        
        return product
    
    return None

def create_product_with_inventory(product_data: Dict, initial_stock: float, minimum_stock: float, user_id: int) -> Optional[Dict]:
    """Create product and inventory entry"""
    # Add user_id to product data
    product_data['user_id'] = user_id
    
    # Create product
    product_result = execute_query('products', 'insert', data=product_data)
    
    if not product_result['data'] or len(product_result['data']) == 0:
        return None
    
    product = product_result['data'][0]
    product_id = product['id']
    
    # Create inventory entry
    inventory_data = {
        'product_id': product_id,
        'current_stock': initial_stock,
        'minimum_stock': minimum_stock,
        'maximum_stock': 1000,
        'updated_at': datetime.now().isoformat()
    }
    
    execute_query('inventory', 'insert', data=inventory_data)
    
    # Add stock info to product
    product['stock'] = initial_stock
    product['current_stock'] = initial_stock
    product['minimum_stock'] = minimum_stock
    
    return product

def update_product_and_inventory(product_id: int, product_data: Dict, stock: float, minimum_stock: float, user_id: int) -> Optional[Dict]:
    """Update product and its inventory"""
    # Update product
    update_data = {k: v for k, v in product_data.items() if v is not None}
    update_data['updated_at'] = datetime.now().isoformat()
    
    product_result = execute_query('products', 'update', data=update_data, filters={'id': product_id, 'user_id': user_id})
    
    if not product_result['data'] or len(product_result['data']) == 0:
        return None
    
    # Update inventory
    inventory_update = {
        'current_stock': stock,
        'minimum_stock': minimum_stock,
        'updated_at': datetime.now().isoformat()
    }
    
    execute_query('inventory', 'update', data=inventory_update, filters={'product_id': product_id})
    
    # Get updated product with inventory
    product = product_result['data'][0]
    inventory_result = execute_query('inventory', 'select', filters={'product_id': product_id})
    
    if inventory_result['data'] and len(inventory_result['data']) > 0:
        inventory = inventory_result['data'][0]
        product['stock'] = inventory.get('current_stock', 0)
        product['current_stock'] = inventory.get('current_stock', 0)
        product['minimum_stock'] = inventory.get('minimum_stock', 0)
    
    return product

def update_inventory_stock(product_id: int, stock_change: float) -> bool:
    """Update inventory stock by adding/subtracting"""
    # Get current stock
    inventory_result = execute_query('inventory', 'select', filters={'product_id': product_id})
    
    if not inventory_result['data'] or len(inventory_result['data']) == 0:
        return False
    
    current_stock = inventory_result['data'][0].get('current_stock', 0)
    new_stock = current_stock + stock_change
    
    if new_stock < 0:
        return False
    
    # Update stock
    update_data = {
        'current_stock': new_stock,
        'updated_at': datetime.now().isoformat()
    }
    
    result = execute_query('inventory', 'update', data=update_data, filters={'product_id': product_id})
    return result['error'] is None

def create_sale_with_items(sale_data: Dict, items: List[Dict], user_id: int) -> Optional[Dict]:
    """Create sale and sale items, update inventory"""
    # Add user_id to sale data
    sale_data['user_id'] = user_id
    sale_data['created_at'] = datetime.now().isoformat()
    
    # Create sale
    sale_result = execute_query('sales', 'insert', data=sale_data)
    
    if not sale_result['data'] or len(sale_result['data']) == 0:
        return None
    
    sale = sale_result['data'][0]
    sale_id = sale['id']
    
    # Create sale items and update inventory
    for item in items:
        item_data = {
            'sale_id': sale_id,
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'unit_price': item['price'],
            'total_price': item['total'],
            'created_at': datetime.now().isoformat()
        }
        
        execute_query('sale_items', 'insert', data=item_data)
        
        # Update inventory (subtract quantity)
        update_inventory_stock(item['product_id'], -item['quantity'])
    
    # Get sale items for response
    items_result = execute_query('sale_items', 'select', filters={'sale_id': sale_id})
    sale['items'] = items_result['data'] if items_result['data'] else []
    
    return sale
