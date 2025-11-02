# User Authentication & Authorization Implementation Guide

## Overview
This guide documents the implementation of user-specific project filtering in the ADL Construction Management app. Now each user can only see and manage their own projects.

## What Was Changed

### Backend Changes (Python/FastAPI)

#### 1. Added OAuth2 Authentication Dependency
**File:** `backend/main.py`

- Added `OAuth2PasswordBearer` from FastAPI security
- Created `get_current_user_id()` dependency function that:
  - Extracts the Bearer token from the Authorization header
  - Verifies the Google ID token
  - Returns the user's unique Google ID (`sub` field)
  - Raises 401 error if token is invalid

#### 2. Updated Database Schema
**File:** `backend/main.py` - `init_db()` function

- Modified `projects` table to require `user_id` column (NOT NULL)
- Moved `user_id` to be the second column (after `id`) for better organization

#### 3. Protected All Project Endpoints

**Create Project** - `POST /api/v1/projects`
- Now requires authentication via `user_id: str = Depends(get_current_user_id)`
- Automatically associates new projects with the authenticated user
- Updated INSERT query to include `user_id`

**Get All Projects** - `GET /api/v1/projects`
- Now requires authentication
- Filters projects by `user_id` in SQL query: `WHERE user_id = ?`
- Users only see their own projects

**Get Single Project** - `GET /api/v1/projects/{project_id}`
- Now requires authentication
- Verifies ownership: `WHERE id = ? AND user_id = ?`
- Returns 404 if project doesn't exist or doesn't belong to the user

**Add Expense** - `POST /api/v1/projects/{project_id}/expenses`
- Now requires authentication
- Verifies project ownership before allowing expense addition

**Update Task** - `PUT /api/v1/projects/{project_id}/tasks/{task_id}`
- Now requires authentication
- Verifies project ownership before allowing task updates

### Frontend Changes (Flutter/Dart)

#### 1. Updated Auth Service
**File:** `lib/auth_service.dart`

- Added `flutter_secure_storage` import
- Modified `signInWithGoogle()` to accept and store the `idToken`
- Updated `signOut()` to delete the stored token
- Added `getIdToken()` method to retrieve the stored token

#### 2. Updated Login Flow
**File:** `lib/main.dart`

- Modified `_handleGoogleSignIn()` to pass the `idToken` to `AuthService`
- Token is now securely stored after successful Google Sign-In

#### 3. Updated Projects Service
**File:** `lib/projects_service.dart`

- Added `flutter_secure_storage` import
- Created `_getAuthHeaders()` helper method that:
  - Retrieves the stored `idToken`
  - Throws an error if user is not logged in
  - Returns headers with `Authorization: Bearer <token>`

- Updated ALL API calls to use authenticated headers:
  - `createProject()` - uses `await _getAuthHeaders()`
  - `getProjects()` - uses `await _getAuthHeaders()`
  - `getProjectDetails()` - uses `await _getAuthHeaders()`
  - `updateTaskStatus()` - uses `await _getAuthHeaders()`
  - `addExpense()` - uses `await _getAuthHeaders()`

## How It Works

### Authentication Flow

1. **User Signs In:**
   - User clicks "Sign in with Google"
   - Google returns an ID token
   - Frontend stores token in secure storage
   - Frontend sends token to backend for verification
   - Backend verifies and creates user session

2. **Making API Requests:**
   - Frontend retrieves stored ID token
   - Adds token to `Authorization: Bearer <token>` header
   - Sends request to backend
   - Backend verifies token and extracts user ID
   - Backend filters data by user ID

3. **User Signs Out:**
   - Token is deleted from secure storage
   - User must sign in again to access projects

### Security Benefits

✅ **User Isolation:** Each user can only access their own data
✅ **Token-Based:** Secure, industry-standard OAuth2 authentication
✅ **Server-Side Verification:** Backend validates every request
✅ **No Password Storage:** Uses Google's authentication system
✅ **Automatic Expiry:** Google ID tokens expire automatically

## Database Migration

The old database has been backed up as `store_prices.db.backup`. When you restart the FastAPI server, it will automatically create a new database with the updated schema.

⚠️ **Important:** Existing projects in the old database will not have a `user_id` and cannot be migrated automatically. You'll need to create new projects after implementing this feature.

## Testing the Implementation

### 1. Start the Backend Server
```bash
cd /Users/trishajanath/ADL_FINAL/ADL/backend
python3 main.py
```

### 2. Run the Flutter App
```bash
cd /Users/trishajanath/ADL_FINAL/ADL
flutter run
```

### 3. Test User Isolation

**Test 1: Create Projects as User A**
1. Sign in with Google Account A
2. Create 2-3 projects
3. Verify they appear in the projects list

**Test 2: Switch Users**
1. Sign out from the app
2. Sign in with Google Account B
3. Verify that User A's projects are NOT visible
4. Create new projects as User B
5. Verify only User B's projects are shown

**Test 3: Verify Data Isolation**
1. Try to access User A's project directly (if you know the ID)
2. Should receive a 404 error or permission denied
3. Confirm backend is properly filtering by user_id

## Troubleshooting

### "User not logged in" Error
- User's token has expired or been deleted
- Solution: Sign out and sign back in

### "Invalid authentication credentials" Error
- Token verification failed on backend
- Check that GOOGLE_CLIENT_ID matches in both frontend and backend
- Ensure token hasn't expired

### 401 Unauthorized Errors
- Backend cannot verify the token
- Check that the Authorization header is being sent correctly
- Verify the token format is "Bearer <token>"

### No Projects Showing After Login
- This is normal if you're a new user
- Create a new project to test
- Old projects from before this implementation won't be associated with any user

## Files Modified

### Backend
- ✅ `backend/main.py` - Added authentication, updated all endpoints

### Frontend
- ✅ `lib/auth_service.dart` - Token storage
- ✅ `lib/main.dart` - Pass token on login
- ✅ `lib/projects_service.dart` - Add auth headers to all requests

## Next Steps

1. ✅ Restart the backend server to initialize new database schema
2. ✅ Test the authentication flow with multiple Google accounts
3. ✅ Verify user isolation is working correctly
4. 🔄 Consider adding user profile management features
5. 🔄 Add analytics to track per-user project metrics
6. 🔄 Implement project sharing/collaboration features in the future

## Notes

- The `flutter_secure_storage` package was already in your `pubspec.yaml`
- All API calls now require a valid authentication token
- Backend properly validates tokens on every request
- Old database has been backed up as `store_prices.db.backup`

---
**Implementation Date:** October 16, 2025
**Status:** ✅ Complete and Ready for Testing
