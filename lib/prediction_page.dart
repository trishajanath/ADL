import 'package:flutter/material.dart';
import 'concrete_prediction_service.dart';
import 'scan_storage.dart';
import 'chatbot_page.dart';
import 'auth_service.dart';

class PredictionPage extends StatefulWidget {
  final String category; // "Residential" or "Commercial"
  final ScanResult? existingScan; // For editing existing scans
  
  const PredictionPage({
    Key? key, 
    required this.category, 
    this.existingScan,
  }) : super(key: key);

  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  
  // Form data storage
  final Map<String, dynamic> _formData = {};
  
  // Residential questions based on your PDF
  final List<Map<String, dynamic>> _residentialQuestions = [
    {
      'id': 'building_type',
      'title': 'What type of residential building are you constructing?',
      'type': 'dropdown',
      'options': ['Independent house', 'Apartment (small-scale)'],
      'required': true,
    },
    {
      'id': 'floors',
      'title': 'How many floors (including ground)?',
      'type': 'dropdown',
      'options': ['G', 'G+1', 'G+2'],
      'required': true,
    },
    {
      'id': 'built_up_area',
      'title': 'What is the total built-up area?',
      'type': 'number',
      'placeholder': 'Enter area in sq.ft or m²',
      'required': true,
    },
    {
      'id': 'room_count',
      'title': 'How many rooms do you plan?',
      'type': 'number',
      'placeholder': 'Enter approximate count',
      'required': true,
    },
    {
      'id': 'terrain_type',
      'title': 'What is the terrain type?',
      'type': 'dropdown',
      'options': ['Flat', 'Sloped', 'Hilly'],
      'required': true,
    },
    {
      'id': 'soil_type',
      'title': 'What is the soil type?',
      'type': 'dropdown',
      'options': ['Sandy', 'Clayey', 'Rocky', 'Mixed'],
      'required': true,
    },
    {
      'id': 'exposure_condition',
      'title': 'Is your site in a special exposure condition?',
      'type': 'dropdown',
      'options': ['Normal', 'Coastal', 'Flood-prone', 'High rainfall'],
      'required': true,
    },
    {
      'id': 'seismic_zone',
      'title': 'Do you know the seismic zone of your location?',
      'type': 'dropdown',
      'options': ['Zone II', 'Zone III', 'Zone IV', 'Zone V', 'Not sure'],
      'descriptions': {
        'Zone II': 'Low risk - Minimal earthquake activity (e.g., parts of Maharashtra, Kerala)',
        'Zone III': 'Moderate risk - Occasional seismic activity (e.g., Mumbai, Chennai, Bangalore)',
        'Zone IV': 'High risk - Significant seismic activity (e.g., Delhi, Patna, parts of Himalayas)',
        'Zone V': 'Severe risk - Highest seismic zone (e.g., Kashmir, Northeast India, Uttarakhand)',
        'Not sure': 'We\'ll help determine the zone based on your location',
      },
      'required': true,
    },
    {
      'id': 'roof_type',
      'title': 'Will your roof be plain, garden, or have solar panels?',
      'type': 'dropdown',
      'options': ['Plain roof', 'Garden roof', 'Solar panels', 'Multiple options'],
      'required': true,
    },
    {
      'id': 'load_type',
      'title': 'Will there be heavy loads or only household loads?',
      'type': 'dropdown',
      'options': ['Only household loads', 'Vehicle parking', 'Heavy machinery', 'Mixed loads'],
      'required': true,
    },
    {
      'id': 'basement_needed',
      'title': 'Do you need a basement or underground tank?',
      'type': 'dropdown',
      'options': ['No', 'Basement only', 'Underground tank only', 'Both'],
      'required': true,
    },
    {
      'id': 'waterlogging',
      'title': 'Is waterlogging an issue in your area?',
      'type': 'dropdown',
      'options': ['No', 'Yes, occasionally', 'Yes, frequently'],
      'required': true,
    },
    {
      'id': 'budget_per_sqft',
      'title': 'What is your expected construction budget per sq.ft?',
      'type': 'number',
      'placeholder': 'Enter budget in ₹ per sq.ft',
      'required': false,
    },
    {
      'id': 'material_preference',
      'title': 'Do you prefer eco-friendly or traditional materials?',
      'type': 'dropdown',
      'options': ['Traditional materials', 'Eco-friendly materials', 'No preference'],
      'required': false,
    },
    {
      'id': 'cost_priority',
      'title': 'Do you want only low-cost material options?',
      'type': 'dropdown',
      'options': ['No', 'Yes, low-cost priority', 'Balanced approach'],
      'required': false,
    },
  ];

