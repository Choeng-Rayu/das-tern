import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Displays the generated connection token as a QR code + text code.
/// Patient shows this to caregiver to scan.
class TokenDisplayScreen extends StatefulWidget {
  const TokenDisplayScreen({super.key});

  @override
  State<TokenDisplayScreen> createState() => _TokenDisplayScreenState();
}

class _TokenDisplayScreenState extends State<TokenDisplayScreen> {
  bool _isGenerating = true;
  String? _token;
  DateTime? _expiresAt;
  String? _error;

  /// Key attached to the RepaintBoundary that wraps the QR widget.
  /// Used by [_shareTokenWithQr] to capture the QR as a PNG image.
  final GlobalKey _qrKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token == null && _error == null) {
      _generateToken();
    }
  }

  Future<void> _generateToken() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final permissionLevel = args?['permissionLevel'] ?? 'REQUEST';
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final provider = context.read<ConnectionProvider>();
      final result = await provider.generateToken(permissionLevel);
      if (result != null && mounted) {
        setState(() {
          _token = result['token'];
          _expiresAt = result['expiresAt'] != null
              ? DateTime.parse(result['expiresAt'])
              : DateTime.now().add(const Duration(hours: 24));
          _isGenerating = false;
        });
      } else if (mounted) {
        setState(() {
          _error = provider.error ?? l10n.failedToGenerateToken;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isGenerating = false;
        });
      }
    }
  }

  String _getTimeRemaining(AppLocalizations l10n) {
    if (_expiresAt == null) return '';
    final diff = _expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return l10n.tokenExpired;
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return l10n.timeRemaining(hours, minutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.connectionCodeTitle), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _isGenerating
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState(context)
              : _buildTokenDisplay(context),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.alertRed),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.cannotGenerateCode,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(text: l10n.retry, onPressed: _generateToken),
        ],
      ),
    );
  }

  Widget _buildTokenDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          // QR Code
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // RepaintBoundary captures both the QR image and the token
                // text as a single PNG.  The white Container gives the PNG a
                // solid background so it looks clean when shared.
                // _qrKey is used by _shareTokenWithQr() to find this boundary.
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: _token ?? '',
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.darkBlue,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _token ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.neutral300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        l10n.orUseCode,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.neutral300)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Text token
                GestureDetector(
                  onTap: () => _copyToken(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _token ?? '',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppColors.primaryBlue,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.copy,
                          size: 20,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _getTimeRemaining(l10n),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Instructions
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.instructions,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStep(context, '1', l10n.instructionStep1Family),
                _buildStep(context, '2', l10n.instructionStep2Family),
                _buildStep(context, '3', l10n.instructionStep3Family),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Share button
          PrimaryButton(
            text: l10n.shareCodeButton,
            icon: Icons.share,
            onPressed: _shareTokenWithQr,
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            text: l10n.generateNewCode,
            icon: Icons.refresh,
            isOutlined: true,
            onPressed: _generateToken,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Captures the QR code widget as a PNG, saves it to a temporary file,
  /// then opens the native OS share sheet with both the image and a text
  /// message that contains the token.
  ///
  /// How it works step-by-step:
  /// 1. Find the [RenderRepaintBoundary] associated with [_qrKey].
  /// 2. Call [toImage()] on it to rasterise the widget into a [ui.Image].
  /// 3. Convert the image to raw PNG bytes via [toByteData()] + [Uint8List].
  /// 4. Write those bytes to a temp PNG file using [path_provider].
  /// 5. Call [Share.shareXFiles()] with an [XFile] pointing at the PNG
  ///    and a plain-text body containing the token code.
  Future<void> _shareTokenWithQr() async {
    if (_token == null) return;
    final l10n = AppLocalizations.of(context)!;

    try {
      // 1. Locate the render object for the RepaintBoundary.
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        // Fallback: share text only if the boundary is not yet painted.
        await Share.share(l10n.shareQrAndCodeMessage(_token!));
        return;
      }

      // 2. Rasterise the widget to a ui.Image at 3× device-pixel density
      //    so the exported PNG is crisp on high-DPI screens.
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // 3. Encode the ui.Image to PNG byte data.
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        await Share.share(l10n.shareQrAndCodeMessage(_token!));
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      // 4. Write the PNG to a temporary file in the system's temp directory.
      final Directory tempDir = await getTemporaryDirectory();
      final File qrFile = await File(
        '${tempDir.path}/dastern_qr_$_token.png',
      ).create();
      await qrFile.writeAsBytes(pngBytes);

      // 5. Share both the image file and the token text via the native sheet.
      await Share.shareXFiles(
        [XFile(qrFile.path, mimeType: 'image/png')],
        text: l10n.shareQrAndCodeMessage(_token!),
      );
    } catch (e) {
      // If anything goes wrong (e.g., rendering not ready), fall back to
      // sharing the token text only.
      if (mounted) {
        await Share.share(l10n.shareQrAndCodeMessage(_token ?? ''));
      }
    }
  }

  void _copyToken() {
    if (_token != null) {
      final l10n = AppLocalizations.of(context)!;
      Clipboard.setData(ClipboardData(text: _token!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
    }
  }
}
