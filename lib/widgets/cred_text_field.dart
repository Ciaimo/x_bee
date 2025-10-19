import 'package:flutter/material.dart';

class CredTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final bool isPassword;
  const CredTextField(
      {super.key,
      required this.controller,
      required this.labelText,
      this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          )),
      obscureText: isPassword,
    );
  }
}
