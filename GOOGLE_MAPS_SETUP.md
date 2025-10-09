# 🗺️ **Google Maps & Places API Setup Guide**

## Prerequisites

You'll need to obtain your Google Maps API Key from the Google Cloud Console.

## Step 1: Get Google API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the following APIs:
   - **Google Maps SDK for iOS**
   - **Google Maps SDK for Android** 
   - **Google Places API**
   - **Geocoding API**

4. Create credentials (API Key)
5. Restrict the API key to your bundle identifier and APIs listed above

## Step 2: Configure API Key in Your App

### For iOS (Required):
Replace `YOUR_API_KEY_HERE` in `/ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Replace YOUR_API_KEY_HERE with your actual API key
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### For Google Places Service:
Replace `YOUR_API_KEY_HERE` in `/lib/google_places_service.dart`:

```dart
class GooglePlacesService {
  // Replace with your actual Google Places API key
  static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
  // ... rest of the code
}
```

## Step 3: Android Configuration (Optional)

If you plan to support Android, add your API key to `/android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR_ACTUAL_API_KEY_HERE"/>
    <!-- ... rest of your application -->
</application>
```

## Step 4: Test the Implementation

1. Run `flutter clean && flutter pub get`
2. Test on a physical iOS device (location services don't work well in simulator)
3. When you tap the search icon, the app should:
   - Request location permission
   - Get your current location
   - Search for nearby construction supply stores
   - Display results with distance, ratings, and action buttons

## Features Implemented

✅ **Location Permission Handling** - Automatic permission requests
✅ **Current Location Detection** - Uses GPS to find user location  
✅ **Nearby Store Search** - Finds construction supply stores within 5km
✅ **Text Search** - Search for specific stores or materials
✅ **Store Details** - Name, address, rating, distance, open/closed status
✅ **Navigation Integration** - Get directions via Google Maps
✅ **Call Integration** - Direct calling to store phone numbers
✅ **Distance Calculation** - Shows distance from current location

## Troubleshooting

- **No results found**: Check if your API key has Places API enabled
- **Location permission denied**: Guide users to enable location in Settings
- **API quota exceeded**: Monitor your API usage in Google Cloud Console
- **iOS simulator issues**: Test on physical device for location services

## API Usage Notes

- The app searches within a 5km radius for nearby stores
- Text searches expand to 10km radius
- Results are sorted by distance from user location
- API calls are made only when user initiates search

---

**Important**: Remember to keep your API key secure and never commit it to public repositories!