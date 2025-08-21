import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isVisible;
  final Function(bool) onVisibilityChanged;
  final Function(String) onSubmitted;
  final int? maxLength;

  const PasswordInput({
    super.key,
    required this.controller,
    required this.isVisible,
    required this.onVisibilityChanged,
    required this.onSubmitted,
    this.maxLength = 8, // Varsayılan 8 haneli
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        keyboardType: TextInputType.number,
        maxLength: maxLength,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 8,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '•' * (maxLength ?? 8),
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
            letterSpacing: 8,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[400],
            ),
            onPressed: () => onVisibilityChanged(!isVisible),
          ),
        ),
        onSubmitted: onSubmitted,
        onChanged: (value) {
          if (value.length == maxLength) {
            onSubmitted(value);
          }
        },
      ),
    );
  }
}
