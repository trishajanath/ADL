#!/usr/bin/env python3
"""
Final verification script - simulates Flutter app connection
Tests the exact same endpoints that your Flutter app will use
"""
import requests
import json
import time

# This is the same IP that your Flutter app will use
FLUTTER_API_URL = "http://172.20.10.2:8000"
LOCALHOST_URL = "http://localhost:8000"

def test_flutter_connection():
    """Test connection exactly as Flutter app will"""
    print("🧪 Testing Flutter App Connection...")
    print("=" * 50)
    
    # Test 1: Basic connection (what Flutter testConnection() does)
    print("1. Testing basic connection...")
    try:
        response = requests.get(f"{FLUTTER_API_URL}/", timeout=5)
        if response.status_code == 200:
            print("   ✅ Connection successful!")
        else:
            print(f"   ❌ Connection failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Connection error: {e}")
        print("   🔧 Trying localhost instead...")
        try:
            response = requests.get(f"{LOCALHOST_URL}/", timeout=5)
            if response.status_code == 200:
                print("   ✅ Localhost connection works!")
                print("   ⚠️  Note: Update Flutter service to use localhost for testing")
            return False
        except:
            print("   ❌ Both connections failed")
            return False
    
    # Test 2: Model status (what Flutter checkModelStatus() does)
    print("\n2. Testing model status...")
    try:
        response = requests.get(f"{FLUTTER_API_URL}/api/v1/model/status", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Model loaded: {data['model_loaded']}")
            print(f"   ✅ Features count: {data['feature_count']}")
            print(f"   ✅ Available grades: {data['available_grades']}")
        else:
            print(f"   ❌ Status check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Status error: {e}")
        return False
    
    # Test 3: Prediction (what Flutter predictConcreteGrade() does)
    print("\n3. Testing prediction (exactly like Flutter app)...")
    flutter_request = {
        "building_type": "House",
        "floors": "G+2",
        "soil_type": "Any", 
        "seismic_zone": "Zone III",
        "exposure": "Moderate",
        "load_type": "Regular Household",
        "built_up_area": 1500
    }
    
    try:
        print(f"   📤 Sending request: {json.dumps(flutter_request, indent=6)}")
        
        start_time = time.time()
        response = requests.post(
            f"{FLUTTER_API_URL}/api/v1/predict",
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            json=flutter_request,
            timeout=30
        )
        end_time = time.time()
        
        response_time = round((end_time - start_time) * 1000, 2)
        print(f"   ⏱️  Response time: {response_time}ms")
        
        if response.status_code == 200:
            result = response.json()
            print("   ✅ Prediction successful!")
            print(f"   🎯 Grade: {result['prediction']['concrete_grade']}")
            print(f"   📊 Confidence: {result['prediction']['confidence_percentage']}")
            print(f"   💰 Cost: {result['cost_estimation']['total_estimated_cost']}")
            print(f"   📏 Volume: {result['cost_estimation']['estimated_volume_cum']}")
            return True
        else:
            print(f"   ❌ Prediction failed: {response.status_code}")
            print(f"   📄 Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Prediction error: {e}")
        return False

def test_multiple_requests():
    """Test multiple concurrent requests like a real app"""
    print("\n4. Testing multiple concurrent requests...")
    
    test_cases = [
        {"building_type": "House", "floors": "G+1", "built_up_area": 1000},
        {"building_type": "Commercial", "floors": "G+3", "built_up_area": 2500},
        {"building_type": "Apartment", "floors": "G+5", "built_up_area": 1800},
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"   Test {i}: {test_case['building_type']} - {test_case['floors']}")
        
        request_data = {
            **test_case,
            "soil_type": "Any",
            "seismic_zone": "Zone III", 
            "exposure": "Moderate",
            "load_type": "Regular Household"
        }
        
        try:
            response = requests.post(
                f"{FLUTTER_API_URL}/api/v1/predict",
                json=request_data,
                timeout=15
            )
            
            if response.status_code == 200:
                result = response.json()
                grade = result['prediction']['concrete_grade']
                confidence = result['prediction']['confidence_percentage']
                print(f"      ✅ {grade} ({confidence} confidence)")
            else:
                print(f"      ❌ Failed: {response.status_code}")
                
        except Exception as e:
            print(f"      ❌ Error: {e}")

def main():
    print("🎯 FINAL FLUTTER APP VERIFICATION")
    print("Testing exact same API calls your Flutter app will make...")
    print("\n")
    
    success = test_flutter_connection()
    
    if success:
        test_multiple_requests()
        print("\n" + "=" * 50)
        print("🎉 SUCCESS! Your Flutter app is ready to connect!")
        print("\n✅ Next steps:")
        print("1. Run your Flutter app")
        print("2. Test the prediction feature")
        print("3. Verify results match these tests")
        print("\n🔧 If connection fails from Flutter:")
        print("- Make sure phone and computer are on same WiFi")
        print("- Check IP address in concrete_prediction_service.dart")
        print("- Verify server is still running on port 8000")
    else:
        print("\n" + "=" * 50)
        print("❌ CONNECTION ISSUES DETECTED")
        print("\n🔧 Troubleshooting:")
        print("1. Make sure the server is running: python main.py")
        print("2. Check if your computer's IP changed")
        print("3. Test with localhost first, then network IP")
        print("4. Ensure firewall allows port 8000")

if __name__ == "__main__":
    main()