# predict.py - Complete Concrete Grade Prediction Pipeline

import pandas as pd
import numpy as np
import joblib
import json
import os

print("🔧 Loading Concrete Grade Prediction Pipeline...")
print("="*50)

# 1. Load All Necessary Components
print("📂 Loading trained model components...")

try:
    # Load the trained model
    model = joblib.load('concrete_grade_model.pkl')
    print("✅ Trained model loaded successfully")
    
    # Load the target encoder for grade conversion
    target_encoder = joblib.load('target_encoder.pkl')
    print("✅ Target encoder loaded successfully")
    
    # Load feature names to ensure proper column ordering
    with open('feature_names.txt', 'r') as f:
        feature_names = [line.strip() for line in f.readlines()]
    print(f"✅ Feature names loaded: {len(feature_names)} features")
    
    # Load model metadata
    with open('model_info.json', 'r') as f:
        model_info = json.load(f)
    print(f"✅ Model info loaded: {model_info['model_type']}")
    
except FileNotFoundError as e:
    print(f"❌ Error: Required model files not found!")
    print("Please run 'train_model.py' first to generate the model files.")
    print(f"Missing file: {e}")
    exit(1)

# 2. Load the lookup datasets for materials and cost estimation
print("\n📊 Loading lookup datasets...")

try:
    # Load concrete mix design dataset for materials
    mix_df = pd.read_csv('concrete_mix_design_dataset.csv')
    print(f"✅ Mix design data loaded: {len(mix_df)} grades available")
    
    # Load cost estimation dataset
    cost_df = pd.read_csv('concrete_estimate_dataset.csv')
    print(f"✅ Cost estimation data loaded: {len(cost_df)} cost entries")
    
except FileNotFoundError as e:
    print(f"❌ Error: Required lookup datasets not found!")
    print("Make sure 'concrete_mix_design_dataset.csv' and 'concrete_estimate_dataset.csv' are in the same directory.")
    print(f"Missing file: {e}")
    exit(1)

print("✅ All components loaded successfully!")
print("="*50)

def preprocess_user_input(user_input):
    """
    Preprocesses user input to match the model's expected format
    """
    # Convert user input into a DataFrame
    input_df = pd.DataFrame([user_input])
    
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

def get_prediction(user_input):
    """
    Takes user input as a dictionary and returns a complete prediction with:
    - Concrete grade
    - Required materials 
    - Estimated cost
    """
    print(f"\n🔍 Processing prediction for: {user_input.get('Building_Type', 'Unknown')} building")
    
    # 2. Preprocess the user input to match model format
    try:
        processed_input = preprocess_user_input(user_input)
        print("✅ Input preprocessing completed")
    except Exception as e:
        return {"error": f"Input preprocessing failed: {str(e)}"}
    
    # 3. Make the concrete grade prediction
    try:
        # Get numeric prediction
        predicted_grade_numeric = model.predict(processed_input)[0]
        
        # Convert back to grade name
        predicted_grade = target_encoder.inverse_transform([predicted_grade_numeric])[0]
        
        # Get prediction confidence
        prediction_proba = model.predict_proba(processed_input)[0]
        confidence = max(prediction_proba) * 100
        
        print(f"✅ Predicted grade: {predicted_grade} (confidence: {confidence:.1f}%)")
        
    except Exception as e:
        return {"error": f"Grade prediction failed: {str(e)}"}

    # 4. Look up materials from the mix design dataset
    try:
        materials_row = mix_df[mix_df['Grade'] == predicted_grade]
        if materials_row.empty:
            print(f"⚠️ Warning: No materials data found for grade {predicted_grade}")
            materials = {"Grade": predicted_grade, "Note": "Materials data not available"}
        else:
            materials = materials_row.iloc[0].to_dict()
            print("✅ Materials information retrieved")
    except Exception as e:
        materials = {"error": f"Materials lookup failed: {str(e)}"}

    # 5. Calculate cost estimation
    try:
        cost_row = cost_df[cost_df['Grade'] == predicted_grade]
        if cost_row.empty:
            print(f"⚠️ Warning: No cost data found for grade {predicted_grade}")
            total_cost = "Cost data not available"
            rate_per_cum = 0
        else:
            rate_per_cum = cost_row['RMC_Rate_perCum'].iloc[0]
            
            # Calculate volume estimation
            built_up_area_sqft = user_input.get('Built_Up_Area_sqft', 1000)
            
            # Volume calculation: 0.07 cubic meters per sq. ft. (adjustable heuristic)
            estimated_volume_cum = built_up_area_sqft * 0.07
            total_cost_value = estimated_volume_cum * rate_per_cum
            
            total_cost = f"₹{total_cost_value:,.2f}"
            print(f"✅ Cost estimated: {total_cost} for {built_up_area_sqft} sq. ft.")
            
    except Exception as e:
        total_cost = f"Cost calculation failed: {str(e)}"
        built_up_area_sqft = user_input.get('Built_Up_Area_sqft', 1000)

    # 6. Format and return the complete results
    prediction_result = {
        "input_summary": {
            "Building_Type": user_input.get('Building_Type', 'N/A'),
            "Floors": user_input.get('Floors', 'N/A'),
            "Soil_Type": user_input.get('Soil_Type', 'N/A'),
            "Seismic_Zone": user_input.get('Seismic_Zone', 'N/A'),
            "Exposure": user_input.get('Exposure', 'N/A'),
            "Load_Type": user_input.get('Load_Type', 'N/A'),
            "Built_Up_Area_sqft": user_input.get('Built_Up_Area_sqft', 1000)
        },
        "prediction": {
            "concrete_grade": predicted_grade,
            "confidence_percentage": f"{confidence:.1f}%",
            "model_used": model_info['model_type']
        },
        "materials": materials,
        "cost_estimation": {
            "rate_per_cubic_meter": f"₹{rate_per_cum:,.2f}" if isinstance(rate_per_cum, (int, float)) else "N/A",
            "estimated_volume_cum": f"{estimated_volume_cum:.2f} cubic meters" if 'estimated_volume_cum' in locals() else "N/A",
            "total_estimated_cost": total_cost,
            "area_considered": f"{built_up_area_sqft} sq. ft."
        }
    }
    
    return prediction_result

