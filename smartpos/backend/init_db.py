#!/usr/bin/env python3
"""
Database initialization script for SmartPOS
"""
import sys
import os

# Add the backend directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import create_tables, drop_tables, get_database_info
from models import *  # Import all models

def init_database():
    """Initialize the database with all tables"""
    print("🚀 Initializing SmartPOS Database...")
    
    try:
        # Create all tables
        create_tables()
        
        # Show database info
        db_info = get_database_info()
        print(f"✅ Database initialized successfully!")
        print(f"   Type: {db_info['type']}")
        print(f"   URL: {db_info['url']}")
        print(f"   Tables: {', '.join(db_info['tables'])}")
        
    except Exception as e:
        print(f"❌ Error initializing database: {e}")
        return False
    
    return True

def reset_database():
    """Reset the database (drop all tables and recreate)"""
    print("⚠️  RESETTING DATABASE - All data will be lost!")
    confirmation = input("Are you sure? Type 'yes' to continue: ")
    
    if confirmation.lower() != 'yes':
        print("Operation cancelled.")
        return
    
    try:
        drop_tables()
        create_tables()
        print("✅ Database reset successfully!")
        
    except Exception as e:
        print(f"❌ Error resetting database: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--reset":
        reset_database()
    else:
        init_database()