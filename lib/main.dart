import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/barter_service.dart';
import 'services/category_service.dart';
import 'services/skill_request_service.dart';
import 'providers/auth_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/explore_provider.dart';
import 'providers/barter_provider.dart';
import 'providers/category_provider.dart';
import 'providers/skill_request_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/skills/skill_list_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/explore/leaderboard_screen.dart';
import 'screens/barter/transaction_list_screen.dart';
import 'screens/barter/create_offer_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(CategoryService()),
        ),
        ChangeNotifierProvider(
          create: (_) => SkillRequestProvider(SkillRequestService()),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BarterProvider>(
          create: (context) => BarterProvider(
            BarterService(baseUrl: ApiService.baseUrl, getToken: () => ''),
          ),
          update: (context, auth, previous) {
            final service = BarterService(
              baseUrl: ApiService.baseUrl,
              getToken: () => auth.token ?? '',
            );
            return previous != null
                ? (previous..updateService(service))
                : BarterProvider(service);
          },
        ),
      ],
      child: MaterialApp(
        title: 'SkillBarter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/skills': (context) => const SkillListScreen(),
          '/explore': (context) => const ExploreScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/transactions': (context) => const TransactionListScreen(),
          '/create-offer': (context) => const CreateOfferScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
