import 'package:flutter/material.dart';
import 'concrete_prediction_service.dart';

class PredictionPage extends StatefulWidget {
  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  
  // Form data storage
  final Map<String, dynamic> _formData = {};
  
  // Question data based on Customer_Questionnaire.pdf
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'building_type',
      'title': 'What type of building are you constructing?',
      'type': 'dropdown',
      'options': ['House', 'Commercial', 'Apartment', 'Industrial'],
      'required': true,
    },
    {
      'id': 'floors',
      'title': 'How many floors will your building have?',
      'type': 'dropdown',
      'options': ['G', 'G+1', 'G+2', 'G+3', 'G+4', 'G+5', 'G+6+'],
      'required': true,
    },
    {
      'id': 'built_up_area',
      'title': 'What is the built-up area? (in sq. ft.)',
      'type': 'number',
      'placeholder': 'Enter area in square feet',
      'required': true,
    },
    {
      'id': 'soil_type',
      'title': 'What type of soil is at your construction site?',
      'type': 'dropdown',
      'options': ['Any', 'Clay', 'Sandy', 'Rocky', 'Black Cotton', 'Alluvial'],
      'required': true,
    },
    {
      'id': 'seismic_zone',
      'title': 'Which seismic zone is your location in?',
      'type': 'dropdown',
      'options': ['Zone I', 'Zone II', 'Zone III', 'Zone IV', 'Zone V'],
      'required': true,
    },
    {
      'id': 'exposure',
      'title': 'What is the exposure condition of your building?',
      'type': 'dropdown',
      'options': ['Mild', 'Moderate', 'Severe', 'Very Severe', 'Extreme'],
      'required': true,
    },
    {
      'id': 'load_type',
      'title': 'What type of loads will the building carry?',
      'type': 'dropdown',
      'options': ['Regular Household', 'Heavy Machinery', 'Storage/Warehouse', 'Office/Commercial', 'Light Industrial'],
      'required': true,
    },
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize form data with empty values
    for (var question in _questions) {
      _formData[question['id']] = null;
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

      // Make prediction
      final result = await ConcretePredictionService.predictConcreteGrade(
        buildingType: _formData['building_type'],
        floors: _formData['floors'],
        soilType: _formData['soil_type'],
        seismicZone: _formData['seismic_zone'],
        exposure: _formData['exposure'],
        loadType: _formData['load_type'],
        builtUpArea: int.parse(_formData['built_up_area'].toString()),
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
              _buildResultItem('Confidence', result['prediction']['confidence_percentage'], Icons.verified),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
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
      default:
        return Container();
    }
  }

  Widget _buildDropdownInput(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...question['options'].map<Widget>((option) {
          final isSelected = _formData[question['id']] == option;
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
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.grey[400],
                    ),
                    SizedBox(width: 12),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black87,
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
            suffixText: 'sq. ft.',
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
          'Enter the total built-up area of your building in square feet.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Building Questionnaire'),
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