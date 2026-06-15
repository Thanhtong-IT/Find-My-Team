import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/constants.dart';
import 'core/di/injection.dart';
import 'core/repository/secure_storage_repository.dart';
import 'core/websocket/websocket_client.dart';
import 'core/connectivity/connectivity_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/services/auth_api_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/main/screens/main_navigation_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/setup_profile_screen.dart';
import 'features/profile/bloc/profile_bloc.dart';
import 'features/profile/services/user_api_service.dart';
import 'features/team/bloc/team_bloc.dart';
import 'features/team/services/team_api_service.dart';
import 'features/notification/bloc/notification_bloc.dart';
import 'features/explore/bloc/explore_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const FindMyTeamApp());
}

class FindMyTeamApp extends StatelessWidget {
  const FindMyTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authApiService: AuthApiService(),
            secureStorage: getIt<SecureStorageRepository>(),
            wsClient: getIt<WebSocketClient>(),
          )..add(const AuthCheckRequested()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(
            userApiService: UserApiService(),
          ),
        ),
        BlocProvider<TeamBloc>(
          create: (_) => TeamBloc(
            teamApiService: TeamApiService(),
          ),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => NotificationBloc(),
        ),
        BlocProvider<ExploreBloc>(
          create: (_) => ExploreBloc(),
        ),
        BlocProvider<ConnectivityBloc>(
          create: (_) => ConnectivityBloc(
            wsClient: getIt<WebSocketClient>(),
          )..add(const ConnectivityStarted()),
        ),
        // ChatBloc tạo riêng trong CommunityChatScreen với community/channel cụ thể
      ],
      child: MaterialApp(
        title: 'Find My Team',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/setup-profile': (context) => const SetupProfileScreen(),
          '/main': (context) => const MainNavigationScreen(),
        },
        builder: (context, child) {
          return BlocListener<ConnectivityBloc, ConnectivityState>(
            listener: (context, state) {
              if (state.isOffline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Mất kết nối mạng. Đang thử lại...'),
                      ],
                    ),
                    backgroundColor: Colors.amber.shade700,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state.status == ConnectivityStatus.online) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Đã kết nối lại'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
