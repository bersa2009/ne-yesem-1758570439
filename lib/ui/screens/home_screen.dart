import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'ingredients_screen.dart';
import 'pantry_screen.dart';
import 'shopping_list_screen.dart';
import 'favorites_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const IngredientsScreen(),
    const PantryScreen(),
    const ShoppingListScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in
          return Scaffold(
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Tarif Ara',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.kitchen),
                  label: 'Kiler',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Alışveriş',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Favoriler',
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(snapshot.data?.displayName ?? 'Kullanıcı'),
                    accountEmail: Text(snapshot.data?.email ?? ''),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage: snapshot.data?.photoURL != null
                          ? NetworkImage(snapshot.data!.photoURL!)
                          : null,
                      child: snapshot.data?.photoURL == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Ayarlar'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to settings screen
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Yardım'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to help screen
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Çıkış Yap'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _authService.signOut();
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          // User is not logged in
          return const AuthScreen();
        }
      },
    );
  }
}