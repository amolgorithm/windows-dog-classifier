import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.black,
            onPrimary: Colors.white,
          ),
        ),
      ),
      home: DogBannerWidget(),
    );
  }
}

class DogBannerWidget extends StatefulWidget {
  @override
  _DogBannerWidgetState createState() => _DogBannerWidgetState();
}

class _DogBannerWidgetState extends State<DogBannerWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  File? _image;
  Iterable<dynamic> _result = [];
  bool _loading = false;
  bool _runningPyCode = false;
  String _pyErrorMessage = '';
  String _flutterErrorMessage = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: -0.2, end: 1.2).animate(_controller);

    Future.delayed(Duration(seconds: 1), () {
      _startAnimation();
    });
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true; // Show loading indicator
      });

      await _callPythonScript(_image!.path);
    }
  }

  Future<void> _callPythonScript(String imagePath) async {
    try {
      setState(() {
        _runningPyCode = true;
        _pyErrorMessage = ''; // Reset Python error message
      });

      var pythonScript = 'assets/dog_classifier.py';
      var result = await Process.run('python', [pythonScript, imagePath]);

      setState(() {
        _result = jsonDecode(result.stdout.toString());
        _loading = false; // Hide loading indicator
        _runningPyCode = false;
      });
    } catch (e) {
      print('Error calling Python script: $e');
      setState(() {
        _runningPyCode = false;
        _pyErrorMessage = 'Error running Python script: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 250.0,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/dog_photo.jpg'),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
            ),
            child: Center(
              child: Stack(
                children: [
                  Container(
                    height: 250.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.0),
                        bottomRight: Radius.circular(30.0),
                      ),
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Center(
                      child: Text(
                        'Dog Classifier',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 60.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                              stops: [
                                _animation.value,
                                _animation.value + 0.2
                              ],
                            ).createShader(bounds);
                          },
                          child: Container(
                            width: 100.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(30.0),
                                bottomRight: Radius.circular(30.0),
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 4.0,
                              ),
                              color: Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: _getImage,
            style: ElevatedButton.styleFrom(
              primary: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload, color: Colors.white),
                SizedBox(width: 8.0),
                Text('Upload Photo', style: TextStyle(fontSize: 16.0)),
              ],
            ),
          ),
          SizedBox(height: 20.0),
          if (_image != null)
            Text('Image File: ${_image!.path}')
          else
            Text('No Image Selected'),

          // Display result from Python script
          Container(
            margin: EdgeInsets.all(20.0),
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.grey[200],
            ),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_loading)
                    Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10.0),
                        Text(
                          'Running Python code...',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.red, // Change text color to red
                          ),
                        ),
                      ],
                    )
                  else if (_pyErrorMessage.isNotEmpty)
                    Text(
                      _pyErrorMessage,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.red, // Change text color to red
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (_result.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Top Predictions:',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.0),
                        for (int i = 0; i < _result.length; i++)
                          ListTile(
                            title: Text(
                              'Breed: ${(_result.toList())[i]['label']}', // Convert Iterable to List
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: i == 0 ? Colors.green : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            subtitle: Text(
                              'Probability: ${(_result.toList())[i]['probability'].toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    )
                  else if (_result.isEmpty)
                    Text(
                      'No result available',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
