import 'package:flutter/material.dart';

class AdditionalItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AdditionalItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 48),
          SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 16)),
          SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
