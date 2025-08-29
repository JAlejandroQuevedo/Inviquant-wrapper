import 'dart:io';

import 'package:flutter/material.dart';

const kBrandPurple = Color(0xff32004A);

class EdgeToEdgeScaffold extends StatelessWidget {
  final Widget child;
  final Color topColorIOS;
  const EdgeToEdgeScaffold({
    super.key,
    required this.child,
    required this.topColorIOS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandPurple,
      child: Column(
        children: [
          if (Platform.isIOS) Container(height: 0, color: topColorIOS),
          Expanded(
            child: SafeArea(
              top: Platform.isAndroid ? false : true,
              bottom: false,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
