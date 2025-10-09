# 🚀 Complete Integration Guide

## ✅ What's Been Done

Your FastAPI backend (`main.py`) now includes:

1. **Google Authentication** (already working)
2. **Concrete Grade Prediction** (newly added)
3. **Model Status Checking** (newly added)

## 📡 Available API Endpoints

### 1. Authentication
- `POST /api/v1/auth/google` - Google OAuth authentication

### 2. Prediction (NEW!)
- `POST /api/v1/predict` - Predict concrete grade
- `GET /api/v1/model/status` - Check if ML model is loaded

### 3. Utilities
- `GET /` - Health check
- `POST /api/v1/debug/request` - Debug requests

## 🔧 Step-by-Step Setup Guide

### Step 1: Install Dependencies
```bash
cd /Users/trishajanath/ADL_FINAL/ADL/backend
pip install requests
```

### Step 2: Start Your FastAPI Server
```bash
cd /Users/trishajanath/ADL_FINAL/ADL/backend
python main.py
```

You should see:
```
🔧 Loading ML model components...
✅ ML model components loaded successfully!
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 3: Find Your Computer's IP Address

**On macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**On Windows:**
```cmd
ipconfig
```

Look for something like `192.168.1.5` or `10.0.0.101`

### Step 4: Test the API
```bash
python test_api.py
```

## 📱 Flutter Integration

In your Flutter app, update the API base URL to use your computer's IP:

```dart
// Replace with your actual IP address
final String baseUrl = "http://192.168.1.5:8000"; // Your IP here!

// Example prediction request
Future<Map<String, dynamic>> predictConcreteGrade({
  required String buildingType,
  required String floors,
  required String soilType,
  required String seismicZone,
  required String exposure,
  required String loadType,
  required int builtUpArea,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/v1/predict'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'building_type': buildingType,
      'floors': floors,
      'soil_type': soilType,
      'seismic_zone': seismicZone,
      'exposure': exposure,
      'load_type': loadType,
      'built_up_area': builtUpArea,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Prediction failed: ${response.body}');
  }
}
```

## 📊 Example API Request/Response

**Request:**
```json
{
  "building_type": "House",
  "floors": "G+2",
  "soil_type": "Any",
  "seismic_zone": "Zone III",
  "exposure": "Moderate",
  "load_type": "Regular Household",
  "built_up_area": 1500
}
```

**Response:**
```json
{
  "success": true,
  "prediction": {
    "concrete_grade": "M30",
    "confidence_percentage": "42.0%"
  },
  "materials": {
    "Grade": "M30",
    "Target_Strength_Nmm2": 38.25,
    "Cement_kg": 360,
    "Sand_kg": 770,
    "Water_kg": 155,
    ...
  },
  "cost_estimation": {
    "total_estimated_cost": "₹640,500.00",
    "area_considered": "1500 sq. ft.",
    "estimated_volume_cum": "105.00 cubic meters"
  }
}
```

## 🔧 Troubleshooting

### Server Won't Start
1. Check all model files exist: `ls *.pkl *.txt *.csv`
2. Install missing packages: `pip install -r requirements.txt`

### Flutter Can't Connect
1. Use your computer's IP, not `localhost`
2. Make sure both devices are on the same Wi-Fi
3. Check firewall settings

### Prediction Errors
1. Check model status: `GET /api/v1/model/status`
2. Verify input format matches the expected schema

## 🎉 Ready to Go!

Your complete AI-powered concrete grade prediction system is now live and ready for your Flutter app!