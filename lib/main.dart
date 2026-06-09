
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/utils/unit_system.dart';
import 'data/datasources/database_helper.dart';
import 'data/datasources/export_datasource.dart';
import 'data/datasources/gps_datasource.dart';
import 'data/repositories/project_repository_impl.dart';
import 'data/repositories/export_repository_impl.dart';
import 'presentation/cubits/tracking_cubit.dart';
import 'presentation/cubits/projects_cubit.dart';
import 'presentation/cubits/export_cubit.dart';
import 'presentation/cubits/compass_cubit.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const FMAApp());
}

class FMAApp extends StatelessWidget {
  const FMAApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dbHelper      = DatabaseHelper();
    final gpsDatasource = GpsDatasource();
    final exportDs      = ExportDatasource();
    final projectRepo   = ProjectRepositoryImpl(dbHelper);
    final exportRepo    = ExportRepositoryImpl(exportDs);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: projectRepo),
        RepositoryProvider.value(value: exportRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => TrackingCubit(
            gps: gpsDatasource,
            projectRepo: projectRepo,
          )),
          BlocProvider(create: (_) => ProjectsCubit(projectRepo)),
          BlocProvider(create: (_) => ExportCubit(exportRepo)),
          BlocProvider(create: (_) => CompassCubit()),
        ],
        child: MaterialApp(
          title: 'FMA Compaction Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}




class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slideAnim = Tween(begin: 24.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: Text(
                      'FMA',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Compaction Analyzer Pro',
                  style: tt.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'النظام الهندسي الشامل للدمك الذكي',
                  style: tt.bodyMedium,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text('v5.0.0', style: tt.labelSmall),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