  // Commercial questions based on your PDF
  final List<Map<String, dynamic>> _commercialQuestions = [
    {
      'id': 'building_type',
      'title': 'Type of commercial building',
      'type': 'dropdown',
      'options': ['Office', 'Mall', 'Hospital', 'School', 'Warehouse'],
      'required': true,
    },
    {
      'id': 'floors',
      'title': 'Number of floors / stories',
      'type': 'dropdown',
      'options': ['G', 'G+1', 'G+2', 'G+3', 'G+4', 'G+5', 'G+6+'],
      'required': true,
    },
    {
      'id': 'built_up_area',
      'title': 'What is the total built-up area?',
      'type': 'number',
      'placeholder': 'Enter area in sq.ft or m²',
      'required': true,
    },
    {
      'id': 'expected_loads',
      'title': 'Expected live loads',
      'type': 'dropdown',
      'options': ['Light equipment', 'Heavy equipment', 'High foot traffic', 'Vehicle parking', 'Mixed loads'],
      'required': true,
    },
    {
      'id': 'fire_resistance',
      'title': 'Fire resistance / durability requirements',
      'type': 'dropdown',
      'options': ['Standard', 'Enhanced', 'High-grade', 'Maximum'],
      'required': true,
    },
    {
      'id': 'parking_levels',
      'title': 'Basement or multi-level parking?',
      'type': 'dropdown',
      'options': ['No', 'Single basement', 'Multi-level basement', 'Ground level only'],
      'required': true,
    },
    {
      'id': 'location',
      'title': 'Where is your site located?',
      'type': 'text',
      'placeholder': 'Enter pincode or GPS location',
      'required': true,
    },
    {
      'id': 'soil_type',
      'title': 'What is the soil type?',
      'type': 'dropdown',
      'options': ['Sandy', 'Clayey', 'Rocky', 'Mixed'],
      'required': true,
    },
    {
      'id': 'seismic_zone',
      'title': 'Do you know the seismic zone of your location?',
      'type': 'dropdown',
      'options': ['Zone II', 'Zone III', 'Zone IV', 'Zone V', 'Not sure'],
      'descriptions': {
        'Zone II': 'Low risk - Minimal earthquake activity (e.g., parts of Maharashtra, Kerala)',
        'Zone III': 'Moderate risk - Occasional seismic activity (e.g., Mumbai, Chennai, Bangalore)',
        'Zone IV': 'High risk - Significant seismic activity (e.g., Delhi, Patna, parts of Himalayas)',
        'Zone V': 'Severe risk - Highest seismic zone (e.g., Kashmir, Northeast India, Uttarakhand)',
        'Not sure': 'We\'ll help determine the zone based on your location',
      },
      'required': true,
    },
    {
      'id': 'exposure_condition',
      'title': 'Is your site in a special exposure condition?',
      'type': 'dropdown',
      'options': ['Normal', 'Coastal', 'Flood-prone', 'High rainfall'],
      'required': true,
    },
  ];

  List<Map<String, dynamic>> get _questions => 
    widget.category.toLowerCase() == 'residential' ? _residentialQuestions : _commercialQuestions;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize form data with empty values
    for (var question in _questions) {
      _formData[question['id']] = null;
    }
    
