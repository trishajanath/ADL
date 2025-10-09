# Python script for preparing concrete grade prediction data

# 1. Import necessary libraries for data manipulation and preprocessing.
import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
import warnings
warnings.filterwarnings('ignore')

# 2. Load the dataset from 'Grade_Requirement_Dataset.csv' into a DataFrame.
# Please ensure the CSV file is in the same directory as this script.
df = pd.read_csv('Grade_Requirement_Dataset.csv')

# 3. Display basic information about the dataset
print("Dataset Information:")
print("="*50)
print(f"Dataset shape: {df.shape}")
print(f"Columns: {list(df.columns)}")
print("\nData types:")
print(df.dtypes)
print("\nFirst 5 rows:")
print(df.head())
print("\n" + "="*50 + "\n")

# 4. Data Quality Check - Check for missing values and duplicates
print("Data Quality Check:")
print("="*30)
print("Missing values per column:")
print(df.isnull().sum())
print(f"\nDuplicate rows: {df.duplicated().sum()}")
print(f"Unique values in target column: {df['Recommended_Grade'].nunique()}")
print(f"Target distribution:\n{df['Recommended_Grade'].value_counts()}")
print("\n" + "="*30 + "\n")

# 5. Feature Engineering - Extract numerical information from Floor data
print("Feature Engineering:")
print("="*25)
# Extract floor number from 'G+X' format (using raw string to avoid regex warning)
df['Floor_Number'] = df['Floors'].str.extract(r'(\d+)').astype(int)
print("Extracted floor numbers from 'Floors' column:")
print(df[['Floors', 'Floor_Number']].head())
print("\n" + "="*25 + "\n")

# 6. Select the feature columns (inputs for the model) and the target column.
# The features are: 'Building_Type', 'Floor_Number', 'Soil_Type', 'Seismic_Zone', 'Exposure', 'Load_Type'.
# The target is: 'Recommended_Grade'.
features = ['Building_Type', 'Floor_Number', 'Soil_Type', 'Seismic_Zone', 'Exposure', 'Load_Type']
X = df[features].copy()
y = df['Recommended_Grade'].copy()

# Display the separated features and target variable.
print("Selected Features and Target:")
print("="*35)
print("Features (X):")
print(X.head())
print("\nTarget (y):")
print(y.head())
print("\n" + "="*35 + "\n")

# 7. Advanced Preprocessing Steps
print("Advanced Preprocessing:")
print("="*30)

# 7a. Handle categorical encoding with proper preprocessing
# Separate numerical and categorical features
numerical_features = ['Floor_Number']
categorical_features = ['Building_Type', 'Soil_Type', 'Seismic_Zone', 'Exposure', 'Load_Type']

print(f"Numerical features: {numerical_features}")
print(f"Categorical features: {categorical_features}")

# 7b. Apply one-hot encoding to categorical features
X_categorical = pd.get_dummies(X[categorical_features], prefix=categorical_features)
X_numerical = X[numerical_features]

# Combine numerical and encoded categorical features
X_processed = pd.concat([X_numerical, X_categorical], axis=1)

print(f"\nOriginal feature count: {len(features)}")
print(f"After one-hot encoding: {X_processed.shape[1]} features")
print("\nFirst 3 rows of processed features:")
print(X_processed.head(3))
print("\n" + "="*30 + "\n")

# 8. Target Variable Processing
print("Target Variable Processing:")
print("="*35)

# Create label encoder for target variable to convert to numerical format
target_encoder = LabelEncoder()
y_encoded = target_encoder.fit_transform(y)

print("Original target values:")
print(y.unique())
print("\nEncoded target values:")
print(np.unique(y_encoded))
print("\nTarget mapping:")
for i, grade in enumerate(target_encoder.classes_):
    print(f"{grade} -> {i}")
print("\n" + "="*35 + "\n")

# 9. Feature Scaling (Standardization)
print("Feature Scaling:")
print("="*20)

# Apply standard scaling to numerical features
scaler = StandardScaler()
X_scaled = X_processed.copy()

# Scale only numerical features (Floor_Number in this case)
if len(numerical_features) > 0:
    X_scaled[numerical_features] = scaler.fit_transform(X_processed[numerical_features])
    print("Applied StandardScaler to numerical features")
    print(f"Mean of Floor_Number after scaling: {X_scaled['Floor_Number'].mean():.6f}")
    print(f"Std of Floor_Number after scaling: {X_scaled['Floor_Number'].std():.6f}")
else:
    print("No numerical features to scale")
print("\n" + "="*20 + "\n")

# 10. Train-Test Split
print("Data Splitting:")
print("="*20)

# Check if we have enough samples for stratified split
min_class_count = min(np.bincount(y_encoded))
total_samples = len(y_encoded)

if min_class_count < 2 or total_samples < 4:
    print(f"Warning: Dataset too small ({total_samples} samples) or some classes have too few samples.")
    print("Using simple random split instead of stratified split.")
    
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y_encoded, 
        test_size=0.3,  # Use 30% for test to ensure at least some samples in test set
        random_state=42
    )
else:
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y_encoded, 
        test_size=0.2, 
        random_state=42, 
        stratify=y_encoded
    )

print(f"Training set size: {X_train.shape[0]} samples")
print(f"Test set size: {X_test.shape[0]} samples")
print(f"Feature dimensions: {X_train.shape[1]} features")
print("\nTraining set target distribution:")
unique, counts = np.unique(y_train, return_counts=True)
for val, count in zip(unique, counts):
    grade_name = target_encoder.inverse_transform([val])[0]
    print(f"  {grade_name}: {count} samples")
    
print("\nTest set target distribution:")
unique_test, counts_test = np.unique(y_test, return_counts=True)
for val, count in zip(unique_test, counts_test):
    grade_name = target_encoder.inverse_transform([val])[0]
    print(f"  {grade_name}: {count} samples")
print("\n" + "="*20 + "\n")

# 11. Final Summary and Data Export
print("Preprocessing Complete - Summary:")
print("="*40)
print(f"✓ Loaded {df.shape[0]} samples with {df.shape[1]} original features")
print(f"✓ Extracted numerical feature from 'Floors' column")
print(f"✓ Applied one-hot encoding to {len(categorical_features)} categorical features")
print(f"✓ Encoded target variable with {len(target_encoder.classes_)} classes")
print(f"✓ Applied feature scaling to numerical features")
print(f"✓ Split data: {X_train.shape[0]} train, {X_test.shape[0]} test samples")
print(f"✓ Final feature count: {X_processed.shape[1]} features")

# Save processed data for model training
print("\nSaving processed data...")
pd.DataFrame(X_train).to_csv('X_train_processed.csv', index=False)
pd.DataFrame(X_test).to_csv('X_test_processed.csv', index=False)
pd.DataFrame(y_train).to_csv('y_train_processed.csv', index=False)
pd.DataFrame(y_test).to_csv('y_test_processed.csv', index=False)

# Save feature names and target encoder for future use
feature_names = X_processed.columns.tolist()
with open('feature_names.txt', 'w') as f:
    for name in feature_names:
        f.write(f"{name}\n")

print("✓ Saved processed datasets and metadata")
print("\nFiles created:")
print("  - X_train_processed.csv")
print("  - X_test_processed.csv") 
print("  - y_train_processed.csv")
print("  - y_test_processed.csv")
print("  - feature_names.txt")
print("\n" + "="*40)