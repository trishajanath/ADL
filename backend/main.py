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
from typing import Optional

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
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "137371359979-uteh19od42d7hjal2s75ifcbf8329i5i.apps.googleusercontent.com")

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

@app.get("/")
def read_root():
    return {"message": "Building Platform FastAPI Backend is running!"}

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)