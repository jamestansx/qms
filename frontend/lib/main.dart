import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qms/authentication/bloc/auth_bloc.dart';
import 'package:qms/authentication/services/authentication.dart';
import 'package:qms/authentication/view/login_page.dart';
import 'package:qms/home/view/homepage.dart';

void main() {
  runApp(const QmsApp());
}

class QmsApp extends StatefulWidget {
  const QmsApp({super.key});

  @override
  State<QmsApp> createState() => _QmsAppState();
}

class _QmsAppState extends State<QmsApp> {
  late final AuthRepo _authRepo;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepo();
  }

  @override
  void dispose() {
    _authRepo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authRepo,
      child: BlocProvider(
        lazy: false,
        create: (_) => AuthBloc(authRepo: _authRepo)..add(StreamAuth()),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _nav => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: "Queue Management System",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            switch (state.status) {
              case AuthStatus.authenticated:
                _nav.pushAndRemoveUntil(HomePage.route(), (_) => false);
              case AuthStatus.unauthenticated:
                _nav.pushAndRemoveUntil(LoginPage.route(), (_) => false);
              case AuthStatus.failure:
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                      const SnackBar(content: Text("Authentication Failed")));
              case AuthStatus.unknown:
                break;
            }
          },
          child: child,
        );
      },
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
