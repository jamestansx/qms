import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qms_staff/appointment/view/add_appointment.dart';
import 'package:qms_staff/dashboard/bloc/wearable_bloc.dart';
import 'package:qms_staff/dashboard/services/wearables_repo.dart';
import 'package:qms_staff/dashboard/view/dashboard_page.dart';
import 'package:qms_staff/dashboard/view/wearables_list.dart';
import 'package:qms_staff/queue/view/queue_status_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QmsStaffApp(),
    ),
  );
}

class QmsStaffApp extends StatelessWidget {
  const QmsStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "QMS Staff",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("QMS Dashboard"),
        ),
        body: const HomePage(),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async => showDialog(
            context: context,
            builder: (context) => const AddAppointmentPage(),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController pageController = PageController();
  final SideMenuController sideMenu = SideMenuController();
  late final WearablesRepo _wearablesRepo;

  SideMenuDisplayMode displayMode = SideMenuDisplayMode.open;
  int rotate = 90;

  @override
  void initState() {
    super.initState();
    sideMenu.addListener((idx) {
      pageController.jumpToPage(idx);
    });

    _wearablesRepo = WearablesRepo();
  }

  @override
  void dispose() {
    _wearablesRepo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _wearablesRepo,
      child: BlocProvider(
        create: (_) => WearableBloc(
          wearableRepo: _wearablesRepo,
        )
          ..add(MonitorDashboard())
          ..add(WearablesFetched()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SideMenu(
              style: SideMenuStyle(
                displayMode: displayMode,
              ),
              controller: sideMenu,
              items: [
                SideMenuItem(
                  title: "Dashboard",
                  onTap: (index, _) {
                    sideMenu.changePage(index);
                  },
                ),
                SideMenuItem(
                  title: "Queue",
                  onTap: (index, _) {
                    sideMenu.changePage(index);
                  },
                ),
              ],
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                children: [
                  Row(
                    children: [
                      const WearablesList(),
                      BlocBuilder<WearableBloc, WearableState>(
                          builder: (context, state) {
                        return DashboardPage(
                          controller: _wearablesRepo.controller,
                        );
                      }),
                    ],
                  ),
                  const QueueStatusPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
