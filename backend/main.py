import os
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests
from dotenv import load_dotenv
import json
import joblib
import pandas as pd
import numpy as np
from typing import Optional, List
import googlemaps
import requests as http_requests
import sqlite3
from datetime import datetime
import hashlib

# Load environment variables
load_dotenv()

app = FastAPI()

# Configure CORS
origins = ["*"]  # In production, you should restrict this
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Use the same Web Client ID from your Flutter app
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "258088043167-tajnkjfkk56cv40jveigggju2qhaeutj.apps.googleusercontent.com")

# Google Maps API configuration
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "AIzaSyCzWcYKBQGWFY7uqSp15BN8OKNsaqVJlYY")

# Construction Phase Checklist Templates
CHECKLIST_TEMPLATES = {
    "Residential": {
        "Phase 1: Pre-Construction": [
            "Site Analysis & Survey",
            "Soil Testing",
            "Building Plan Approval",
            "Budget Finalization",
            "Contractor Selection",
            "Material Vendor Selection",
            "Site Clearing & Preparation"
        ],
        "Phase 2: Foundation": [
            "Earth Excavation",
            "Anti-Termite Treatment",
            "PCC (Plain Cement Concrete) Work",
            "Footing Steel Work",
            "Foundation Concrete Pouring",
            "Foundation Waterproofing",
            "Backfilling & Compaction"
        ],
        "Phase 3: Structural Work": [
            "Column & Beam Steel Work",
            "Column & Beam Formwork",
            "Column & Beam Concrete Casting",
            "Slab Steel Work",
            "Slab Formwork",
            "Slab Concrete Casting",
            "Staircase Construction",
            "Brickwork/Block Work - Ground Floor",
            "Brickwork/Block Work - Upper Floors",
            "Lintel Casting"
        ],
        "Phase 4: Services Installation": [
            "Electrical Conduit Laying",
            "Plumbing Pipeline Installation",
            "Drainage Line Installation",
            "HVAC Duct Installation",
            "Bathroom Waterproofing"
        ],
        "Phase 5: Finishing": [
            "Internal Wall Plastering",
            "External Wall Plastering",
            "Flooring Work",
            "Wall Tiling",
            "Door Frame Installation",
            "Window Frame Installation",
            "Painting - First Coat",
            "Kitchen Counter Installation",
            "Bathroom Fixtures Installation",
            "Electrical Fixtures Installation",
            "Painting - Final Coat"
        ],
        "Phase 6: External Works": [
            "Compound Wall Construction",
            "External Drainage",
            "Landscaping",
            "Driveway Construction",
            "Gate Installation"
        ]
    },
    "Commercial": {
        "Phase 1: Pre-Construction": [
            "Site Analysis & Feasibility Study",
            "Environmental Impact Assessment",
            "Building Plan & Zoning Approval",
            "Budget & Finance Planning",
            "Contractor & Vendor Selection",
            "Site Mobilization",
            "Safety Plan Implementation"
        ],
        "Phase 2: Foundation": [
            "Site Clearing & Excavation",
            "Soil Treatment",
            "Foundation Marking",
            "Foundation Steel Work",
            "Foundation Concrete Pouring",
            "Waterproofing Treatment",
            "Underground Tank Construction"
        ],
        "Phase 3: Structural Work": [
            "Column Construction",
            "Beam Construction",
            "Floor Slab Construction",
            "Shear Wall Construction",
            "Core Wall Construction",
            "Post-tensioning Work",
            "External Wall Construction",
            "Internal Wall Construction"
        ],
        "Phase 4: Services Integration": [
            "Electrical System Installation",
            "HVAC System Installation",
            "Plumbing System Installation",
            "Fire Fighting System Installation",
            "Elevator Installation",
            "Building Management System Setup",
            "Security System Installation"
        ],
        "Phase 5: Interior & Finishing": [
            "Floor Finishing",
            "Wall Finishing",
            "Ceiling Work",
            "Glass Facade Installation",
            "Door & Window Installation",
            "Painting Work",
            "Signage Installation",
            "Interior Fixtures Installation"
        ],
        "Phase 6: External Development": [
            "Parking Area Development",
            "Landscaping",
            "External Lighting",
            "Storm Water Drainage",
            "Sewage Treatment Plant",
            "Access Control Setup",
            "Final Site Cleaning"
        ]
    }
}

