import 'package:flutter/material.dart';

class CredTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final bool isPassword;
  final String? Function(String?)? validator;

  const CredTextField(
      {super.key,
      required this.controller,
      required this.labelText,
      this.validator,
      this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          )),
      obscureText: isPassword,
      validator: validator,
    );
  }
}