# --- Example Usage and Testing ---
if __name__ == '__main__':
    print("\n🧪 TESTING PREDICTION PIPELINE")
    print("="*50)
    
    # Sample user inputs for testing different scenarios
    test_cases = [
        {
            'Building_Type': 'House',
            'Floors': 'G+2',
            'Soil_Type': 'Any',
            'Seismic_Zone': 'Zone II/III',
            'Exposure': 'Moderate',
            'Load_Type': 'Regular Household',
            'Built_Up_Area_sqft': 1500
        },
        {
            'Building_Type': 'Apartment',
            'Floors': 'G+4',
            'Soil_Type': 'Rocky',
            'Seismic_Zone': 'Zone IV',
            'Exposure': 'Severe',
            'Load_Type': 'Heavy Load',
            'Built_Up_Area_sqft': 2000
        },
        {
            'Building_Type': 'Villa',
            'Floors': 'G+3',
            'Soil_Type': 'Coastal Soil',
            'Seismic_Zone': 'Zone III/IV',
            'Exposure': 'Severe',
            'Load_Type': 'Regular+Solar Roof',
            'Built_Up_Area_sqft': 2500
        }
    ]
    
    # Test each case
    for i, test_input in enumerate(test_cases, 1):
        print(f"\n📋 TEST CASE {i}:")
        print("-" * 30)
        
        # Get prediction
        result = get_prediction(test_input)
        
        # Display results in a readable format
        if "error" in result:
            print(f"❌ Error: {result['error']}")
            continue
            
        print("\n🏗️ INPUT SUMMARY:")
        for key, value in result['input_summary'].items():
            print(f"  {key}: {value}")
            
        print(f"\n🎯 PREDICTION:")
        print(f"  Concrete Grade: {result['prediction']['concrete_grade']}")
        print(f"  Confidence: {result['prediction']['confidence_percentage']}")
        
        print(f"\n🧱 MATERIALS (per cubic meter):")
        materials = result['materials']
        if isinstance(materials, dict) and 'error' not in materials:
            for key, value in materials.items():
                if key != 'Grade':  # Skip the grade as it's already shown
                    print(f"  {key}: {value}")
        else:
            print(f"  {materials}")
            
        print(f"\n💰 COST ESTIMATION:")
        cost_info = result['cost_estimation']
        for key, value in cost_info.items():
            print(f"  {key.replace('_', ' ').title()}: {value}")
            
        print("-" * 50)
    
    print("\n🎉 Pipeline testing completed!")
    print("✅ The prediction system is ready for integration!")
    print("="*50)

# --- Function for API Integration ---
def predict_for_api(building_type, floors, soil_type, seismic_zone, exposure, load_type, built_up_area=1000):
    """
    Simplified function for API integration
    Returns a clean dictionary suitable for JSON response
    """
    user_input = {
        'Building_Type': building_type,
        'Floors': floors,
        'Soil_Type': soil_type,
        'Seismic_Zone': seismic_zone,
        'Exposure': exposure,
        'Load_Type': load_type,
        'Built_Up_Area_sqft': built_up_area
    }
    
    return get_prediction(user_input)