import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inviquant_wrapper/src/widget/components/edge_to_edge.dart';
import 'package:inviquant_wrapper/src/widget/web_home.dart';

const kBrandPurple = Color(0xff32004A);

class WebWrapperApp extends StatelessWidget {
  const WebWrapperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inviquant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: kBrandPurple,
          statusBarIconBrightness: Brightness.light, // Android
          statusBarBrightness: Brightness.dark, // iOS
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: EdgeToEdgeScaffold(
          topColorIOS: kBrandPurple,
          child: const WebHome(),
        ),
      ),
    );
  }
}
