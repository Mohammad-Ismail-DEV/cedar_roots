import 'package:flutter/material.dart';

class DaySeparator extends StatelessWidget {
  final String formattedDate;

  const DaySeparator({Key? key, required this.formattedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(formattedDate, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
