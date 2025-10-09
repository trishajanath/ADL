#!/usr/bin/env python3
"""
Simple client test for the running ML API server
"""
import requests
import json

BASE_URL = "http://172.20.10.2:8000"

def test_connection():
    """Test basic connection to server"""
    try:
        response = requests.get(f"{BASE_URL}/", timeout=5)
        print(f"✅ Connection test: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

def test_model_status():
    """Test model status endpoint"""
    try:
        response = requests.get(f"{BASE_URL}/api/v1/model/status", timeout=5)
        print(f"✅ Model status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Model loaded: {data.get('model_loaded', 'Unknown')}")
            print(f"   Features: {data.get('feature_count', 'Unknown')}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Model status failed: {e}")
        return False

def test_prediction():
    """Test prediction endpoint"""
    try:
        test_data = {
            "building_type": "House",
            "floors": "G+2",
            "soil_type": "Any",
            "seismic_zone": "Zone III",
            "exposure": "Moderate",
            "load_type": "Regular Household",
            "built_up_area": 1500
        }
        
        print(f"📤 Sending prediction request...")
        print(f"   Data: {json.dumps(test_data, indent=2)}")
        
        response = requests.post(
            f"{BASE_URL}/api/v1/predict",
            json=test_data,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        print(f"📨 Prediction response: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Prediction successful!")
            print(f"   Grade: {result['prediction']['concrete_grade']}")
            print(f"   Confidence: {result['prediction']['confidence_percentage']}")
            print(f"   Cost: {result['cost_estimation']['total_estimated_cost']}")
            return True
        else:
            print(f"❌ Prediction failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        return False

def main():
    print("🧪 Testing ML API Server...")
    print("=" * 50)
    
    # Test connection
    if not test_connection():
        print("❌ Cannot connect to server. Make sure it's running on port 8000")
        return
    
    print()
    
    # Test model status
    if not test_model_status():
        print("❌ Model status check failed")
        return
    
    print()
    
    # Test prediction
    if not test_prediction():
        print("❌ Prediction test failed")
        return
    
    print()
    print("🎉 All tests passed! API is ready for production!")

if __name__ == "__main__":
    main()