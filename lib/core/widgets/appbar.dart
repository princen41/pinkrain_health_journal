import 'package:flutter/material.dart';

AppBar buildAppBar(
  String title, {
  List<Widget>? actions,
  Widget? leading,
  Color? backgroundColor,
}) {
  return AppBar(
    title: Text(
      title,
      style: TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: backgroundColor ?? Colors.white,
    elevation: 0,
    automaticallyImplyLeading: false,
    leading: leading,
    actions: actions,
  );
}