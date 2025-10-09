import os
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests
from dotenv import load_dotenv
import json

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

class Token(BaseModel):
    token: str = None
    idToken: str = None  # Flutter Google Sign In might send this
    id_token: str = None  # Alternative naming
    accessToken: str = None

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)