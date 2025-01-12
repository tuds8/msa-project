import 'package:flutter/material.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/register_page.dart';
import 'package:frontend/screens/landing_page.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/screens/shop/shop_edit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use Google Fonts here
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          bodyLarge: GoogleFonts.lato(
            textStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.normal),
          ),
          displayLarge: GoogleFonts.oswald(
            textStyle: const TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
          ),
        ),
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4.0,
          margin: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          ),
        ),
        appBarTheme: const AppBarTheme(
          color: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 4.0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          textColor: Colors.black87,
          iconColor: Colors.teal,
        ),
      ),
      initialRoute: '/landing',
      routes: {
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainScreen(),
        '/edit-shop': (context) => EditShopPage(
          shopDetails: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
        ),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ro', 'RO'),
      ],
      locale: const Locale('ro', 'RO'),
    );
  }
}
