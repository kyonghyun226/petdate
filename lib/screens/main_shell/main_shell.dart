import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/screens/main_shell/b01_spark_screen.dart';
import 'package:petdate/screens/main_shell/c01_chat_screen.dart';
import 'package:petdate/screens/main_shell/h01_home_screen.dart';
import 'package:petdate/screens/main_shell/meongstar_screen.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/widgets/bottom_nav.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(sessionProvider.select((s) => s.mainTab));

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          H01HomeScreen(),
          B01SparkScreen(),
          C01ChatScreen(),
          MeongstarScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: tab,
        onSelect: ref.read(sessionProvider.notifier).selectTab,
      ),
    );
  }
}
