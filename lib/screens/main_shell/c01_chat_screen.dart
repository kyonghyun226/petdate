import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/widgets/common.dart';

class C01ChatScreen extends StatelessWidget {
  const C01ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppCopy.navChat),
        automaticallyImplyLeading: false,
      ),
      body: EmptyState(
        message: AppCopy.chatEmpty,
        hint: AppCopy.chatEmptyHint,
        icon: Icons.chat_bubble_outline_rounded,
      ),
    );
  }
}
