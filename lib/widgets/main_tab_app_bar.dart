import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/screens/main_shell/y01_my_screen.dart';
import 'package:petdate/theme/tokens.dart';

/// Left-aligned title + profile action used by main-tab screens.
class MainTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainTabAppBar({super.key, required this.title});

  final String title;

  static const profileButtonKey = ValueKey('profile-app-bar-button');

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
      title: Text(title),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          key: profileButtonKey,
          tooltip: AppCopy.navMy,
          icon: const Icon(Icons.account_circle_outlined, size: 28),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Y01MyScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
