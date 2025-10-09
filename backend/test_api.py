# test_api.py - Simple script to test the prediction API

import requests
import json

# Define a standard timeout for API requests to prevent indefinite hangs.
REQUEST_TIMEOUT = 30

def test_prediction_api():
 """
 Test the prediction API endpoint
 """
 # API endpoint
 url = "http://localhost:8000/api/v1/predict"
 
 # Sample prediction request
 test_data = {
 "building_type": "House",
 "floors": "G+2",
 "soil_type": "Any",
 "seismic_zone": "Zone III",
 "exposure": "Moderate", 
 "load_type": "Regular Household",
 "built_up_area": 1500
 }
 
 try:
 print("🧪 Testing prediction API...")
 print(f" 🌐 Sending request to: {url}")
 print(f"📤 Request data: {json.dumps(test_data, indent=2)}")
 
 # Send POST request with a timeout to prevent indefinite hangs
 response = requests.post(url, json=test_data, timeout=REQUEST_TIMEOUT)
 
 print(f"\n📨 Response status: {response.status_code}")
 
 if response.status_code == 200:
 result = response.json()
 print(" ✅ Prediction successful!")
 print(f"📋 Response: {json.dumps(result, indent=2)}")
 else:
 print(" ❌ Prediction failed!")
 print(f"Error: {response.text}")

 except requests.exceptions.Timeout:
 print(f" ❌ Connection timed out! The server did not respond within {REQUEST_TIMEOUT} seconds.")
 except requests.exceptions.ConnectionError:
 print(" ❌ Connection error! Make sure the FastAPI server is running:")
 print(" python main.py")
 except Exception as e:
 print(f" ❌ Error: {e}")

def test_model_status():
 """
 Test the model status endpoint
 """
 url = "http://localhost:8000/api/v1/model/status"
 
 try:
 print("\n 🔍 Checking model status...")
 # Send GET request with a timeout to prevent indefinite hangs
 response = requests.get(url, timeout=REQUEST_TIMEOUT)
 
 if response.status_code == 200:
 status = response.json()
 print(" ✅ Model status retrieved!")
 print(f" 📊 Status: {json.dumps(status, indent=2)}")
 else:
 print(" ❌ Status check failed!")
 print(f"Error: {response.text}")

 except requests.exceptions.Timeout:
 print(f" ❌ Connection timed out! The server did not respond within {REQUEST_TIMEOUT} seconds.")
 except requests.exceptions.ConnectionError:
 print(" ❌ Connection error! Make sure the FastAPI server is running.")
 except Exception as e:
 print(f" ❌ Error: {e}")

if __name__ == "__main__":
 print("🚀 API Testing Suite")
 print("="*50)
 
 # Test model status first
 test_model_status()
 
 # Test prediction
 test_prediction_api()
 
 print("\n" + "="*50)
 print("💡 To run the server: python main.py")
 print("💡 Server should be running on: http://localhost:8000")
