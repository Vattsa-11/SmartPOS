"""
Supabase configuration for SmartPOS backend
"""
from supabase import create_client, Client
import os

# Supabase credentials (from frontend config)
SUPABASE_URL = "https://qmfoudfrqlbikzneopkv.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtZm91ZGZycWxiaWt6bmVvcGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyNTYyNTMsImV4cCI6MjA3MjgzMjI1M30.VJL6-4uy8qLplVYwTLY-zqTsp9L7yEBQ60gOiO8-SJ0"

# Create Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def get_supabase_client() -> Client:
    """Get Supabase client instance"""
    return supabase
