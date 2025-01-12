import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qms/authentication/bloc/auth_bloc.dart';
import 'package:qms/authentication/services/authentication.dart';
import 'package:qms/authentication/view/login_page.dart';
import 'package:qms/home/view/homepage.dart';
import 'package:qms/queue/bloc/queue_bloc.dart';
import 'package:qms/queue/view/queue_status_page.dart';
import 'package:qms/theme.dart';

int id = 0;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();
String? selectedNotifPayload;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings("@mipmap/ic_launcher");

  final InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotifPayload =
        notificationAppLaunchDetails!.notificationResponse?.payload;
  }

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

    _isAndroidPermissionGranted();
    _requestPermission();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImpl =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? grantedNotifPermission =
          await androidImpl?.requestNotificationsPermission();
    }
  }

  @override
  void dispose() {
    _authRepo.dispose();
    selectNotificationStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authRepo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            lazy: false,
            create: (_) => AuthBloc(authRepo: _authRepo)..add(StreamAuth()),
          ),
          BlocProvider(
            lazy: false,
            create: (_) => QueueBloc(),
          ),
        ],
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
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      title: "Queue Management System",
      theme: MaterialTheme(Theme.of(context).textTheme).light().copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: 1.1,
                ),
          ),
      builder: (context, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            switch (state.status) {
              case AuthStatus.authenticated:
                {
                  if (selectedNotifPayload != null) {
                    QueueStatusPage.route();
                  }
                  _nav.pushAndRemoveUntil(HomePage.route(), (_) => false);
                }
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
