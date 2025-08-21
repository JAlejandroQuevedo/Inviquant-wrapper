import 'package:flutter/material.dart';
import 'package:inviquant_wrapper/src/widget/web_home.dart';

class WebWrapperApp extends StatelessWidget {
  const WebWrapperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inviquant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const WebHome(),
    );
  }
}
