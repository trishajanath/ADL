# save_components.py - Utility script to check saved model components

import os
import joblib
import json

def check_saved_components():
    """
    Utility function to verify all model components are properly saved
    """
    print("🔍 Checking Saved Model Components...")
    print("="*40)
    
    components = [
        ("concrete_grade_model.pkl", "Trained RandomForest Model"),
        ("target_encoder.pkl", "Grade Label Encoder"),
        ("feature_names.txt", "Feature Names List"),
        ("model_info.json", "Model Metadata"),
        ("feature_importance.csv", "Feature Importance Analysis")
    ]
    
    all_present = True
    
    for filename, description in components:
        if os.path.exists(filename):
            file_size = os.path.getsize(filename)
            print(f"✅ {filename:<25} - {description} ({file_size} bytes)")
        else:
            print(f"❌ {filename:<25} - MISSING!")
            all_present = False
    
    print("="*40)
    
    if all_present:
        print("🎉 All model components are present!")
        
        # Load and display model info
        try:
            with open('model_info.json', 'r') as f:
                model_info = json.load(f)
            
            print("\n📊 Model Information:")
            for key, value in model_info.items():
                print(f"  {key}: {value}")
                
        except Exception as e:
            print(f"⚠️ Could not read model info: {e}")
            
        return True
    else:
        print("❌ Some components are missing!")
        print("💡 Run 'python train_model.py' to generate all components.")
        return False

def load_components_test():
    """
    Test loading all saved components to ensure they work
    """
    print("\n🧪 Testing Component Loading...")
    print("="*35)
    
    try:
        # Test model loading
        model = joblib.load('concrete_grade_model.pkl')
        print("✅ Model loaded successfully")
        
        # Test encoder loading
        encoder = joblib.load('target_encoder.pkl')
        print("✅ Target encoder loaded successfully")
        
        # Test feature names loading
        with open('feature_names.txt', 'r') as f:
            features = [line.strip() for line in f.readlines()]
        print(f"✅ Feature names loaded: {len(features)} features")
        
        print("🎉 All components load successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Component loading failed: {e}")
        return False

if __name__ == '__main__':
    print("🔧 Model Components Utility")
    print("="*50)
    
    # Check if components exist
    components_exist = check_saved_components()
    
    if components_exist:
        # Test loading components
        load_components_test()
        
        print("\n✅ All systems ready for prediction!")
    else:
        print("\n⚠️ Model components incomplete!")
        print("Run the following to generate all components:")
        print("1. python prepare_data.py")
        print("2. python train_model.py")
    
    print("="*50)