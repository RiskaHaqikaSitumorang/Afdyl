import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final Widget? suffixIcon;

  const CustomTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFD3D3D3),
            borderRadius: BorderRadius.circular(16),
            border:
                errorText != null
                    ? Border.all(color: Colors.red, width: 1.5)
                    : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: enabled,
            keyboardType: keyboardType,
            cursorColor: Colors.black54, // Explicitly set cursor color to black
            style: TextStyle(
              fontFamily: 'OpenDyslexic',
              fontSize: 16,
              color: Colors.black,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Color(0xFF888888),
                fontFamily: 'OpenDyslexic',
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: errorText != null ? Colors.red : Color(0xFF666666),
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(left: 20, top: 8),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontFamily: 'OpenDyslexic',
              ),
            ),
          ),
      ],
    );
  }
}
