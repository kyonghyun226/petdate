import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/widgets/common.dart';

class B01SparkScreen extends StatelessWidget {
  const B01SparkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppCopy.navSpark),
        automaticallyImplyLeading: false,
      ),
      body: const EmptyState(
        message: AppCopy.sparkEmpty,
        icon: Icons.auto_awesome_outlined,
      ),
    );
  }
}
