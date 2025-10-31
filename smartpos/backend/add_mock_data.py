"""
Script to add mock data to the SmartPOS database for testing reports
"""
import sqlite3
from datetime import datetime, timedelta
import random

DB_PATH = "smartpos.db"

def add_mock_data():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("Adding mock data to database...")
    
    # Get user ID (assuming first user)
    cursor.execute("SELECT id FROM users LIMIT 1")
    user_result = cursor.fetchone()
    if not user_result:
        print("ERROR: No users found! Please create a user first.")
        return
    
    user_id = user_result[0]
    print(f"Using user_id: {user_id}")
    
    print("Clearing existing test data...")
    
    # Clear existing data (keep user/login data)
    cursor.execute("DELETE FROM sale_items")
    cursor.execute("DELETE FROM sales")
    cursor.execute("DELETE FROM inventory")
    cursor.execute("DELETE FROM products")
    cursor.execute("DELETE FROM customers WHERE name LIKE 'Walk-in%' OR phone LIKE '98765%'")
    cursor.execute("DELETE FROM categories")
    
    conn.commit()
    
    # Mock categories - now they will be inserted fresh
    categories = [
        ("Beverages", "Drinks and beverages"),
        ("Snacks", "Snacks and chips"),
        ("Dairy", "Milk and dairy products"),
        ("Bakery", "Bread and bakery items"),
        ("Grocery", "General grocery items")
    ]
    
    print("Adding categories...")
    for name, desc in categories:
        cursor.execute("""
            INSERT INTO categories (user_id, name, description, created_at)
            VALUES (?, ?, ?, datetime('now'))
        """, (user_id, name, desc))
    
    conn.commit()
    
    # Get category IDs
    cursor.execute("SELECT id, name FROM categories")
    cat_map = {name: id for id, name in cursor.fetchall()}
    
    print(f"Created {len(cat_map)} categories: {list(cat_map.keys())}")
    
    # Mock products (with realistic data)
    products = [
        # Beverages
        ("Coca Cola 500ml", cat_map["Beverages"], "8901234567890", 40, 30, "Bottle"),
        ("Pepsi 500ml", cat_map["Beverages"], "8901234567891", 40, 30, "Bottle"),
        ("Sprite 500ml", cat_map["Beverages"], "8901234567892", 40, 30, "Bottle"),
        ("Mountain Dew 500ml", cat_map["Beverages"], "8901234567893", 40, 30, "Bottle"),
        ("Thums Up 500ml", cat_map["Beverages"], "8901234567894", 40, 30, "Bottle"),
        ("Mineral Water 1L", cat_map["Beverages"], "8901234567895", 20, 15, "Bottle"),
        
        # Snacks
        ("Lays Classic 50g", cat_map["Snacks"], "8901234567896", 20, 15, "Packet"),
        ("Kurkure Masala 40g", cat_map["Snacks"], "8901234567897", 10, 7, "Packet"),
        ("Bingo Mad Angles 30g", cat_map["Snacks"], "8901234567898", 10, 7, "Packet"),
        ("Uncle Chips 30g", cat_map["Snacks"], "8901234567899", 10, 7, "Packet"),
        
        # Dairy
        ("Amul Milk 500ml", cat_map["Dairy"], "8901234567800", 25, 20, "Packet"),
        ("Amul Butter 100g", cat_map["Dairy"], "8901234567801", 50, 40, "Packet"),
        ("Amul Cheese Slice 200g", cat_map["Dairy"], "8901234567802", 120, 100, "Packet"),
        ("Mother Dairy Milk 500ml", cat_map["Dairy"], "8901234567803", 25, 20, "Packet"),
        
        # Bakery
        ("Britannia Bread", cat_map["Bakery"], "8901234567804", 35, 28, "Packet"),
        ("Britannia Good Day 100g", cat_map["Bakery"], "8901234567805", 30, 24, "Packet"),
        ("Parle-G 100g", cat_map["Bakery"], "8901234567806", 10, 8, "Packet"),
        
        # Grocery
        ("Maggi Noodles 70g", cat_map["Grocery"], "8901234567807", 12, 10, "Packet"),
        ("Tata Salt 1kg", cat_map["Grocery"], "8901234567808", 20, 18, "Packet"),
        ("Sugar 1kg", cat_map["Grocery"], "8901234567809", 40, 35, "Packet"),
    ]
    
    print("Adding products...")
    product_ids = []
    for prod in products:
        name, cat_id, barcode, selling_price, cost_price, unit = prod
        cursor.execute("""
            INSERT INTO products (
                user_id, name, category_id, barcode, 
                price, selling_price, cost_price, unit, 
                is_active, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, datetime('now'))
        """, (user_id, name, cat_id, barcode, selling_price, selling_price, cost_price, unit))
        product_ids.append(cursor.lastrowid)
    
    # Add inventory for all products
    print("Adding inventory...")
    for prod_id in product_ids:
        stock = random.randint(20, 100)
        cursor.execute("""
            INSERT INTO inventory (product_id, current_stock, minimum_stock, updated_at)
            VALUES (?, ?, 10, datetime('now'))
        """, (prod_id, stock))
    
    # Mock customers
    customers = [
        ("Rajesh Kumar", "9876543210", "rajesh@email.com", "Regular"),
        ("Priya Sharma", "9876543211", "priya@email.com", "VIP"),
        ("Amit Patel", "9876543212", "amit@email.com", "Regular"),
        ("Sneha Reddy", "9876543213", "sneha@email.com", "Wholesale"),
        ("Vikram Singh", "9876543214", "vikram@email.com", "Regular"),
        ("Anita Desai", "9876543215", "anita@email.com", "Regular"),
        ("Rohit Mehta", "9876543216", "rohit@email.com", "Regular"),
        ("Kavita Joshi", "9876543217", "kavita@email.com", "Regular"),
        ("Suresh Nair", "9876543218", "suresh@email.com", "VIP"),
        ("Deepa Gupta", "9876543219", "deepa@email.com", "Regular"),
        ("Arjun Verma", "9876543220", "arjun@email.com", "Regular"),
        ("Meera Kapoor", "9876543221", "meera@email.com", "VIP"),
        ("Karan Shah", "9876543222", "karan@email.com", "Wholesale"),
        ("Pooja Iyer", "9876543223", "pooja@email.com", "Regular"),
        ("Rahul Saxena", "9876543224", "rahul@email.com", "Regular"),
        ("Neha Agarwal", "9876543225", "neha@email.com", "VIP"),
        ("Sanjay Malhotra", "9876543226", "sanjay@email.com", "Regular"),
        ("Ritu Bansal", "9876543227", "ritu@email.com", "Regular"),
        ("Vishal Rao", "9876543228", "vishal@email.com", "Wholesale"),
        ("Anjali Chopra", "9876543229", "anjali@email.com", "Regular"),
        ("Manoj Bhatt", "9876543230", "manoj@email.com", "Regular"),
        ("Divya Sinha", "9876543231", "divya@email.com", "VIP"),
        ("Ashok Pandey", "9876543232", "ashok@email.com", "Regular"),
        ("Lakshmi Menon", "9876543233", "lakshmi@email.com", "Regular"),
        ("Ravi Tiwari", "9876543234", "ravi@email.com", "Wholesale"),
        ("Simran Kaur", "9876543235", "simran@email.com", "Regular"),
        ("Nitin Jain", "9876543236", "nitin@email.com", "VIP"),
        ("Geeta Pillai", "9876543237", "geeta@email.com", "Regular"),
        ("Abhishek Dubey", "9876543238", "abhishek@email.com", "Regular"),
        ("Swati Mishra", "9876543239", "swati@email.com", "Regular"),
    ]
    
    print("Adding customers...")
    customer_ids = []
    for name, phone, email, cust_type in customers:
        cursor.execute("""
            INSERT INTO customers (
                user_id, name, phone, email, customer_type, 
                is_active, current_balance, total_purchases, created_at
            )
            VALUES (?, ?, ?, ?, ?, 1, 0, 0, datetime('now'))
        """, (user_id, name, phone, email, cust_type))
        customer_ids.append(cursor.lastrowid)
    
    # Generate sales for the last 30 days
    print("Generating sales transactions...")
    sale_count = 0
    
    for days_ago in range(30):
        sale_date = datetime.now() - timedelta(days=days_ago)
        # Random number of sales per day (3-10)
        num_sales = random.randint(3, 10)
        
        for _ in range(num_sales):
            # Always use a registered customer for simplicity
            customer_id = random.choice(customer_ids)
            
            # Random payment method
            payment_method = random.choice(["Cash", "UPI", "Card", "Cash"])  # More cash sales
            
            # Create sale with random timestamp during business hours
            hour = random.randint(10, 21)  # 10 AM to 9 PM
            minute = random.randint(0, 59)
            sale_datetime = sale_date.replace(hour=hour, minute=minute)
            
            # Random number of items (1-5)
            num_items = random.randint(1, 5)
            selected_products = random.sample(product_ids, min(num_items, len(product_ids)))
            
            # Calculate total
            subtotal = 0
            tax = 0
            discount = 0
            
            for prod_id in selected_products:
                cursor.execute("SELECT selling_price FROM products WHERE id = ?", (prod_id,))
                price = cursor.fetchone()[0]
                quantity = random.randint(1, 3)
                subtotal += price * quantity
            
            # Random discount (20% chance of 5-10% discount)
            if random.random() < 0.2:
                discount = round(subtotal * random.uniform(0.05, 0.10), 2)
            
            # Tax (5% GST)
            tax = round((subtotal - discount) * 0.05, 2)
            total = subtotal - discount + tax
            
            # Insert sale
            cursor.execute("""
                INSERT INTO sales (
                    user_id, customer_id, subtotal, 
                    discount_amount, tax_amount, total_amount,
                    payment_method, payment_status, paid_amount, change_amount,
                    sale_date, created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, 'Completed', ?, ?, ?, ?)
            """, (
                user_id, customer_id, subtotal,
                discount, tax, total,
                payment_method, total, 0,
                sale_datetime.strftime('%Y-%m-%d %H:%M:%S'),
                sale_datetime.strftime('%Y-%m-%d %H:%M:%S')
            ))
            
            sale_id = cursor.lastrowid
            sale_count += 1
            
            # Insert sale items
            for prod_id in selected_products:
                cursor.execute("SELECT selling_price FROM products WHERE id = ?", (prod_id,))
                price = cursor.fetchone()[0]
                quantity = random.randint(1, 3)
                total_price = price * quantity
                
                cursor.execute("""
                    INSERT INTO sale_items (
                        sale_id, product_id, quantity,
                        unit_price, discount_amount, tax_amount, total_price,
                        created_at
                    )
                    VALUES (?, ?, ?, ?, 0, 0, ?, datetime('now'))
                """, (
                    sale_id, prod_id, quantity,
                    price, total_price
                ))
                
                # Update inventory - ensure stock doesn't go negative
                cursor.execute("""
                    SELECT current_stock FROM inventory WHERE product_id = ?
                """, (prod_id,))
                current = cursor.fetchone()
                if current and current[0] >= quantity:
                    cursor.execute("""
                        UPDATE inventory
                        SET current_stock = current_stock - ?,
                            updated_at = datetime('now')
                        WHERE product_id = ?
                    """, (quantity, prod_id))
                else:
                    # Skip this sale item if it would make stock negative
                    print(f"  Skipping sale item: insufficient stock for product {prod_id}")
                    continue
    
    conn.commit()
    conn.close()
    
    print(f"\n✅ Mock data added successfully!")
    print(f"   - {len(categories)} categories")
    print(f"   - {len(products)} products")
    print(f"   - {len(customers)} customers")
    print(f"   - {sale_count} sales transactions over 30 days")
    print(f"\nYou can now check the Reports tab to see sales analytics!")

if __name__ == "__main__":
    add_mock_data()
