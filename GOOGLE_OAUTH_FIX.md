# Google OAuth Fix - Client ID Mismatch

## Problem
Error: `PlatformException(sign_in_failed, org.openid.appauth.oauth_token_invalid_audience: The audience client and the client need to be in the same project, null)`

## Root Cause
The Flutter app and backend were using **different Google Client IDs** from different projects.

## Solution Applied

### Updated Client ID
Changed from: `137371359979-uteh19od42d7hjal2s75ifcbf8329i5i.apps.googleusercontent.com`
Changed to: `258088043167-tajnkjfkk56cv40jveigggju2qhaeutj.apps.googleusercontent.com`

### Files Updated
1. ✅ `lib/main.dart` - Flutter Google Sign-In configuration
2. ✅ `backend/main.py` - Backend token verification
3. ✅ `client_258088043167-tajnkjfkk56cv40jveigggju2qhaeutj.apps.googleusercontent.com.plist` - iOS configuration (already correct)

## Important Notes

### Understanding Google OAuth Client IDs

When you create a Google Cloud project, you can have multiple OAuth 2.0 client IDs:
- **Web application** - For server-side/backend
- **iOS** - For iOS apps  
- **Android** - For Android apps

### For Flutter Apps with Backend Verification

You need to use the **Web Client ID** in both:
1. Flutter app (`serverClientId` parameter in GoogleSignIn)
2. Backend (`GOOGLE_CLIENT_ID` for token verification)

The iOS/Android client IDs are used automatically by the Google Sign-In SDK for the native sign-in flow.

## Verification Steps

1. **Check your Google Cloud Console:**
   - Go to: https://console.cloud.google.com/apis/credentials
   - Make sure you're in the correct project
   - Find your Web application client ID
   - Use this ID in both Flutter and backend

2. **Ensure iOS configuration is correct:**
   - The plist file should have the iOS client ID
   - The Flutter code should have the Web client ID

3. **Test the sign-in:**
   - Restart your backend server
   - Rebuild your Flutter app
   - Try signing in with Google

## If Still Having Issues

### Check Bundle ID/Package Name
Make sure your iOS bundle ID matches what's configured in Google Cloud Console:
- Current bundle ID: `com.example.myApp` (from plist)
- Should match the authorized bundle ID in Google Cloud Console

### Verify OAuth Consent Screen
- Ensure the OAuth consent screen is configured
- Add test users if the app is in testing mode
- Make sure the app is not blocked

### Check Backend Logs
The backend will log authentication attempts. Check for:
- Token verification errors
- Invalid client ID errors
- User information after successful authentication

## Environment Variables

You can also use environment variables instead of hardcoding:

**Backend (.env file):**
```
GOOGLE_CLIENT_ID=258088043167-tajnkjfkk56cv40jveigggju2qhaeutj.apps.googleusercontent.com
```

**Flutter (config file):**
Create a `lib/config.dart`:
```dart
class AppConfig {
  static const String googleWebClientId = 
    '258088043167-tajnkjfkk56cv40jveigggju2qhaeutj.apps.googleusercontent.com';
  static const String serverUrl = 'http://127.0.0.1:8000';
}
```

## Next Steps

1. ✅ Client IDs are now consistent
2. 🔄 Restart the backend server
3. 🔄 Rebuild the Flutter app
4. ✅ Test Google Sign-In

If you still see issues, check the Google Cloud Console to ensure:
- The OAuth consent screen is published (or you're added as a test user)
- The iOS/Android app configurations are correct
- The bundle ID/package name matches your app
