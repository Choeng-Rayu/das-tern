import 'package:flutter/material.dart';

/// Allows any screen (including Navigator-pushed routes) to request a tab
/// switch in [PatientShell]. Register globally in [MultiProvider] so it is
/// accessible above the Navigator.
class ShellTabController extends ChangeNotifier {
  int _requestedIndex = 0;
  int get requestedIndex => _requestedIndex;

  void switchTo(int index) {
    _requestedIndex = index;
    notifyListeners();
  }
}
