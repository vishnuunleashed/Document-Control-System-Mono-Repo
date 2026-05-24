import 'package:flutter/material';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configurations
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  runApp(const DCSApp());
}
