import 'package:flutter/material.dart';
import 'package:petdate/legal/legal_documents.dart';
import 'package:petdate/theme/tokens.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xl),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: AppTypography.title.copyWith(fontSize: 17),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                section.body,
                style: AppTypography.body.copyWith(
                  height: 1.55,
                  color: AppColors.text,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