# Product Category Mapping - Maps Google Places types to expected product categories
PRODUCT_CATEGORY_MAP = {
    "hardware_store": [
        "Tools", "Plumbing Supplies", "Electrical Fittings", "Fasteners", 
        "Hardware", "Safety Equipment", "Power Tools", "Hand Tools", "Locks & Keys"
    ],
    "home_improvement_store": [
        "Building Materials", "Tools", "Hardware", "Paint & Supplies", 
        "Lumber", "Flooring", "Roofing Materials", "Insulation", "Windows & Doors"
    ],
    "building_materials_store": [
        "Cement", "Steel", "Bricks", "Sand", "Gravel", "Concrete Blocks", 
        "Rebar", "Construction Chemicals", "Waterproofing Materials", "Tiles"
    ],
    "paint_store": [
        "Paint", "Brushes & Rollers", "Primers", "Stains", "Varnishes", 
        "Spray Paint", "Color Mixing", "Painting Accessories", "Wall Textures"
    ],
    "home_goods_store": [
        "Home Decor", "Storage Solutions", "Cleaning Supplies", "Organization", 
        "Small Appliances", "Household Items", "Garden Supplies"
    ],
    "plumbing_supply_store": [
        "Pipes", "Fittings", "Valves", "Pumps", "Water Heaters", "Fixtures", 
        "Plumbing Tools", "Drainage Solutions", "Water Treatment"
    ],
    "electrical_supply_store": [
        "Wires & Cables", "Circuit Breakers", "Outlets & Switches", "Lighting", 
        "Electrical Tools", "Conduits", "Transformers", "Solar Equipment"
    ],
    "roofing_contractor": [
        "Roofing Materials", "Shingles", "Metal Roofing", "Gutters", 
        "Roof Insulation", "Flashing", "Roof Repair Materials"
    ],
    "lumber_yard": [
        "Lumber", "Plywood", "Engineered Wood", "Treated Lumber", 
        "Millwork", "Decking Materials", "Beams & Posts"
    ],
    "tile_contractor": [
        "Tiles", "Grout", "Adhesives", "Tile Tools", "Sealers", 
        "Mosaic", "Natural Stone", "Installation Materials"
    ],
    "store": [
        "General Supplies", "Basic Hardware", "Household Items"
    ],
    "establishment": [
        "Various Products", "Mixed Inventory"
    ]
}

# Load ML model components on startup
print("🔧 Loading ML model components...")
try:
    model = joblib.load('concrete_grade_model.pkl')
    target_encoder = joblib.load('target_encoder.pkl')
    
    with open('feature_names.txt', 'r') as f:
        feature_names = [line.strip() for line in f.readlines()]
    
    # Load lookup datasets
    mix_df = pd.read_csv('concrete_mix_design_dataset.csv')
    cost_df = pd.read_csv('concrete_estimate_dataset.csv')
    
    print("✅ ML model components loaded successfully!")
except Exception as e:
    print(f"❌ Error loading ML components: {e}")
    model = None
    target_encoder = None
    feature_names = None
    mix_df = None
    cost_df = None

class Token(BaseModel):
    token: str = None
    idToken: str = None  # Flutter Google Sign In might send this
    id_token: str = None  # Alternative naming
    accessToken: str = None

class PredictionRequest(BaseModel):
    building_type: str
    floors: str
    soil_type: str
    seismic_zone: str
    exposure: str
    load_type: str
    built_up_area: Optional[int] = 1000

class NearbySearchInput(BaseModel):
    query: str
    latitude: float
    longitude: float

class GeocodeInput(BaseModel):
    address: str

# New model for price reporting
class PriceReport(BaseModel):
    product_name: str
    price: float

# Project management models
class ProjectCreate(BaseModel):
    name: str
    location: str
    project_type: str  # "Residential" or "Commercial"
    budget: Optional[float] = 0.0
    description: Optional[str] = ""
    user_id: Optional[str] = "anonymous"

class Project(BaseModel):
    id: int
    name: str
    location: str
    project_type: str
    budget: float
    created_at: str
    user_id: str
    description: str
    status: str

class ExpenseCreate(BaseModel):
    description: str
    amount: float
    category: str
    date: str

# Database initialization
def init_db():
    """Initialize the SQLite database for storing community-reported prices"""
    conn = sqlite3.connect('store_prices.db')
    cursor = conn.cursor()
    
    # Create users table (for email-based authentication tracking)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            password_hash TEXT,
            created_at TEXT NOT NULL,
            last_login TEXT,
            auth_provider TEXT DEFAULT 'email',
            profile_picture TEXT
        )
    ''')
    
    # Create predictions table (for ML model)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS predictions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            building_type TEXT,
            floors TEXT,
            soil_type TEXT,
            seismic_zone TEXT,
            exposure TEXT,
            load_type TEXT,
            built_up_area INTEGER,
            predicted_grade TEXT,
            created_at TEXT
        )
    ''')
    
    # Create store_prices table (for community price tracker)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS store_prices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            place_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            price REAL NOT NULL,
            reported_at TEXT NOT NULL,
            user_id TEXT DEFAULT 'anonymous'
        )
    ''')
    
    # Create projects table (for construction project management)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            location TEXT NOT NULL,
            project_type TEXT NOT NULL CHECK (project_type IN ('Residential', 'Commercial')),
            budget REAL DEFAULT 0.0,
            created_at TEXT NOT NULL,
            user_id TEXT DEFAULT 'anonymous',
            description TEXT DEFAULT '',
            status TEXT DEFAULT 'Planning' CHECK (status IN ('Planning', 'In Progress', 'Completed', 'On Hold'))
        )
    ''')
    
    # Note: user_id stores the user's email address for user identification and project isolation
    
    # Create project_tasks table (for construction phase checklist)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS project_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            phase TEXT NOT NULL,
            task_name TEXT NOT NULL,
            is_completed BOOLEAN DEFAULT FALSE,
            created_at TEXT NOT NULL,
            completed_at TEXT,
            FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
        )
    ''')

    # Create expenses table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
        )
    ''')
    
    conn.commit()
    conn.close()
    print("✅ Database initialized successfully!")

