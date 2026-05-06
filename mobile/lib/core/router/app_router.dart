import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/requests/screens/requests_screen.dart';
import '../../features/requests/screens/create_request_screen.dart';
import '../../features/requests/screens/request_detail_screen.dart';
import '../../features/receipts/screens/receipts_screen.dart';
import '../../features/receipts/screens/upload_receipt_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/allocations/screens/allocations_screen.dart';
import '../../features/allocations/screens/create_allocation_screen.dart';
import '../../core/models/allocation_model.dart';
import '../../features/anomalies/screens/anomalies_screen.dart';
import '../../features/admin/screens/users_screen.dart';
import '../../features/admin/screens/create_user_screen.dart';
import '../../features/admin/screens/vehicles_screen.dart';
import '../widgets/main_scaffold.dart';

// Caches auth status so redirect never calls ref.read during Riverpod's rebuild cycle
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _authStatus = _ref.read(authProvider).status;
    _userRole = _ref.read(authProvider).user?.role;
    _ref.listen<AuthState>(authProvider, (_, next) {
      _authStatus = next.status;
      _userRole = next.user?.role;
      notifyListeners();
    });
  }
  final Ref _ref;
  late AuthStatus _authStatus;
  String? _userRole;

  AuthStatus get authStatus => _authStatus;
  String? get userRole => _userRole;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = notifier.authStatus == AuthStatus.authenticated;
      final isUnknown = notifier.authStatus == AuthStatus.unknown;
      // Public routes that don't require authentication
      final isPublic = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isUnknown) return null;
      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic) return '/dashboard';

      // Role-based route guards
      final role = notifier.userRole ?? '';
      final path = state.matchedLocation;

      // Admin-only: user/vehicle management
      if (path.startsWith('/admin/') && role != 'super_admin') return '/dashboard';

      // Finance + super_admin only: create/edit allocations
      if ((path == '/allocations/new' || path.endsWith('/edit')) &&
          role == 'driver') return '/allocations';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/requests',
            builder: (_, __) => const RequestsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const CreateRequestScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    RequestDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/receipts',
            builder: (_, __) => const ReceiptsScreen(),
            routes: [
              GoRoute(
                path: 'upload/:requestId',
                builder: (_, state) =>
                    UploadReceiptScreen(requestId: state.pathParameters['requestId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/allocations',
            builder: (_, __) => const AllocationsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const CreateAllocationScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => CreateAllocationScreen(
                  allocation: state.extra as AllocationModel?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/anomalies',
            builder: (_, __) => const AnomaliesScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          // Admin-only routes
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UsersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const CreateUserScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/vehicles',
            builder: (_, __) => const VehiclesScreen(),
          ),
        ],
      ),
    ],
  );
});
