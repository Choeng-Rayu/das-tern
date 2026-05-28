import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/models/user_models.dart';
import '../data/repositories/user_repository.dart';

/// Save operation state.
enum SaveStatus { idle, saving, success, error }

/// ViewModel for the profile editor screen.
///
/// Manages dirty tracking, field validation, image encoding, and save state.
/// Views should only render — all logic lives here.
class ProfileEditorViewModel extends ChangeNotifier {
  ProfileEditorViewModel({
    required CurrentUser user,
    required UserRepository userRepository,
  }) : _repo = userRepository,
       firstName = user.firstName,
       lastName = user.lastName ?? '',
       email = user.email ?? '',
       phone = user.phone ?? '',
       gender = user.gender ?? Gender.male,
       dateOfBirth = user.dateOfBirth,
       existingImageUrl = user.profileImage,
       _original = user;

  final UserRepository _repo;
  final CurrentUser _original;

  // ── Editable fields ─────────────────────────────────────────────────────
  String firstName;
  String lastName;
  String email;
  String phone;
  Gender gender;
  DateTime? dateOfBirth;
  String? existingImageUrl;
  File? pickedImage;

  // ── State ───────────────────────────────────────────────────────────────
  SaveStatus _saveStatus = SaveStatus.idle;
  String? _error;

  SaveStatus get saveStatus => _saveStatus;
  String? get error => _error;

  bool get isDirty =>
      firstName != _original.firstName ||
      lastName != (_original.lastName ?? '') ||
      email != (_original.email ?? '') ||
      phone != (_original.phone ?? '') ||
      gender != (_original.gender ?? Gender.male) ||
      dateOfBirth != _original.dateOfBirth ||
      pickedImage != null;

  bool get canSave => isDirty && _saveStatus != SaveStatus.saving;

  // ── Validation ──────────────────────────────────────────────────────────
  String? validateFirstName() => firstName.trim().isEmpty ? 'Required' : null;

  String? validateLastName() => lastName.trim().isEmpty ? 'Required' : null;

  String? validateEmail() {
    if (email.trim().isEmpty) return null; // optional
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(email.trim()) ? null : 'Invalid email';
  }

  bool validate() =>
      validateFirstName() == null &&
      validateLastName() == null &&
      validateEmail() == null;

  // ── Commands ────────────────────────────────────────────────────────────

  void updateField(void Function() mutate) {
    mutate();
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked != null) {
      pickedImage = File(picked.path);
      notifyListeners();
    }
  }

  Future<bool> save() async {
    if (!validate()) return false;

    _saveStatus = SaveStatus.saving;
    _error = null;
    notifyListeners();

    String? encodedImage;
    if (pickedImage != null) {
      final bytes = await pickedImage!.readAsBytes();
      final ext = pickedImage!.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      encodedImage = 'data:$mime;base64,${base64Encode(bytes)}';
    }

    final update = UserProfileUpdate(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().isNotEmpty ? email.trim() : null,
      phone: phone.trim().isNotEmpty ? phone.trim() : null,
      gender: gender,
      dateOfBirth: dateOfBirth,
      profileImage: encodedImage,
    );

    final result = await _repo.updateProfile(update);

    switch (result) {
      case UserSuccess():
        _saveStatus = SaveStatus.success;
        notifyListeners();
        return true;
      case UserFailure(:final message):
        _saveStatus = SaveStatus.error;
        _error = message;
        notifyListeners();
        return false;
    }
  }
}
