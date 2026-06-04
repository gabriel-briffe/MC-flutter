import 'package:flutter/material.dart';

import 'app.dart';
import 'geolocator_web_registrar_stub.dart'
    if (dart.library.html) 'geolocator_web_registrar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerGeolocatorWebPlugin();
  runApp(const McFlutterApp());
}
