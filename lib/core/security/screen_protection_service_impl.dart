import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/security/screen_protection_gateway.dart';
import 'package:keyva/core/security/screen_protection_service.dart';
import 'package:keyva/core/session/session_service.dart';

class ScreenProtectionServiceImpl implements ScreenProtectionService {
  ScreenProtectionServiceImpl({
    required ScreenProtectionGateway gateway,
    required UserDataSource users,
    required SessionService session,
    required HiveDatabase database,
  }) : _gateway = gateway,
       _users = users,
       _session = session,
       _database = database;

  final ScreenProtectionGateway _gateway;
  final UserDataSource _users;
  final SessionService _session;
  final HiveDatabase _database;

  bool _enabled = false;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<Result<void>> setEnabled(bool enabled) async {
    final applied = await _gateway.setSecure(enabled);
    if (applied is FailureResult<void>) {
      return applied;
    }
    _enabled = enabled;
    return const Success(null);
  }

  @override
  Future<Result<void>> applyPersisted() async {
    final resolved = await _resolvePreventScreenshots();
    if (resolved is FailureResult<bool>) {
      return FailureResult(resolved.failure);
    }
    return setEnabled((resolved as Success<bool>).data);
  }

  Future<Result<bool>> _resolvePreventScreenshots() async {
    final sessionUserId = _session.current?.userId;
    if (_session.isAuthenticated && sessionUserId != null) {
      return _preventScreenshotsForUser(sessionUserId);
    }

    try {
      final activeId = _database.appSettings.get(HiveSettingsKeys.activeUserId);
      if (activeId is String && activeId.isNotEmpty) {
        final fromActive = await _preventScreenshotsForUser(activeId);
        if (fromActive is Success<bool>) {
          return fromActive;
        }
        if (fromActive is FailureResult<bool> &&
            fromActive.failure is! AuthenticationFailure) {
          return fromActive;
        }
      }
    } catch (error) {
      return FailureResult(_mapLookupError(error));
    }

    final listed = await _users.list();
    if (listed is FailureResult<List<UserRecord>>) {
      return FailureResult(listed.failure);
    }
    final users = (listed as Success<List<UserRecord>>).data;
    return Success(
      users.any((user) => user.securitySettings.preventScreenshots),
    );
  }

  Future<Result<bool>> _preventScreenshotsForUser(String userId) async {
    final loaded = await _users.findById(userId);
    if (loaded is FailureResult<UserRecord?>) {
      return FailureResult(loaded.failure);
    }
    final user = (loaded as Success<UserRecord?>).data;
    if (user == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(user.securitySettings.preventScreenshots);
  }

  static AppFailure _mapLookupError(Object error) {
    if (error is AppFailure) {
      return error;
    }
    return const DatabaseFailure();
  }
}
