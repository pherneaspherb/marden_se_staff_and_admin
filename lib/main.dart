import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin/dashboardPage.dart';
import 'admin/screens/authLogin.dart';
import 'admin/screens/authSignUp.dart';
import 'landingPage.dart';
import 'admin/screens/Inventory/inventoryTab.dart';
import 'package:marden_se_staff_and_admin/admin/screens/Transactions/transactionsTab.dart';
import 'admin/screens/ManageAccount/manageAccountTab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if admin is already signed in
  User? currentUser = FirebaseAuth.instance.currentUser;
  String initialRoute = currentUser != null ? '/admin-dashboard' : '/';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marden Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4B007D),
          background: Colors.black,
          surface: Color(0xFF2A2A2A),
          onPrimary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white70,
        ),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingPage());
          case '/admin-login':
            return MaterialPageRoute(
              builder: (_) => AuthLoginPage(role: 'admin'),
            );
          case '/staff-login':
            return MaterialPageRoute(
              builder: (_) => AuthLoginPage(role: 'staff'),
            );
          case '/admin-signup':
            return MaterialPageRoute(
              builder: (_) => AuthSignUpPage(role: 'admin'),
            );
          case '/admin-dashboard':
            return MaterialPageRoute(
              builder: (_) => const DashboardPage(role: 'admin'),
            );
          case '/staff-dashboard':
            return MaterialPageRoute(
              builder: (_) => const DashboardPage(role: 'staff'),
            );
          case '/admin-inventory':
            return MaterialPageRoute(builder: (_) => InventoryWidget());
          case '/transactions':
            return MaterialPageRoute(builder: (_) => TransactionsTab());
          case '/admin-manage-accounts':
            return MaterialPageRoute(builder: (_) => const ManageAccountTab());

          default:
            return null;
        }
      },
    );
  }
}
