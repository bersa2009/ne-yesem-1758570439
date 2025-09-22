import 'package:flutter/material.dart';
import 'app.dart';
import 'services/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.instance.init();
  runApp(const NeYesemApp());
}

