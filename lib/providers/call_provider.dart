import 'package:flutter/material.dart';

class CallProvider extends ChangeNotifier {
  dynamic _callData;
  get callData => _callData;

  void setCallData(dynamic data) {
    _callData = data;
    notifyListeners();
  }
}
