const express = require('express');
const cors = require('cors');
const { OAuth2Client } = require('google-auth-library');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Replace with your actual Google OAuth client ID
const GOOGLE_CLIENT_ID = '145339438883-oni0f6o44s78cuaj7se2oh44jc0gt4l7.apps.googleusercontent.com';
const client = new OAuth2Client(GOOGLE_CLIENT_ID);

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Building Platform Backend Server is running!',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Google OAuth verification endpoint
app.post('/api/v1/auth/google', async (req, res) => {
  try {
    const { token } = req.body;
    
    console.log('Received Google OAuth token for verification');
    
    if (!token) {
      return res.status(400).json({ 
        error: 'No token provided',
        message: 'Google ID token is required'
      });
    }

    // Verify the Google ID token
    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: GOOGLE_CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    const userId = payload['sub'];
    const email = payload['email'];
    const name = payload['name'];
    const picture = payload['picture'];
    
    console.log(`User authenticated: ${name} (${email})`);
    
    // Here you would typically:
    // 1. Check if user exists in your database
    // 2. Create user if they don't exist
    // 3. Generate your own session token
    // 4. Return user data and session token
    
    // For now, we'll return a simple success response
    const sessionToken = 'session_' + Date.now() + '_' + userId.slice(-8);
    
    res.json({
      success: true,
      message: 'Google authentication successful',
      token: sessionToken,
      user: {
        id: userId,
        email: email,
        name: name,
        picture: picture,
        verified: payload['email_verified']
      }
    });
    
  } catch (error) {
    console.error('Google OAuth verification error:', error);
    res.status(401).json({ 
      error: 'Authentication failed',
      message: 'Invalid Google token',
      details: error.message
    });
  }
});

// User profile endpoint (protected)
app.get('/api/v1/user/profile', (req, res) => {
  // In a real app, you'd verify the session token here
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No valid authorization token' });
  }
  
  res.json({
    message: 'User profile data',
    // Return user profile data here
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: 'Something went wrong on the server'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Building Platform Backend Server running on port ${PORT}`);
  console.log(`📱 Ready to handle Flutter app requests`);
  console.log(`🔐 Google OAuth endpoint: http://localhost:${PORT}/api/v1/auth/google`);
  console.log(`💻 Health check: http://localhost:${PORT}/`);
});

module.exports = app;
