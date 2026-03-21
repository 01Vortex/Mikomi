import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mikomi/features/home/ui/pages/home_page.dart';
import 'package:mikomi/features/pilgrimage/ui/pages/pilgrimage_page.dart';
import 'package:mikomi/features/my/ui/pages/my_page.dart';
import 'package:mikomi/shared/widgets/bottom_navigation.dart';
import 'package:mikomi/core/services/navigation_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Widget> _buildPages(BuildContext context) {
    return [const HomePage(), const PilgrimagePage(), const MyPage()];
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = context.watch<NavigationService>();
    final currentIndex = navigationService.selectedTab;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _buildPages(context)),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) {
          navigationService.switchToTab(index);
        },
      ),
    );
  }
}
