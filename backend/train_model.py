# Python script for building and training the concrete grade prediction model

# 1. Import necessary libraries for model training and evaluation
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.preprocessing import LabelEncoder
import joblib
import os

print("🚀 Concrete Grade Prediction Model Training")
print("="*50)

# 2. Load the preprocessed data from prepare_data.py
print("📂 Loading preprocessed data...")

try:
    # Load the processed training and testing data
    X_train = pd.read_csv('X_train_processed.csv')
    X_test = pd.read_csv('X_test_processed.csv')
    y_train = pd.read_csv('y_train_processed.csv').iloc[:, 0]  # Extract the series
    y_test = pd.read_csv('y_test_processed.csv').iloc[:, 0]    # Extract the series
    
    # Load feature names
    with open('feature_names.txt', 'r') as f:
        feature_names = [line.strip() for line in f.readlines()]
    
    print("✅ Data loaded successfully!")
    print(f"Training set: {X_train.shape[0]} samples, {X_train.shape[1]} features")
    print(f"Test set: {X_test.shape[0]} samples, {X_test.shape[1]} features")
    print(f"Feature names: {len(feature_names)} features")
    
except FileNotFoundError as e:
    print("❌ Error: Preprocessed data files not found!")
    print("Please run 'prepare_data.py' first to generate the processed data.")
    print(f"Missing file: {e}")
    exit(1)

print("\n" + "="*50 + "\n")

# 3. Recreate the target encoder to understand class mappings
print("🎯 Setting up target variable mappings...")

# Load original data to recreate the label encoder
df_original = pd.read_csv('Grade_Requirement_Dataset.csv')
target_encoder = LabelEncoder()
target_encoder.fit(df_original['Recommended_Grade'])

print("Concrete grade mappings:")
for i, grade in enumerate(target_encoder.classes_):
    print(f"  {grade} -> {i}")

print(f"\nTraining data target distribution:")
unique_train, counts_train = np.unique(y_train, return_counts=True)
for val, count in zip(unique_train, counts_train):
    grade_name = target_encoder.inverse_transform([val])[0]
    print(f"  {grade_name}: {count} samples")

print("\n" + "="*30 + "\n")

# 4. Create and configure the Random Forest model
print("🌲 Initializing Random Forest Classifier...")

# Enhanced Random Forest with optimized parameters
model = RandomForestClassifier(
    n_estimators=100,        # Number of trees in the forest
    max_depth=10,           # Maximum depth of trees (prevent overfitting)
    min_samples_split=2,    # Minimum samples required to split a node
    min_samples_leaf=1,     # Minimum samples required at leaf node
    random_state=42,        # For reproducible results
    class_weight='balanced' # Handle class imbalance
)

print("Model configuration:")
print(f"  - Trees: {model.n_estimators}")
print(f"  - Max depth: {model.max_depth}")
print(f"  - Random state: {model.random_state}")
print(f"  - Class weight: {model.class_weight}")

print("\n" + "="*30 + "\n")

# 5. Train the model
print("🛠️ Training the Random Forest model...")
print("This may take a moment...")

model.fit(X_train, y_train)

print("✅ Model training completed successfully!")
print("\n" + "="*30 + "\n")


# 6. Evaluate the model's performance
print("📊 Evaluating model performance...")

# Make predictions on the test set
y_pred = model.predict(X_test)

# Calculate accuracy
accuracy = accuracy_score(y_test, y_pred)

print(f"🎯 Model Accuracy: {accuracy * 100:.2f}%")

# Detailed evaluation metrics
print("\n📈 Detailed Classification Report:")
print("-" * 40)

# Convert numeric predictions back to grade names for better readability
y_test_grades = target_encoder.inverse_transform(y_test)
y_pred_grades = target_encoder.inverse_transform(y_pred)

print(classification_report(y_test_grades, y_pred_grades, zero_division=0))

# Confusion Matrix
print("\n🔢 Confusion Matrix:")
print("-" * 25)
cm = confusion_matrix(y_test_grades, y_pred_grades, labels=target_encoder.classes_)
print("Actual vs Predicted:")
print(f"{'':>8}", end="")
for grade in target_encoder.classes_:
    print(f"{grade:>6}", end="")
