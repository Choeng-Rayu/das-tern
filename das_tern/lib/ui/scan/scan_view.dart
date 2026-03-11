import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/ui/scan/scan_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Scan',
      currentIndex: 2,
      body: Consumer<ScanViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCard(
                child: Text('Use mock OCR scanning for migration coverage.'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Mock Scan',
                onPressed: viewModel.mockScan,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Review OCR Result',
                variant: AppButtonVariant.secondary,
                onPressed: viewModel.rawText.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(
                          AppRouter.ocrReview,
                          arguments: viewModel.rawText,
                        );
                      },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    viewModel.rawText.isEmpty
                        ? 'No scan result yet.'
                        : viewModel.rawText,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
