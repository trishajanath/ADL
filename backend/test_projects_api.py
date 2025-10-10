#!/usr/bin/env python3
"""
Test script for the Projects API endpoints
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_create_project():
    """Test creating a new project"""
    print("🧪 Testing Project Creation...")
    
    # Test data for a residential project
    project_data = {
        "name": "My Dream Home",
        "location": "Coimbatore, Tamil Nadu",
        "project_type": "Residential",
        "budget": 2500000.0,
        "description": "G+1 house construction with modern amenities"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/v1/projects", json=project_data)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Project created successfully!")
            print(f"   Project ID: {result['project_id']}")
            print(f"   Project Name: {result['project']['name']}")
            print(f"   Location: {result['project']['location']}")
            print(f"   Type: {result['project']['project_type']}")
            print(f"   Budget: ₹{result['project']['budget']:,.2f}")
            return result['project_id']
        else:
            print(f"❌ Failed to create project: {response.status_code}")
            print(f"   Error: {response.text}")
            return None
    
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend server. Please start the server first:")
        print("   cd backend && python main.py")
        return None
    except Exception as e:
        print(f"❌ Error testing project creation: {e}")
        return None

def test_get_projects():
    """Test getting all projects"""
    print("\n🧪 Testing Get All Projects...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/v1/projects")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved {result['count']} projects:")
            
            for project in result['projects']:
                print(f"   • {project['name']} ({project['project_type']}) - ₹{project['budget']:,.2f}")
                print(f"     Location: {project['location']}")
                print(f"     Status: {project['status']}")
                print(f"     Created: {project['created_at'][:19]}")  # Show date without milliseconds
                
        else:
            print(f"❌ Failed to get projects: {response.status_code}")
            print(f"   Error: {response.text}")
    
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend server")
        return None
    except Exception as e:
        print(f"❌ Error testing get projects: {e}")

def test_get_project_by_id(project_id):
    """Test getting a specific project by ID"""
    if not project_id:
        print("\n⏭️  Skipping get project by ID test (no project ID)")
        return
        
    print(f"\n🧪 Testing Get Project by ID ({project_id})...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/v1/projects/{project_id}")
        
        if response.status_code == 200:
            result = response.json()
            project = result['project']
            print("✅ Retrieved project details:")
            print(f"   ID: {project['id']}")
            print(f"   Name: {project['name']}")
            print(f"   Location: {project['location']}")
            print(f"   Type: {project['project_type']}")
            print(f"   Budget: ₹{project['budget']:,.2f}")
            print(f"   Description: {project['description']}")
            print(f"   Status: {project['status']}")
            
        else:
            print(f"❌ Failed to get project: {response.status_code}")
            print(f"   Error: {response.text}")
    
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend server")
    except Exception as e:
        print(f"❌ Error testing get project by ID: {e}")

def test_create_commercial_project():
    """Test creating a commercial project"""
    print("\n🧪 Testing Commercial Project Creation...")
    
    project_data = {
        "name": "Tech Office Complex",
        "location": "Chennai, Tamil Nadu", 
        "project_type": "Commercial",
        "budget": 15000000.0,
        "description": "5-floor commercial building with parking"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/v1/projects", json=project_data)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Commercial project created successfully!")
            print(f"   Project ID: {result['project_id']}")
            print(f"   Project Name: {result['project']['name']}")
            print(f"   Budget: ₹{result['project']['budget']:,.2f}")
            return result['project_id']
        else:
            print(f"❌ Failed to create commercial project: {response.status_code}")
            print(f"   Error: {response.text}")
            return None
    
    except Exception as e:
        print(f"❌ Error testing commercial project creation: {e}")
        return None

if __name__ == "__main__":
    print("🚀 Testing Projects API Endpoints")
    print("=" * 50)
    
    # Test creating a residential project
    residential_id = test_create_project()
    
    # Test creating a commercial project  
    commercial_id = test_create_commercial_project()
    
    # Test getting all projects
    test_get_projects()
    
    # Test getting specific projects by ID
    test_get_project_by_id(residential_id)
    test_get_project_by_id(commercial_id)
    
    print("\n🎉 Projects API Testing Complete!")
    print("\nNext steps:")
    print("1. Integrate the Projects API with your Flutter app")
    print("2. Add expense tracking to projects")
    print("3. Add project checklists")
    print("4. Add project timeline management")