import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../../../core/theme/tokens/radii.dart';
import '../../../../core/theme/tokens/spacing.dart';

/// Image picker + upload widget for prescription images.
///
/// Displays a thumbnail when an image is selected, uploads to Supabase
/// Storage under `prescription-images/{patientId}/{prescriptionId}/`,
/// and calls [onUploaded] with the storage path.
///
/// Spec ref: 03-prescription-medication §3.5.
class PrescriptionImagePicker extends ConsumerStatefulWidget {
  const PrescriptionImagePicker({
    super.key,
    required this.patientId,
    required this.prescriptionId,
    this.onUploaded,
    this.existingUrl,
  });

  final String patientId;
  final String prescriptionId;
  final ValueChanged<String>? onUploaded;
  final String? existingUrl;

  @override
  ConsumerState<PrescriptionImagePicker> createState() =>
      _PrescriptionImagePickerState();
}

class _PrescriptionImagePickerState
    extends ConsumerState<PrescriptionImagePicker> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _localPath;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() { _uploading = true; _error = null; });
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.name.isNotEmpty ? file.name : 'image.jpg';
      final storage = ref.read(supabaseStorageProvider);
      final path = await storage.uploadPrescriptionImage(
        patientId: widget.patientId,
        prescriptionId: widget.prescriptionId,
        fileName: fileName,
        bytes: bytes,
      );
      setState(() => _localPath = file.path);
      widget.onUploaded?.call(path);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () => _showSourceSheet(context),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: AppRadii.allMedium,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: _uploading
                ? const Center(child: CircularProgressIndicator())
                : _localPath != null
                    ? ClipRRect(
                        borderRadius: AppRadii.allMedium,
                        child: Image.network(
                          _localPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image, size: 48),
                        ),
                      )
                    : widget.existingUrl != null
                        ? ClipRRect(
                            borderRadius: AppRadii.allMedium,
                            child: Image.network(
                              widget.existingUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40, color: cs.onSurfaceVariant),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Add prescription image',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              _error!,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
