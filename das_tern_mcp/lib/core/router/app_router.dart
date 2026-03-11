/// Core router module — re-exports the canonical [AppRouter] defined in
/// `lib/utils/app_router.dart` so that files under `lib/core/` can import
/// from a consistent path.
///
/// Usage:
/// ```dart
/// import 'package:das_tern_mcp/core/router/app_router.dart';
///
/// Navigator.pushNamed(context, AppRouter.patientHome);
/// ```
export 'package:das_tern_mcp/utils/app_router.dart';
