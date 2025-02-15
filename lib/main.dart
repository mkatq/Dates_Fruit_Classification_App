import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'tflite_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق تصنيف التمر',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        textTheme: TextTheme(
          bodyLarge: const TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: const TextStyle(color: Colors.black54, fontSize: 14),
          headlineSmall: TextStyle(
              color: Colors.brown.shade700,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TFLiteModel _model;
  File? _image;
  bool _loading = false;
  List<double> _outputs = [];
  List<String> _classLabels = ['عجوة', 'جالاكسي', 'رطب', 'سكري', 'شيشي'];
  String _predictedClass = '';
  double _confidenceScore = 0.0;

  // Educational content for each class
  final Map<String, String> _educationalContent = {
    'عجوة':
        """.تمور العجوة معروفة بمذاقها الغني وفوائدها الصحية. غالبًا ما تعتبر أفضل أنواع التمر""",
    'جالاكسي':
        'تمور جالاكسي معروفة بحلاوتها وملمسها الفريد. تحظى بشعبية كوجبة خفيفة وكمكونات للحلويات.',
    'رطب':
        'تمور الرطب ناعمة وحلوة، وغالبًا ما يتم تناولها عندما تكون طازجة ولم تجف بعد.',
    'سكري':
        'تمور السكري معروفة بحلاوتها الشبيهة بالكراميل وملمسها المطاطي، مما يجعلها مفضلة لدى الكثيرين.',
    'شيشي':
        'تمور الشايش صغيرة وحلوة، وغالبًا ما يتم تناولها طازجة أو مجففة كوجبة سريعة للطاقة.'
  };

  @override
  void initState() {
    super.initState();
    _model = TFLiteModel();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    await _model.loadModel();
  }

  Future<void> _classifyImage() async {
    if (_model == null || _image == null) return;

    setState(() {
      _loading = true;
      _predictedClass = '';
      _confidenceScore = 0.0;
    });

    _outputs = await _model.runInference(_image!);

    // Determine the predicted class and confidence score
    int predictedClassIndex =
        _outputs.indexOf(_outputs.reduce((a, b) => a > b ? a : b));
    _predictedClass = _classLabels[predictedClassIndex];
    _confidenceScore = _outputs[predictedClassIndex];

    setState(() {
      _loading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      _image = File(image.path);
      _predictedClass = '';
      _confidenceScore = 0.0;
    });

    // Call classify image directly after picking it
    await _classifyImage();
  }

  void _clearImage() {
    setState(() {
      _image = null;
      _predictedClass = '';
      _confidenceScore = 0.0;
    });
  }

  @override
  void dispose() {
    _model.closeInterpreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق تصنيف التمر'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown.shade50, Colors.brown.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_image != null) ...[
                  _buildImageCard(),
                  const SizedBox(height: 20),
                  if (_loading)
                    const CircularProgressIndicator()
                  else
                    _buildResultCard(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.clear,
                      color: Color.fromARGB(136, 255, 0, 0),
                    ),
                    label: const Text(
                      'مسح الصورة',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onPressed: _clearImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 230, 121, 113),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Show buttons only if no image is selected
                if (_image == null) _buildButtonRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          _image!,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: Colors.brown.shade200,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              ' نوع التمر: $_predictedClass ',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${(_confidenceScore * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.green)),
                  Text(
                    ' :نسبة الثقة ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Educational content display
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _educationalContent[_predictedClass] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    return Column(
      children: [
        // Instruction text above the buttons
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'الرجاء اختيار صورة لتحديد نوع التمر',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Center the text horizontally
            ),
          ),
        ),

        const SizedBox(
          height: 70,
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Spread buttons evenly
          children: [
            Expanded(
              child: _buildImageButton(
                icon: Icons.photo,
                label: 'المعرض',
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 10), // Add some space between buttons
            Expanded(
              child: _buildImageButton(
                icon: Icons.camera_alt,
                label: 'التقاط',
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 180, // Fixed height for square shape
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade300, Colors.brown.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 5,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon:
            Icon(size: 28, icon, color: const Color.fromARGB(255, 43, 43, 43)),
        label: Text(
          label,
          style: const TextStyle(color: Color.fromARGB(255, 43, 43, 43)),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About the App'),
          content: const Text(
            'This app classifies various types of dates using a machine learning model. '
            'Please upload a photo of the date, and it will identify the type and provide educational content.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
