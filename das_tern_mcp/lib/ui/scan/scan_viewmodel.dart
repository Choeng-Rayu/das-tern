import 'package:flutter/foundation.dart';
import 'package:das_tern_mcp/data/models/medication.dart';
import 'package:das_tern_mcp/domain/use_cases/process_ocr_result_use_case.dart';

class ScanViewModel extends ChangeNotifier {
  ScanViewModel({ProcessOcrResultUseCase? processOcrResultUseCase})
      : _processOcr =
            processOcrResultUseCase ?? const ProcessOcrResultUseCase();

  final ProcessOcrResultUseCase _processOcr;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  String? _capturedImagePath;
  String? get capturedImagePath => _capturedImagePath;

  String? _ocrResult;
  String? get ocrResult => _ocrResult;

  List<Medication> _extractedMedications = [];
  List<Medication> get extractedMedications => _extractedMedications;

  void startScan() {
    _isScanning = true;
    _capturedImagePath = null;
    _ocrResult = null;
    _extractedMedications = [];
    _hasError = false;
    notifyListeners();
  }

  void captureImage(String path) {
    _capturedImagePath = path;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> processImage(String imagePath) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    try {
      // TODO(team): Replace mock OCR with real OCR service call.
      // See: https://github.com/Choeng-Rayu/das-tern/issues (OCR integration task)
      await Future.delayed(const Duration(seconds: 1));
      const mockOcrText =
          'Amoxicillin 500mg twice daily\nParacetamol 1g once';
      _ocrResult = mockOcrText;
      _extractedMedications = _processOcr(mockOcrText);
      _capturedImagePath = imagePath;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to process image.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
