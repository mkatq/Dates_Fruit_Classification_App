import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteModel {
  Interpreter? _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  Future<void> loadModel() async {
    try {
      // Load the TensorFlow Lite model from assets
      _interpreter = await Interpreter.fromAsset('assets/best_model.tflite');

      // Get input and output tensor shapes
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<List<double>> runInference(File imageFile) async {
    if (_interpreter == null) {
      print("Interpreter not initialized.");
      return [];
    }

    if (_inputShape.isEmpty) {
      print("Model input shape not initialized.");
      return [];
    }

    // Load and preprocess the image
    var image = await _loadImage(imageFile);

    // Prepare the output buffer
    var output =
        List.filled(_outputShape[1], 0.0).reshape([1, _outputShape[1]]);

    // Run the inference
    _interpreter!.run(image, output);

    return output[0];
  }

  Future<List<List<List<List<double>>>>> _loadImage(File imageFile) async {
    // Read the image file
    final bytes = await imageFile.readAsBytes();

    // Decode the image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception("Unable to decode image");
    }

    // Resize the image to match the input shape of the model (e.g., 64x64)
    img.Image resizedImage = img.copyResize(image, width: 64, height: 64);

    // Prepare the input array (1, 64, 64, 3)
    List<List<List<List<double>>>> input = List.generate(
      1,
      (i) => List.generate(
        64,
        (j) => List.generate(
          64,
          (k) => List.generate(
            3,
            (l) {
              // Get pixel values (RGB) and normalize to [0, 1]
              int pixel = resizedImage.getPixel(k, j);
              return img.getRed(pixel) / 255.0; // Normalize red channel
            },
          ),
        ),
      ),
    );

    return input;
  }

  void closeInterpreter() {
    _interpreter?.close();
  }
}
