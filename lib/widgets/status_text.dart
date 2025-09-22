import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  final String status;

  const StatusText({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontFamily: 'OpenDyslexic',
          height: 1.3,
        ),
      ),
    );
  }
}