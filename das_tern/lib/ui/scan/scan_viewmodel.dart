import 'package:das_tern/core/utils/command.dart';
import 'package:flutter/foundation.dart';

class ScanViewModel extends ChangeNotifier {
  ScanViewModel() {
    load = Command0(_load);
  }

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _rawText = '';
  String get rawText => _rawText;

  Future<void> _load() async {
    _isLoading = false;
    notifyListeners();
  }

  void mockScan() {
    _rawText = 'Paracetamol,500,mg,2 times/day\nVitamin C,1000,mg,1 time/day';
    notifyListeners();
  }
}