    // If editing an existing scan, populate the form data
    if (widget.existingScan != null) {
      _loadExistingScanData();
    }
  }

  void _loadExistingScanData() {
    final scan = widget.existingScan!;
    
    // Map the scan data back to form fields from questionnaireData
    if (scan.questionnaireData.isNotEmpty) {
      _formData.addAll(scan.questionnaireData);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitQuestionnaire();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isCurrentQuestionAnswered() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final value = _formData[currentQuestion['id']];
    
    if (currentQuestion['required'] == true) {
      if (currentQuestion['type'] == 'number') {
        return value != null && value.toString().isNotEmpty;
      }
      return value != null && value.toString().isNotEmpty;
    }
    return true;
  }

  Future<void> _submitQuestionnaire() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First test connection
      bool isConnected = await ConcretePredictionService.testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to prediction service. Please ensure the backend server is running.');
      }

      // Map form data to API format
      Map<String, dynamic> apiData = _mapFormDataToAPI();

      // Make prediction
      final result = await ConcretePredictionService.predictConcreteGrade(
        buildingType: apiData['building_type'],
        floors: apiData['floors'],
        soilType: apiData['soil_type'],
        seismicZone: apiData['seismic_zone'],
        exposure: apiData['exposure'],
        loadType: apiData['load_type'],
        builtUpArea: apiData['built_up_area'],
      );

      setState(() {
        _isLoading = false;
      });

      // Show results
      _showResultsDialog(result);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(e.toString());
    }
  }

  Map<String, dynamic> _mapFormDataToAPI() {
    // Map the detailed questionnaire data to the simpler API format
    Map<String, dynamic> apiData = {};
    
    // Building type mapping
    if (_formData['building_type'] != null) {
      String buildingType = _formData['building_type'];
      if (widget.category.toLowerCase() == 'residential') {
        // Map residential building types to API format
        if (buildingType.contains('house') || buildingType.contains('House')) {
          apiData['building_type'] = 'House';
        } else if (buildingType.contains('Apartment') || buildingType.contains('apartment')) {
          apiData['building_type'] = 'Apartment';
        } else if (buildingType.contains('Villa') || buildingType.contains('villa')) {
          apiData['building_type'] = 'House'; // Villa maps to House
        } else if (buildingType.contains('Duplex') || buildingType.contains('duplex')) {
          apiData['building_type'] = 'House'; // Duplex maps to House
        } else {
          apiData['building_type'] = 'House'; // Default for residential
        }
      } else {
        // Commercial building types
        apiData['building_type'] = 'Commercial';
      }
    }
    
    // Floors mapping
    apiData['floors'] = _formData['floors'] ?? 'G+2';
    
    // Built-up area
    apiData['built_up_area'] = int.tryParse(_formData['built_up_area']?.toString() ?? '1500') ?? 1500;
    
    // Soil type mapping
    String soilType = _formData['soil_type'] ?? 'Mixed';
    if (soilType == 'Clayey') {
      apiData['soil_type'] = 'Clay';
    } else if (soilType == 'Sandy') {
      apiData['soil_type'] = 'Sandy'; 
    } else if (soilType == 'Rocky') {
      apiData['soil_type'] = 'Rocky';
    } else {
      apiData['soil_type'] = 'Any'; // Mixed or other maps to Any
    }
    
    // Seismic zone mapping
    String seismicZone = _formData['seismic_zone'] ?? 'Zone III';
    if (seismicZone == 'Not sure') {
      apiData['seismic_zone'] = 'Zone III'; // Default
    } else {
      apiData['seismic_zone'] = seismicZone;
    }
    
    // Exposure condition mapping
    String exposure = _formData['exposure_condition'] ?? 'Normal';
    if (exposure == 'Normal') {
      apiData['exposure'] = 'Moderate';
    } else if (exposure == 'Coastal') {
      apiData['exposure'] = 'Severe';
    } else if (exposure == 'Flood-prone' || exposure == 'High rainfall') {
      apiData['exposure'] = 'Very Severe';
    } else {
      apiData['exposure'] = 'Moderate';
    }
    
    // Load type mapping
    if (widget.category.toLowerCase() == 'residential') {
      String loadType = _formData['load_type'] ?? 'Only household loads';
      if (loadType.contains('household') || loadType.contains('Only')) {
        apiData['load_type'] = 'Regular Household';
      } else if (loadType.contains('Heavy machinery')) {
        apiData['load_type'] = 'Heavy Machinery';
      } else if (loadType.contains('Vehicle parking')) {
        apiData['load_type'] = 'Light Industrial';
      } else {
        apiData['load_type'] = 'Regular Household';
      }
    } else {
      // Commercial load mapping
      String expectedLoads = _formData['expected_loads'] ?? 'Light equipment';
      if (expectedLoads.contains('Heavy equipment')) {
        apiData['load_type'] = 'Heavy Machinery';
      } else if (expectedLoads.contains('Vehicle parking')) {
        apiData['load_type'] = 'Light Industrial';
      } else {
        apiData['load_type'] = 'Office/Commercial';
      }
    }
    
    return apiData;
  }

  void _showResultsDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.green),
            SizedBox(width: 8),
            Text('🎯 AI Prediction Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultItem('Concrete Grade', result['prediction']['concrete_grade'], Icons.foundation),
              _buildResultItem('Estimated Cost', result['cost_estimation']['total_estimated_cost'], Icons.attach_money),
              _buildResultItem('Volume Required', result['cost_estimation']['estimated_volume_cum'], Icons.view_in_ar),
              
              SizedBox(height: 16),
              Text('Materials Required:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Divider(),
              _buildMaterialItem('Cement', '${result['materials']['Cement_kg']} kg'),
              _buildMaterialItem('Water', '${result['materials']['Water_kg']} kg'),
              _buildMaterialItem('Sand', '${result['materials']['Sand_kg']} kg'),
              _buildMaterialItem('Coarse Aggregate (20mm)', '${result['materials']['CA20_kg']} kg'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetQuestionnaire();
            },
            child: Text('New Prediction'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openChatbot(result);
            },
            icon: Icon(Icons.smart_toy),
            label: Text('Ask AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSaveDialog(result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(Map<String, dynamic> result) {
    String projectName = widget.existingScan?.projectName ?? _generateDefaultProjectName();
    final TextEditingController nameController = TextEditingController(text: projectName);
    String? errorText;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(widget.existingScan != null ? Icons.edit : Icons.save, color: Colors.blue),
              SizedBox(width: 8),
              Text(widget.existingScan != null ? 'Update Scan' : 'Save Scan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existingScan != null 
                ? 'Update your scan name:' 
                : 'Give your scan a name for easy reference:'
              ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'e.g., My Dream House, Office Building',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                  errorText: errorText,
                ),
                maxLength: 50,
                onChanged: (value) {
                  // Clear error when user types
                  if (errorText != null) {
                    setState(() {
                      errorText = null;
                    });
                  }
                },
              ),
              SizedBox(height: 8),
              Text(
                widget.existingScan != null
                  ? 'Your updated scan will be saved with the new analysis.'
                  : 'You can view and edit this scan later from the home page.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                final trimmedName = nameController.text.trim();
                
                // Validate empty name
                if (trimmedName.isEmpty) {
                  setState(() {
                    errorText = 'Please enter a project name';
                  });
                  return;
                }
                
                // Check for duplicate name
                final userEmail = AuthService().userIdentifier;
                final isDuplicate = await ScanStorage.scanNameExists(
                  trimmedName, 
                  userEmail,
                  excludeScanId: widget.existingScan?.id,
                );
                
                if (isDuplicate) {
                  setState(() {
                    errorText = 'A scan with this name already exists';
                  });
                  return;
                }
                
                // If validation passes, save and close
                Navigator.pop(context);
                await _saveScanResult(trimmedName, result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateDefaultProjectName() {
    String buildingType = _formData['building_type'] ?? 'Building';
    String area = _formData['built_up_area']?.toString() ?? '';
    String floors = _formData['floors'] ?? '';
    
    if (area.isNotEmpty) {
      return '$buildingType - ${area} sq.ft - $floors';
    } else {
      return '$buildingType - $floors';
    }
  }

  Future<void> _saveScanResult(String projectName, Map<String, dynamic> result) async {
    try {
      if (projectName.isEmpty) {
        projectName = _generateDefaultProjectName();
      }

      ScanResult scan;
      bool isUpdate = widget.existingScan != null;

      if (isUpdate) {
        // Update existing scan
        scan = ScanResult(
          id: widget.existingScan!.id, // Keep the same ID
          category: widget.category.toLowerCase(),
          timestamp: widget.existingScan!.timestamp, // Keep original timestamp
          questionnaireData: Map<String, dynamic>.from(_formData),
          predictionResult: result,
          projectName: projectName,
        );
        // Get current user email as identifier
        final userEmail = AuthService().userIdentifier;
        await ScanStorage.updateScan(scan, userEmail);
      } else {
        // Create new scan
        scan = ScanResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          category: widget.category.toLowerCase(),
          timestamp: DateTime.now(),
          questionnaireData: Map<String, dynamic>.from(_formData),
          predictionResult: result,
          projectName: projectName,
        );
        // Get current user email as identifier
        final userEmail = AuthService().userIdentifier;
        await ScanStorage.saveScan(scan, userEmail);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(isUpdate ? 'Scan updated successfully!' : 'Scan saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to save scan'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(String material, String quantity) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(material),
          Text(quantity, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Failed to get prediction:'),
            SizedBox(height: 8),
            Text(error, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 16),
            Text('Troubleshooting:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Ensure the backend server is running'),
            Text('• Check your internet connection'),
            Text('• Verify all answers are provided'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openChatbot(Map<String, dynamic> result) {
    // Create a formatted prediction context for the chatbot
    String predictionContext = '''
Concrete Prediction Results:
- Grade: ${result['prediction']['concrete_grade']}
- Estimated Cost: ${result['cost_estimation']['total_estimated_cost']}
- Volume Required: ${result['cost_estimation']['estimated_volume_cum']}
- Materials: Cement ${result['materials']['Cement_kg']}kg, Water ${result['materials']['Water_kg']}kg, Sand ${result['materials']['Sand_kg']}kg, Coarse Aggregate ${result['materials']['CA20_kg']}kg
- Building Type: ${widget.category}
- Project Details: ${_formData.toString()}
''';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotPage(predictionContext: predictionContext),
      ),
    );
  }

  void _resetQuestionnaire() {
    setState(() {
      _currentQuestionIndex = 0;
      for (var question in _questions) {
        _formData[question['id']] = null;
      }
    });
    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          
          // Question counter
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          
          // Question title
          Text(
            question['title'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 32),
          
          // Question input
          Expanded(
            child: _buildQuestionInput(question),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(Map<String, dynamic> question) {
    switch (question['type']) {
      case 'dropdown':
        return _buildDropdownInput(question);
      case 'number':
        return _buildNumberInput(question);
      case 'text':
        return _buildTextInput(question);
      default:
        return Container();
    }
  }

  Widget _buildDropdownInput(Map<String, dynamic> question) {
    final descriptions = question['descriptions'] as Map<String, dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...question['options'].map<Widget>((option) {
          final isSelected = _formData[question['id']] == option;
          final hasDescription = descriptions != null && descriptions.containsKey(option);
          
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _formData[question['id']] = option;
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.grey[400],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.blue : Colors.black87,
                            ),
                          ),
                          if (hasDescription) ...[
                            SizedBox(height: 4),
                            Text(
                              descriptions[option],
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? Colors.blue.shade700 : Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTextInput(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          keyboardType: TextInputType.text,
          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: question['placeholder'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _formData[question['id']] = value;
            });
          },
          initialValue: _formData[question['id']]?.toString(),
        ),
        SizedBox(height: 16),
        Text(
          question['id'] == 'location' 
            ? 'Enter your pincode, GPS coordinates, or nearby landmark.'
            : 'Provide additional details as needed.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildNumberInput(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: question['placeholder'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.all(16),
            suffixText: question['id'] == 'built_up_area' ? 'sq. ft.' : 
                       question['id'] == 'budget_per_sqft' ? '₹' : null,
          ),
          onChanged: (value) {
            setState(() {
              _formData[question['id']] = value;
            });
          },
          initialValue: _formData[question['id']]?.toString(),
        ),
        SizedBox(height: 16),
        Text(
          question['id'] == 'built_up_area' 
            ? 'Enter the total built-up area of your building in square feet.'
            : question['id'] == 'room_count'
            ? 'Include bedrooms, living rooms, kitchen, bathrooms, etc.'
            : question['id'] == 'budget_per_sqft'
            ? 'Optional: Enter your expected budget per square foot in rupees.'
            : 'Enter the required numeric value.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to verify category
    print('🔍 PredictionPage: Category = "${widget.category}"');
    print('🔍 Questions count: ${_questions.length}');
    print('🔍 Is Residential: ${widget.category.toLowerCase() == 'residential'}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingScan != null 
          ? 'Edit ${widget.category.isNotEmpty ? widget.category[0].toUpperCase() + widget.category.substring(1) : "Building"} Project'
          : '${widget.category.isNotEmpty ? widget.category[0].toUpperCase() + widget.category.substring(1) : "Building"} Questionnaire'
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(), // Disable swipe navigation
            itemCount: _questions.length,
            onPageChanged: (index) {
              setState(() {
                _currentQuestionIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildQuestionWidget(_questions[index]);
            },
          ),
          
          // Navigation buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous button
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousQuestion,
                        icon: Icon(Icons.arrow_back),
                        label: Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  
                  if (_currentQuestionIndex > 0) SizedBox(width: 16),
                  
                  // Next/Submit button
                  Expanded(
                    flex: _currentQuestionIndex == 0 ? 1 : 1,
                    child: ElevatedButton.icon(
                      onPressed: _isCurrentQuestionAnswered() 
                        ? (_isLoading ? null : _nextQuestion)
                        : null,
                      icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(_currentQuestionIndex == _questions.length - 1
                            ? Icons.analytics
                            : Icons.arrow_forward),
                      label: Text(_isLoading
                        ? 'Getting Prediction...'
                        : _currentQuestionIndex == _questions.length - 1
                            ? 'Get AI Prediction'
                            : 'Next'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}