# Initialize database on startup
init_db()

# Password hashing helper functions
def hash_password(password: str) -> str:
    """Hash a password using SHA-256"""
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(password: str, password_hash: str) -> bool:
    """Verify a password against its hash"""
    return hash_password(password) == password_hash

@app.get("/")
def read_root():
    return {"message": "Building Platform FastAPI Backend is running!"}

@app.get("/api/v1/users/check-email")
async def check_email_exists(email: str):
    """
    Check if an email already exists in the system
    """
    try:
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # Check if email exists in users table
        cursor.execute('SELECT email FROM users WHERE email = ?', (email,))
        user = cursor.fetchone()
        
        conn.close()
        
        exists = user is not None
        print(f"{'✅' if exists else '❌'} Email check: {email} - {'Exists' if exists else 'Available'}")
        
        return {
            "success": True,
            "exists": exists,
            "email": email
        }
    except Exception as e:
        print(f"❌ Error checking email: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to check email: {str(e)}")

@app.post("/api/v1/users/register")
async def register_user(user_data: dict):
    """
    Register a new user with their email, name, and password
    """
    try:
        email = user_data.get('email')
        name = user_data.get('name')
        password = user_data.get('password')
        auth_provider = user_data.get('auth_provider', 'email')  # 'email' or 'google'
        
        if not email or not name:
            raise HTTPException(status_code=400, detail="Email and name are required")
        
        if auth_provider == 'email' and not password:
            raise HTTPException(status_code=400, detail="Password is required for email registration")
        
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # Check if email already exists
        cursor.execute('SELECT email FROM users WHERE email = ?', (email,))
        if cursor.fetchone():
            conn.close()
            raise HTTPException(status_code=409, detail="Email already exists")
        
        # Hash password if provided (for email auth)
        password_hash = hash_password(password) if password else None
        
        # Insert new user
        created_at = datetime.now().isoformat()
        cursor.execute('''
            INSERT INTO users (email, name, password_hash, created_at, last_login, auth_provider)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (email, name, password_hash, created_at, created_at, auth_provider))
        
        conn.commit()
        conn.close()
        
        print(f"✅ User registered: {name} ({email}) via {auth_provider}")
        
        return {
            "success": True,
            "message": "User registered successfully",
            "user": {
                "email": email,
                "name": name,
                "created_at": created_at,
                "auth_provider": auth_provider
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error registering user: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to register user: {str(e)}")

@app.post("/api/v1/users/login")
async def login_user(user_data: dict):
    """
    Authenticate user with email and password
    """
    try:
        email = user_data.get('email')
        password = user_data.get('password')
        
        if not email:
            raise HTTPException(status_code=400, detail="Email is required")
        
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # Get user by email
        cursor.execute('SELECT email, name, password_hash, auth_provider, profile_picture FROM users WHERE email = ?', (email,))
        user = cursor.fetchone()
        
        if not user:
            conn.close()
            print(f"⚠️ Login attempt for unregistered email: {email}")
            return {
                "success": False,
                "message": "Email not found. Please sign up first."
            }
        
        user_email, user_name, password_hash, auth_provider, profile_picture = user
        
        # If user registered with Google, they can't login with password
        if auth_provider == 'google' and password:
            conn.close()
            print(f"⚠️ Password login attempted for Google account: {email}")
            return {
                "success": False,
                "message": "This email is registered with Google. Please sign in with Google."
            }
        
        # Verify password for email-registered users
        if auth_provider == 'email':
            if not password:
                conn.close()
                return {
                    "success": False,
                    "message": "Password is required"
                }
            
            if not verify_password(password, password_hash):
                conn.close()
                print(f"❌ Invalid password for email: {email}")
                return {
                    "success": False,
                    "message": "Incorrect password"
                }
        
        # Update last login
        cursor.execute('''
            UPDATE users SET last_login = ? WHERE email = ?
        ''', (datetime.now().isoformat(), email))
        conn.commit()
        conn.close()
        
        print(f"✅ User logged in: {user_name} ({email})")
        
        return {
            "success": True,
            "message": "Login successful",
            "user": {
                "email": user_email,
                "name": user_name,
                "auth_provider": auth_provider,
                "profile_picture": profile_picture
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error during login: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to login: {str(e)}")

@app.put("/api/v1/users/profile-picture")
async def update_profile_picture(data: dict):
    """
    Update user's profile picture URL
    """
    try:
        email = data.get('email')
        profile_picture = data.get('profile_picture')
        
        if not email or not profile_picture:
            raise HTTPException(status_code=400, detail="Email and profile_picture are required")
        
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # Check if user exists
        cursor.execute('SELECT id FROM users WHERE email = ?', (email,))
        user = cursor.fetchone()
        
        if not user:
            conn.close()
            raise HTTPException(status_code=404, detail="User not found")
        
        # Update profile picture
        cursor.execute('''
            UPDATE users SET profile_picture = ? WHERE email = ?
        ''', (profile_picture, email))
        
        conn.commit()
        conn.close()
        
        print(f"✅ Profile picture updated for user: {email}")
        
        return {
            "success": True,
            "message": "Profile picture updated successfully",
            "profile_picture": profile_picture
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error updating profile picture: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update profile picture: {str(e)}")

@app.post("/api/v1/debug/request")
async def debug_request(request: Request):
    """Debug endpoint to see what the Flutter app is sending"""
    body = await request.body()
    headers = dict(request.headers)
    
    return {
        "body": body.decode(),
        "headers": headers,
        "content_type": headers.get("content-type")
    }

@app.post("/api/v1/auth/google")
async def auth_google(request: Request):
    try:
        # Get the raw request body for debugging
        body = await request.body()
        print(f"Raw request body: {body.decode()}")
        
        # Parse JSON manually to handle different formats
        try:
            data = json.loads(body.decode())
            print(f"Parsed JSON: {data}")
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="Invalid JSON format")
        
        # Extract token from various possible field names
        token_value = (
            data.get('token') or 
            data.get('idToken') or 
            data.get('id_token') or
            data.get('accessToken')
        )
        
        if not token_value:
            raise HTTPException(status_code=400, detail="No token found in request")
        
        print(f"Using token: {token_value[:50]}...")  # Print first 50 chars for debugging

        # Verify the ID token
        idinfo = id_token.verify_oauth2_token(token_value, requests.Request(), GOOGLE_CLIENT_ID)

        # Extract user information
        user_id = idinfo['sub']
        email = idinfo['email']
        name = idinfo['name']
        picture = idinfo.get('picture', '')

        print(f"User authenticated: {name} ({email})")

        # Generate a session token (replace with your own logic)
        session_token = f"session_{user_id}"

        return {
            "success": True,
            "message": "Google authentication successful",
            "token": session_token,
            "user": {
                "id": user_id,
                "email": email,
                "name": name,
                "picture": picture,
                "verified": idinfo.get('email_verified', False)
            }
        }
    except ValueError as e:
        # Invalid token
        print(f"Token verification failed: {e}")
        raise HTTPException(status_code=401, detail=f"Invalid Google token: {e}")
    except Exception as e:
        print(f"Authentication error: {e}")
        raise HTTPException(status_code=500, detail=f"An error occurred: {e}")

# Prediction helper functions
def preprocess_user_input(user_input_dict):
    """
    Preprocesses user input to match the model's expected format
    """
    if not all([model, target_encoder, feature_names]):
        raise HTTPException(status_code=503, detail="ML model not properly loaded")
    
    # Convert user input into a DataFrame
    input_df = pd.DataFrame([user_input_dict])
    
    # Feature engineering - extract floor number from 'G+X' format
    input_df['Floor_Number'] = input_df['Floors'].str.extract(r'(\d+)').astype(int)
    
    # Select the same features used in training
    features = ['Building_Type', 'Floor_Number', 'Soil_Type', 'Seismic_Zone', 'Exposure', 'Load_Type']
    X_input = input_df[features].copy()
    
    # Apply one-hot encoding to categorical features
    categorical_features = ['Building_Type', 'Soil_Type', 'Seismic_Zone', 'Exposure', 'Load_Type']
    X_categorical = pd.get_dummies(X_input[categorical_features], prefix=categorical_features)
    X_numerical = X_input[['Floor_Number']]
    
    # Combine numerical and encoded categorical features
    X_processed = pd.concat([X_numerical, X_categorical], axis=1)
    
    # Ensure all training features are present (fill missing with 0)
    for feature in feature_names:
        if feature not in X_processed.columns:
            X_processed[feature] = 0
    
    # Reorder columns to match training data
    X_processed = X_processed[feature_names]
    
    return X_processed

def get_concrete_prediction(user_input_dict):
    """
    Generate complete concrete grade prediction with materials and cost
    """
    try:
        # Preprocess input
        processed_input = preprocess_user_input(user_input_dict)
        
        # Make prediction
        predicted_grade_numeric = model.predict(processed_input)[0]
        predicted_grade = target_encoder.inverse_transform([predicted_grade_numeric])[0]
        
        # Get confidence
        prediction_proba = model.predict_proba(processed_input)[0]
        confidence = max(prediction_proba) * 100
        
        # Look up materials
        materials_row = mix_df[mix_df['Grade'] == predicted_grade]
        if materials_row.empty:
            materials = {"Grade": predicted_grade, "Note": "Materials data not available"}
        else:
            materials = materials_row.iloc[0].to_dict()
        
        # Calculate cost
        cost_row = cost_df[cost_df['Grade'] == predicted_grade]
        if cost_row.empty:
            total_cost = "Cost data not available"
            rate_per_cum = 0
        else:
            rate_per_cum = cost_row['RMC_Rate_perCum'].iloc[0]
            built_up_area_sqft = user_input_dict.get('built_up_area', 1000)
            estimated_volume_cum = built_up_area_sqft * 0.07
            total_cost_value = estimated_volume_cum * rate_per_cum
            total_cost = f"₹{total_cost_value:,.2f}"
        
        return {
            "success": True,
            "prediction": {
                "concrete_grade": predicted_grade,
                "confidence_percentage": f"{confidence:.1f}%"
            },
            "materials": materials,
            "cost_estimation": {
                "rate_per_cubic_meter": f"₹{rate_per_cum:,.2f}" if isinstance(rate_per_cum, (int, float)) else "N/A",
                "estimated_volume_cum": f"{estimated_volume_cum:.2f} cubic meters" if 'estimated_volume_cum' in locals() else "N/A",
                "total_estimated_cost": total_cost,
                "area_considered": f"{user_input_dict.get('built_up_area', 1000)} sq. ft."
            },
            "input_summary": user_input_dict
        }
        
    except Exception as e:
        print(f"Prediction error: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.post("/api/v1/predict")
async def predict_concrete_grade(request: PredictionRequest):
    """
    Predict concrete grade based on building specifications
    """
    try:
        # Convert Pydantic model to dictionary
        user_input = {
            "Building_Type": request.building_type,
            "Floors": request.floors,
            "Soil_Type": request.soil_type,
            "Seismic_Zone": request.seismic_zone,
            "Exposure": request.exposure,
            "Load_Type": request.load_type,
            "built_up_area": request.built_up_area
        }
        
        print(f"🔍 Processing prediction request for {request.building_type} building")
        
        # Get prediction
        result = get_concrete_prediction(user_input)
        
        print(f"✅ Prediction completed: {result['prediction']['concrete_grade']}")
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Prediction endpoint error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during prediction")

@app.get("/api/v1/model/status")
async def get_model_status():
    """
    Check if the ML model is loaded and ready
    """
    return {
        "model_loaded": model is not None,
        "encoder_loaded": target_encoder is not None,
        "features_loaded": feature_names is not None,
        "datasets_loaded": mix_df is not None and cost_df is not None,
        "feature_count": len(feature_names) if feature_names else 0,
        "available_grades": target_encoder.classes_.tolist() if target_encoder else []
    }

@app.post("/api/v1/nearby-stores")
async def find_nearby_stores(search_input: NearbySearchInput):
    """
    Receives a search query and GPS coordinates from the Flutter app,
    finds nearby stores using the Google Places API, and returns a list.
    """
    try:
        print(f"🔍 Searching for '{search_input.query}' near {search_input.latitude}, {search_input.longitude}")
        
        # Use Google Places API to find nearby stores
        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        params = {
            'location': f"{search_input.latitude},{search_input.longitude}",
            'radius': 5000,  # 5km radius
            'keyword': f"{search_input.query} construction supply building materials hardware",
            'type': 'store',
            'key': GOOGLE_MAPS_API_KEY
        }
        
        response = http_requests.get(url, params=params)
        data = response.json()
        
        if data.get('status') != 'OK':
            print(f"❌ Google Places API error: {data.get('status')} - {data.get('error_message', 'Unknown error')}")
            return {"stores": [], "error": f"Google Places API error: {data.get('status')}"}
        
        # Format the results and get detailed information for each store
        stores = []
        for place in data.get('results', []):
            location = place.get('geometry', {}).get('location', {})
            
            # Get basic store info
            store_data = {
                "name": place.get('name', 'Unknown Store'),
                "address": place.get('vicinity', 'Address not available'),
                "formatted_address": place.get('formatted_address', place.get('vicinity', 'Address not available')),
                "rating": place.get('rating', 0.0),
                "user_ratings_total": place.get('user_ratings_total', 0),
                "isOpen": place.get('opening_hours', {}).get('open_now', False),
                "latitude": location.get('lat', 0.0),
                "longitude": location.get('lng', 0.0),
                "place_id": place.get('place_id', ''),
                "types": place.get('types', []),
                "price_level": place.get('price_level'),
                "photo_reference": None,
                "photos": []
            }
            
            # Add photo references if available
            if place.get('photos'):
                store_data["photo_reference"] = place['photos'][0].get('photo_reference')
                store_data["photos"] = [photo.get('photo_reference') for photo in place.get('photos', [])[:3]]
            
            # Infer product categories based on store types
            place_types = place.get('types', [])
            inferred_categories = set()
            
            for place_type in place_types:
                if place_type in PRODUCT_CATEGORY_MAP:
                    inferred_categories.update(PRODUCT_CATEGORY_MAP[place_type])
            
            # Convert set to list and add to store data
            store_data["inferred_product_categories"] = list(inferred_categories)
            
            stores.append(store_data)
        
        print(f"✅ Found {len(stores)} stores with detailed information")
        return {"stores": stores, "status": "success"}

    except Exception as e:
        print(f"❌ Error in nearby stores search: {e}")
        return {"stores": [], "error": str(e)}

@app.post("/api/v1/geocode")
async def geocode_address(geocode_input: GeocodeInput):
    """
    Convert an address to GPS coordinates using Google Geocoding API
    """
    try:
        print(f"🗺️ Geocoding address: {geocode_input.address}")
        
        # Use Google Geocoding API
        url = "https://maps.googleapis.com/maps/api/geocode/json"
        params = {
            'address': geocode_input.address,
            'key': GOOGLE_MAPS_API_KEY
        }
        
        response = http_requests.get(url, params=params)
        data = response.json()
        
        if data.get('status') == 'OK' and data.get('results'):
            result = data['results'][0]
            location = result['geometry']['location']
            formatted_address = result['formatted_address']
            
            print(f"✅ Geocoded: {geocode_input.address} → {location['lat']}, {location['lng']}")
            
            return {
                "success": True,
                "location": {
                    "latitude": location['lat'],
                    "longitude": location['lng']
                },
                "formatted_address": formatted_address,
                "input_address": geocode_input.address
            }
        else:
            print(f"❌ Geocoding failed: {data.get('status')} - {data.get('error_message', 'No results')}")
            return {
                "success": False,
                "error": f"Could not find location for: {geocode_input.address}"
            }
            
    except Exception as e:
        print(f"❌ Geocoding error: {e}")
        return {
            "success": False,
            "error": f"Geocoding service error: {str(e)}"
        }

@app.post("/api/v1/stores/{place_id}/prices")
async def report_store_price(place_id: str, price_report: PriceReport):
    """
    Allow users to report current prices for products at a specific store
    """
    try:
        print(f"💰 Reporting price for {price_report.product_name} at store {place_id}: ₹{price_report.price}")
        
        # Connect to database
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # Insert the new price report
        cursor.execute('''
            INSERT INTO store_prices (place_id, product_name, price, reported_at, user_id)
            VALUES (?, ?, ?, ?, ?)
        ''', (
            place_id,
            price_report.product_name,
            price_report.price,
            datetime.now().isoformat(),
            'anonymous'  # Placeholder for user system
        ))
        
        conn.commit()
        conn.close()
        
        print(f"✅ Price report saved successfully")
        return {
            "success": True,
            "message": f"Price for {price_report.product_name} reported successfully",
            "data": {
                "place_id": place_id,
                "product_name": price_report.product_name,
                "price": price_report.price,
                "reported_at": datetime.now().isoformat()
            }
        }
        
    except Exception as e:
        print(f"❌ Error reporting price: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to report price: {str(e)}")

@app.get("/api/v1/store-details/{place_id}")
async def get_store_details(place_id: str):
    """
    Get detailed information about a specific store including reviews, photos, and hours
    """
    try:
        print(f"🏪 Getting details for place_id: {place_id}")
        
        # Use Google Places Details API
        url = "https://maps.googleapis.com/maps/api/place/details/json"
        params = {
            'place_id': place_id,
            'fields': 'name,formatted_address,formatted_phone_number,website,opening_hours,rating,user_ratings_total,reviews,photos,price_level,types',
            'key': GOOGLE_MAPS_API_KEY
        }
        
        response = http_requests.get(url, params=params)
        data = response.json()
        
        if data.get('status') != 'OK':
            print(f"❌ Google Places Details API error: {data.get('status')}")
            return {"details": None, "error": f"Google Places API error: {data.get('status')}"}
        
        result = data.get('result', {})
        
        # Format the detailed information
        details = {
            "name": result.get('name'),
            "formatted_address": result.get('formatted_address'),
            "phone_number": result.get('formatted_phone_number'),
            "website": result.get('website'),
            "rating": result.get('rating', 0.0),
            "user_ratings_total": result.get('user_ratings_total', 0),
            "price_level": result.get('price_level'),
            "types": result.get('types', []),
            "opening_hours": result.get('opening_hours', {}).get('weekday_text', []),
            "reviews": [],
            "photos": []
        }
        
        # Add reviews
        if result.get('reviews'):
            details["reviews"] = [
                {
                    "author_name": review.get('author_name'),
                    "rating": review.get('rating'),
                    "text": review.get('text'),
                    "time": review.get('time'),
                    "relative_time_description": review.get('relative_time_description')
                }
                for review in result['reviews'][:5]  # Limit to 5 reviews
            ]
        
        # Add photo references
        if result.get('photos'):
            details["photos"] = [
                photo.get('photo_reference') 
                for photo in result['photos'][:5]  # Limit to 5 photos
            ]
        
        # Get latest community-reported prices for this store
        try:
            conn = sqlite3.connect('store_prices.db')
            cursor = conn.cursor()
            
            # Query to get the most recent price for each product at this store
            cursor.execute('''
                SELECT product_name, price, reported_at
                FROM store_prices 
                WHERE place_id = ? 
                  AND (product_name, reported_at) IN (
                      SELECT product_name, MAX(reported_at)
                      FROM store_prices 
                      WHERE place_id = ?
                      GROUP BY product_name
                  )
                ORDER BY reported_at DESC
            ''', (place_id, place_id))
            
            price_data = cursor.fetchall()
            conn.close()
            
            # Format price data
            details["latest_prices"] = [
                {
                    "product_name": row[0],
                    "price": row[1],
                    "last_reported": row[2]
                }
                for row in price_data
            ]
            
            print(f"💰 Found {len(price_data)} price reports for this store")
            
        except Exception as price_error:
            print(f"⚠️ Error fetching prices: {price_error}")
            details["latest_prices"] = []
        
        print(f"✅ Retrieved detailed information for {details['name']}")
        return {"details": details, "status": "success"}
        
    except Exception as e:
        print(f"❌ Error getting store details: {e}")
        return {"details": None, "error": str(e)}

# ====================================
# PROJECTS API ENDPOINTS
# ====================================

@app.post("/api/v1/projects")
async def create_project(project: ProjectCreate):
    """
    Create a new construction project and its associated tasks from template
    User is identified by email address
    """
    try:
        # Validate project type
        if project.project_type not in ["Residential", "Commercial"]:
            raise HTTPException(status_code=400, detail="Project type must be 'Residential' or 'Commercial'")
        
        # Connect to database
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # Insert new project with user_id (email) from request body
        created_at = datetime.now().isoformat()
        user_id = project.user_id if project.user_id else 'anonymous'
        
        print(f"🏗️ Creating project '{project.name}' for user (email): {user_id}")
        
        cursor.execute('''
            INSERT INTO projects (name, location, project_type, budget, created_at, user_id, description, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            project.name,
            project.location,
            project.project_type,
            project.budget,
            created_at,
            user_id,
            project.description,
            'Planning'
        ))
        
        project_id = cursor.lastrowid
        
        # Create tasks from template
        template = CHECKLIST_TEMPLATES.get(project.project_type)
        if template:
            task_entries = []
            for phase, tasks in template.items():
                for task_name in tasks:
                    task_entries.append((
                        project_id,
                        phase,
                        task_name,
                        False,  # is_completed
                        created_at,  # created_at
                        None  # completed_at
                    ))
            
            # Bulk insert all tasks
            cursor.executemany('''
                INSERT INTO project_tasks (project_id, phase, task_name, is_completed, created_at, completed_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', task_entries)
        
        conn.commit()
        
        # Fetch all created tasks
        cursor.execute('''
            SELECT id, phase, task_name, is_completed
            FROM project_tasks
            WHERE project_id = ?
            ORDER BY phase, id
        ''', (project_id,))
        tasks = [
            {
                "id": row[0],
                "phase": row[1],
                "task_name": row[2],
                "is_completed": bool(row[3])
            }
            for row in cursor.fetchall()
        ]
        
        conn.close()
        
        print(f"✅ Created new project: {project.name} (ID: {project_id}) with {len(tasks)} tasks")
        
        return {
            "success": True,
            "message": "Project created successfully with checklist",
            "project_id": project_id,
            "project": {
                "id": project_id,
                "name": project.name,
                "location": project.location,
                "project_type": project.project_type,
                "budget": project.budget,
                "created_at": created_at,
                "description": project.description,
                "status": "Planning"
            },
            "tasks": tasks
        }
        
    except Exception as e:
        print(f"❌ Error creating project: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create project: {str(e)}")

@app.get("/api/v1/projects")
async def get_projects(user_id: str = "anonymous"):
    """
    Get all projects for a specific user (identified by email)
    """
    try:
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # Get projects for the specific user (by email)
        cursor.execute('''
            SELECT id, name, location, project_type, budget, created_at, user_id, description, status
            FROM projects
            WHERE user_id = ?
            ORDER BY created_at DESC
        ''', (user_id,))
        
        projects = []
        for row in cursor.fetchall():
            projects.append({
                "id": row[0],
                "name": row[1],
                "location": row[2],
                "project_type": row[3],
                "budget": row[4],
                "created_at": row[5],
                "user_id": row[6],
                "description": row[7],
                "status": row[8]
            })
        
        conn.close()
        
        print(f"✅ Retrieved {len(projects)} projects for user (email): {user_id}")
        return {
            "success": True,
            "projects": projects,
            "count": len(projects)
        }
        
    except Exception as e:
        print(f"❌ Error getting projects: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get projects: {str(e)}")

@app.put("/api/v1/projects/{project_id}/tasks/{task_id}")
async def update_task(project_id: int, task_id: int, is_completed: bool):
    """
    Update the completion status of a specific task
    """
    try:
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()
        
        # First verify that the task belongs to the specified project
        cursor.execute('''
            SELECT id FROM project_tasks 
            WHERE id = ? AND project_id = ?
        ''', (task_id, project_id))
        
        if not cursor.fetchone():
            conn.close()
            raise HTTPException(status_code=404, detail="Task not found or does not belong to the specified project")
        
        # Update task status
        completed_at = datetime.now().isoformat() if is_completed else None
        cursor.execute('''
            UPDATE project_tasks 
            SET is_completed = ?, completed_at = ?
            WHERE id = ? AND project_id = ?
        ''', (is_completed, completed_at, task_id, project_id))
        
        # Get updated task details
        cursor.execute('''
            SELECT id, phase, task_name, is_completed, created_at, completed_at
            FROM project_tasks
            WHERE id = ?
        ''', (task_id,))
        task = cursor.fetchone()
        
        # Update project status based on task completion
        cursor.execute('''
            SELECT COUNT(*) as total, SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) as completed
            FROM project_tasks
            WHERE project_id = ?
        ''', (project_id,))
        counts = cursor.fetchone()
        total_tasks, completed_tasks = counts
        
        # Update project status if all tasks are complete
        if completed_tasks == total_tasks and is_completed:
            cursor.execute('''
                UPDATE projects
                SET status = 'Completed'
                WHERE id = ?
            ''', (project_id,))
        elif completed_tasks > 0:
            cursor.execute('''
                UPDATE projects
                SET status = 'In Progress'
                WHERE id = ?
            ''', (project_id,))
        
        conn.commit()
        conn.close()
        
        return {
            "success": True,
            "task": {
                "id": task[0],
                "phase": task[1],
                "task_name": task[2],
                "is_completed": bool(task[3]),
                "created_at": task[4],
                "completed_at": task[5]
            },
            "project_progress": {
                "total_tasks": total_tasks,
                "completed_tasks": completed_tasks,
                "completion_percentage": round((completed_tasks / total_tasks) * 100, 1)
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error updating task: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update task: {str(e)}")

@app.get("/api/v1/projects/{project_id}")
async def get_project(project_id: int):
    """
    Get a specific project by ID, including its tasks and expenses
    """
    try:
        conn = sqlite3.connect('store_prices.db')
        conn.row_factory = sqlite3.Row  # Allows accessing columns by name
        cursor = conn.cursor()
        
        # Get project details
        cursor.execute('''
            SELECT id, name, location, project_type, budget, created_at, user_id, description, status
            FROM projects
            WHERE id = ?
        ''', (project_id,))
        
        project_row = cursor.fetchone()
        
        if not project_row:
            conn.close()
            raise HTTPException(status_code=404, detail="Project not found")
        
        project = dict(project_row)
        
        # Get project tasks
        cursor.execute('''
            SELECT id, phase, task_name, is_completed, created_at, completed_at
            FROM project_tasks
            WHERE project_id = ?
            ORDER BY phase, id
        ''', (project_id,))
        
        tasks = [dict(row) for row in cursor.fetchall()]

        # Get project expenses
        cursor.execute('''
            SELECT id, description, amount, category, date
            FROM expenses
            WHERE project_id = ?
            ORDER BY date DESC
        ''', (project_id,))
        
        expenses = [dict(row) for row in cursor.fetchall()]
        
        conn.close()
        
        # Combine project details with tasks and expenses
        project_with_details = {
            "project": project,
            "tasks": tasks,
            "expenses": expenses
        }
        
        print(f"✅ Retrieved project '{project['name']}' with {len(tasks)} tasks and {len(expenses)} expenses")
        return {
            "success": True,
            "data": project_with_details
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error getting project: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get project: {str(e)}")

@app.delete("/api/v1/projects/{project_id}")
async def delete_project(project_id: int, user_id: str):
    """
    Delete a project and all its associated tasks and expenses
    User must own the project to delete it
    """
    try:
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()

        # Check if project exists and belongs to the user
        cursor.execute('''
            SELECT id, name, user_id FROM projects 
            WHERE id = ?
        ''', (project_id,))
        
        project = cursor.fetchone()
        if not project:
            conn.close()
            raise HTTPException(status_code=404, detail="Project not found")
        
        # Verify ownership
        if project[2] != user_id:
            conn.close()
            raise HTTPException(status_code=403, detail="You don't have permission to delete this project")
        
        project_name = project[1]
        
        # Delete project (CASCADE will delete tasks and expenses automatically)
        cursor.execute('DELETE FROM projects WHERE id = ?', (project_id,))
        
        conn.commit()
        conn.close()
        
        print(f"✅ Deleted project {project_id}: {project_name}")
        
        return {
            "success": True,
            "message": f"Project '{project_name}' deleted successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error deleting project: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete project: {str(e)}")

@app.post("/api/v1/projects/{project_id}/expenses")
async def add_expense_to_project(project_id: int, expense: ExpenseCreate):
    """
    Add a new expense to a specific project
    """
    try:
        conn = sqlite3.connect('store_prices.db')
        cursor = conn.cursor()

        # Check if project exists
        cursor.execute("SELECT id FROM projects WHERE id = ?", (project_id,))
        if not cursor.fetchone():
            conn.close()
            raise HTTPException(status_code=404, detail="Project not found")

        # Insert new expense
        cursor.execute('''
            INSERT INTO expenses (project_id, description, amount, category, date)
            VALUES (?, ?, ?, ?, ?)
        ''', (
            project_id,
            expense.description,
            expense.amount,
            expense.category,
            expense.date
        ))
        
        expense_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        print(f"✅ Added expense {expense_id} to project {project_id}")
        
        return {
            "success": True,
            "message": "Expense added successfully",
            "expense_id": expense_id,
            "expense": {
                "id": expense_id,
                "project_id": project_id,
                **expense.dict()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error adding expense: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to add expense: {str(e)}")

@app.get("/api/v1/store-photo/{photo_reference}")
async def get_store_photo(photo_reference: str, maxwidth: int = 400):
    """
    Get a store photo using Google Places Photo API
    """
    try:
        url = "https://maps.googleapis.com/maps/api/place/photo"
        params = {
            'photoreference': photo_reference,
            'maxwidth': maxwidth,
            'key': GOOGLE_MAPS_API_KEY
        }
        
        # Redirect to Google's photo URL
        from fastapi.responses import RedirectResponse
        photo_url = f"{url}?{'&'.join([f'{k}={v}' for k, v in params.items()])}"
        return RedirectResponse(url=photo_url)
        
    except Exception as e:
        print(f"❌ Error getting store photo: {e}")
        raise HTTPException(status_code=404, detail="Photo not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)