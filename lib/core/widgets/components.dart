
import 'package:flutter/material.dart';
import 'custom_text_field.dart';

Padding nameField({required TextEditingController controller, VoidCallback? onChanged}){
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
    child: CustomTextField(
      controller: controller,
      hintText: 'Anonymous',
      onChanged: onChanged,
    ),
  );
}