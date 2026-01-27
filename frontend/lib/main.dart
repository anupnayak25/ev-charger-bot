import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

const String backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://7hb4djcf-8000.inc1.devtunnels.ms',
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Charger Bot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const ChatScreen(backendUrl: backendUrl),
    );
  }
}
