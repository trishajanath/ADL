#!/usr/bin/env python3
"""
Test script to diagnose the /api/v1/predict endpoint error
"""
import requests
import json

# Test prediction request
url = "http://127.0.0.1:8000/api/v1/predict"

test_data = {
    "building_type": "Residential",
    "floors": "G+2",
    "soil_type": "Clay",
    "seismic_zone": "Zone III",
    "exposure": "Moderate",
    "load_type": "Dead Load + Live Load",
    "built_up_area": 1500
}

print("🧪 Testing prediction endpoint...")
print(f"📤 Sending data: {json.dumps(test_data, indent=2)}")

try:
    response = requests.post(url, json=test_data)
    print(f"\n📥 Response Status: {response.status_code}")
    print(f"📥 Response Headers: {dict(response.headers)}")
    print(f"📥 Response Body:")
    
    try:
        print(json.dumps(response.json(), indent=2))
    except:
        print(response.text)
        
except Exception as e:
    print(f"❌ Error: {e}")
