import 'package:flutter/material.dart';
import 'package:mikomi/features/home/ui/pages/home_page.dart';
import 'package:mikomi/features/pilgrimage/ui/pages/pilgrimage_page.dart';
import 'package:mikomi/features/my/ui/pages/my_page.dart';
import 'package:mikomi/shared/widgets/bottom_navigation.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<Widget> _buildPages(BuildContext context) {
    return [const HomePage(), const PilgrimagePage(), const MyPage()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _buildPages(context)),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