print()

for i, actual_grade in enumerate(target_encoder.classes_):
    print(f"{actual_grade:>8}", end="")
    for j in range(len(target_encoder.classes_)):
        print(f"{cm[i][j]:>6}", end="")
    print()

print("\n" + "="*30 + "\n")

# 7. Feature Importance Analysis
print("🔍 Feature Importance Analysis:")
print("-" * 35)

# Get feature importances
feature_importance = pd.DataFrame({
    'feature': feature_names,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False)

print("Top 10 most important features:")
for idx, row in feature_importance.head(10).iterrows():
    print(f"  {row['feature']:<25}: {row['importance']:.4f}")

print("\n" + "="*30 + "\n")

# 8. Model Persistence - Save the trained model
print("💾 Saving the trained model and components...")

# Save the trained model
joblib.dump(model, 'concrete_grade_model.pkl')

# Save the target encoder
joblib.dump(target_encoder, 'target_encoder.pkl')

# Save feature importance
feature_importance.to_csv('feature_importance.csv', index=False)

# Save model metadata
model_info = {
    'model_type': 'RandomForestClassifier',
    'n_estimators': model.n_estimators,
    'accuracy': accuracy,
    'features_count': len(feature_names),
    'classes': target_encoder.classes_.tolist(),
    'training_samples': len(X_train),
    'test_samples': len(X_test)
}

import json
with open('model_info.json', 'w') as f:
    json.dump(model_info, f, indent=2)

print("✅ Model and components saved successfully!")
print("\nFiles created:")
print("  - concrete_grade_model.pkl    (trained model)")
print("  - target_encoder.pkl          (label encoder)")
print("  - feature_importance.csv      (feature analysis)")
print("  - model_info.json            (model metadata)")

print("\n" + "="*50)

# 9. Test Prediction Function
print("🧪 Testing Prediction Pipeline...")

def predict_concrete_grade(building_type, floors, soil_type, seismic_zone, exposure, load_type):
    """
    Predict concrete grade for given building specifications
    """
    # Create input dataframe
    input_data = pd.DataFrame({
        'Building_Type': [building_type],
        'Floors': [floors],
        'Soil_Type': [soil_type], 
        'Seismic_Zone': [seismic_zone],
        'Exposure': [exposure],
        'Load_Type': [load_type]
    })
    
    # Feature engineering (extract floor number)
    input_data['Floor_Number'] = input_data['Floors'].str.extract(r'(\d+)').astype(int)
    
    # Select features and apply one-hot encoding
    features = ['Building_Type', 'Floor_Number', 'Soil_Type', 'Seismic_Zone', 'Exposure', 'Load_Type']
    X_input = input_data[features]
    
    # One-hot encode categorical features
    categorical_features = ['Building_Type', 'Soil_Type', 'Seismic_Zone', 'Exposure', 'Load_Type']
    X_categorical = pd.get_dummies(X_input[categorical_features], prefix=categorical_features)
    X_numerical = X_input[['Floor_Number']]
    X_processed = pd.concat([X_numerical, X_categorical], axis=1)
    
    # Align with training features
    for feature in feature_names:
        if feature not in X_processed.columns:
            X_processed[feature] = 0
    
    X_processed = X_processed[feature_names]
    
    # Make prediction
    prediction_numeric = model.predict(X_processed)[0]
    prediction_grade = target_encoder.inverse_transform([prediction_numeric])[0]
    
    # Get prediction probability
    prediction_proba = model.predict_proba(X_processed)[0]
    confidence = max(prediction_proba) * 100
    
    return prediction_grade, confidence

# Test with a sample prediction
print("\nSample Prediction Test:")
test_grade, confidence = predict_concrete_grade(
    building_type="House",
    floors="G+2", 
    soil_type="Any",
    seismic_zone="Zone III",
    exposure="Moderate",
    load_type="Regular Household"
)

print(f"Input: House, G+2, Any soil, Zone III, Moderate exposure, Regular Household")
print(f"Predicted Grade: {test_grade}")
print(f"Confidence: {confidence:.1f}%")

print("\n" + "="*50)
print("🎉 Model Training Complete!")
print("The model is ready for concrete grade predictions!")
print("="*50)