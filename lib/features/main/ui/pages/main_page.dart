import 'package:flutter/material.dart';
import 'package:mikomi/features/home/ui/pages/home_page.dart';
import 'package:mikomi/features/pilgrimage/ui/pages/pilgrimage_page.dart';
import 'package:mikomi/shared/widgets/bottom_navigation.dart';
import 'package:mikomi/config/localization/app_localizations.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<Widget> _buildPages(BuildContext context) {
    return [
      const HomePage(),
      const PilgrimagePage(),
      PlaceholderPage(title: AppLocalizations.of(context).message),
      PlaceholderPage(title: AppLocalizations.of(context).profile),
    ];
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

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
    );
  }
}
