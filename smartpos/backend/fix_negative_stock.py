"""
Fix negative stock values in the database
"""
import sqlite3

DB_PATH = "smartpos.db"

def fix_negative_stock():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Check for negative stock
    cursor.execute("SELECT product_id, current_stock FROM inventory WHERE current_stock < 0")
    negative_stocks = cursor.fetchall()
    
    if negative_stocks:
        print(f"Found {len(negative_stocks)} products with negative stock:")
        for product_id, stock in negative_stocks:
            print(f"  Product {product_id}: {stock}")
            # Set to 0
            cursor.execute("""
                UPDATE inventory
                SET current_stock = 0,
                    updated_at = datetime('now')
                WHERE product_id = ?
            """, (product_id,))
        
        conn.commit()
        print(f"\n✅ Fixed all negative stocks - set to 0")
    else:
        print("✅ No negative stocks found")
    
    conn.close()

if __name__ == "__main__":
    fix_negative_stock()
