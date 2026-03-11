import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/medication.dart';
import 'package:das_tern/domain/use_cases/process_ocr_result_use_case.dart';
import 'package:flutter/foundation.dart';

class OcrReviewViewModel extends ChangeNotifier {
  OcrReviewViewModel({required ProcessOcrResultUseCase processOcrResultUseCase})
    : _processOcrResultUseCase = processOcrResultUseCase {
    load = Command0(_load);
  }

  final ProcessOcrResultUseCase _processOcrResultUseCase;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _rawText = '';

  List<Medication> _drafts = <Medication>[];
  List<Medication> get drafts => _drafts;

  void setRawText(String rawText) {
    _rawText = rawText;
    load.execute();
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();

    _drafts = _processOcrResultUseCase(_rawText);

    _isLoading = false;
    notifyListeners();
  }
}
