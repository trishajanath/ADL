# Valid Prediction API Values

This document lists the exact values that the ML model accepts for prediction requests.

## Building Type
- `House`
- `Apartment`
- `Villa`
- `Office`
- `Mall`
- `Hospital`
- `School`

## Floors
Format: `G+X` where X is a number
- `G` (Ground floor only)
- `G+1`
- `G+2`
- `G+3`
- `G+4`
- `G+5`
- `G+6+`

## Soil Type
**IMPORTANT**: Only these values are recognized:
- `Any`
- `Rocky`
- `Mixed`
- `Coastal Soil`

**NOT ACCEPTED**: `Clay`, `Sandy`, `Clayey` (these are NOT in the training data!)

## Seismic Zone
- `Zone II`
- `Zone II/III`
- `Zone III`
- `Zone III/IV`
- `Zone IV`
- `Zone IV/V`
- `Zone V`

## Exposure
- `Mild`
- `Moderate`
- `Severe`
- `Very Severe`
- `Extreme`

## Load Type
**Residential:**
- `Regular Household` - Normal residential loads
- `Regular+Parking` - Residential with parking
- `Regular+Solar Roof` - Residential with solar panels

**Commercial/Heavy:**
- `Heavy Equipment` - Heavy machinery/equipment
- `Heavy Load` - High foot traffic or heavy loads
- `Heavy+Parking` - Heavy loads with parking areas

## Built-up Area
- Integer value in square feet
- Minimum: 500
- Typical residential: 1000-5000
- Typical commercial: 5000-50000+

## Example Valid Request

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

## Common Mapping Errors

### ❌ WRONG → ✅ CORRECT

**Soil Type:**
- ❌ `"Clay"` → ✅ `"Any"`
- ❌ `"Sandy"` → ✅ `"Any"`
- ❌ `"Clayey"` → ✅ `"Any"`

**Load Type:**
- ❌ `"Heavy Machinery"` → ✅ `"Heavy Equipment"`
- ❌ `"Light Industrial"` → ✅ `"Regular+Parking"` or `"Heavy Load"`
- ❌ `"Office/Commercial"` → ✅ `"Regular Household"` or `"Heavy Load"`

**Building Type:**
- ❌ `"Residential"` → ✅ `"House"` or `"Apartment"`
- ❌ `"Commercial"` → ✅ `"Office"`, `"Mall"`, etc.

## Testing Your Request

You can test if your request values are valid by running:

```bash
cd backend
python test_predict_endpoint.py
```

Or check directly:
```bash
cat feature_names.txt | grep "YourFeature"
```
