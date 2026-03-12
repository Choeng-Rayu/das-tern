import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/ui/scan/ocr_review_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OcrReviewView extends StatelessWidget {
  const OcrReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final String rawText =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return AppScaffold(
      title: 'OCR Review',
      showBackButton: true,
      body: Consumer<OcrReviewViewModel>(
        builder: (context, viewModel, _) {
          if (rawText.isNotEmpty &&
              viewModel.drafts.isEmpty &&
              !viewModel.isLoading) {
            viewModel.setRawText(rawText);
          }

          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Processing OCR...');
          }

          if (viewModel.drafts.isEmpty) {
            return const Center(child: Text('No medication drafts extracted'));
          }

          return ListView.separated(
            itemCount: viewModel.drafts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final draft = viewModel.drafts[index];
              return AppCard(
                child: Text('${draft.name} - ${draft.dosage} ${draft.unit}'),
              );
            },
          );
        },
      ),
    );
  }
}
