import 'package:calsnap/models/meal_entry.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

enum HealthAvailability {
  available,
  needsInstall,
  unavailable,
}

class HealthSyncResult {
  const HealthSyncResult({
    required this.status,
    this.errorMessage,
    this.recordId,
  });

  final HealthSyncStatus status;
  final String? errorMessage;
  final String? recordId;
}

abstract class HealthSyncGateway {
  Future<HealthAvailability> checkAvailability();
  Future<bool> hasWritePermission();
  Future<bool> requestWritePermission();
  Future<void> installHealthConnect();
  Future<HealthSyncResult> writeMeal(MealEntry meal);
}

class HealthConnectSyncService implements HealthSyncGateway {
  HealthConnectSyncService({Health? health}) : _health = health ?? Health();

  static const List<HealthDataType> _types = <HealthDataType>[
    HealthDataType.NUTRITION,
  ];
  static const List<HealthDataAccess> _permissions = <HealthDataAccess>[
    HealthDataAccess.WRITE,
  ];

  final Health _health;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    await _health.configure();
    _configured = true;
  }

  @override
  Future<HealthAvailability> checkAvailability() async {
    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      if (status == HealthConnectSdkStatus.sdkAvailable) {
        return HealthAvailability.available;
      }
      if (status ==
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        return HealthAvailability.needsInstall;
      }
      return HealthAvailability.unavailable;
    } catch (_) {
      return HealthAvailability.unavailable;
    }
  }

  @override
  Future<bool> hasWritePermission() async {
    try {
      await _ensureConfigured();
      final granted = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestWritePermission() async {
    final availability = await checkAvailability();
    if (availability != HealthAvailability.available) {
      return false;
    }
    // Check first so requestAuthorization never blocks when already granted.
    if (await hasWritePermission()) {
      return true;
    }
    try {
      return await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> installHealthConnect() async {
    try {
      await _ensureConfigured();
      await _health.installHealthConnect();
    } catch (_) {
      // Play Store redirection unavailable on unsupported profiles.
    }
  }

  @override
  Future<HealthSyncResult> writeMeal(MealEntry meal) async {
    final availability = await checkAvailability();
    if (availability == HealthAvailability.needsInstall) {
      return const HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: 'Health Connect belum dipasang atau perlu diperbarui.',
      );
    }
    if (availability == HealthAvailability.unavailable) {
      return const HealthSyncResult(
        status: HealthSyncStatus.skipped,
        errorMessage: 'Health Connect tidak tersedia di perangkat ini.',
      );
    }

    final permitted = await hasWritePermission();
    if (!permitted) {
      return const HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: 'Izin tulis nutrisi ke Health Connect belum aktif.',
      );
    }

    final endTime = meal.eatenAt;
    final startTime = endTime.subtract(const Duration(minutes: 1));

    try {
      final ok = await _health.writeMeal(
        mealType: _mapMealType(meal.category),
        startTime: startTime,
        endTime: endTime,
        clientRecordId: meal.id,
        clientRecordVersion: 1.0,
        name: meal.title,
        caloriesConsumed: meal.totalCalories,
        protein: meal.totalProtein,
        carbohydrates: meal.totalCarbs,
        fatTotal: meal.totalFat,
        recordingMethod: RecordingMethod.manual,
      );

      if (ok) {
        return HealthSyncResult(
          status: HealthSyncStatus.synced,
          recordId: meal.id,
        );
      }
      return const HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: 'Health Connect gagal menyimpan catatan makan.',
      );
    } on HealthPlatformException catch (e) {
      return HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: e.message ?? e.cause,
      );
    } on HealthException catch (e) {
      return HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: e.cause,
      );
    } on PlatformException catch (e) {
      return HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: e.message ?? 'Gagal terhubung ke Health Connect.',
      );
    } on UnsupportedError {
      return const HealthSyncResult(
        status: HealthSyncStatus.skipped,
        errorMessage: 'Health Connect tidak didukung di perangkat ini.',
      );
    } catch (_) {
      return const HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: 'Terjadi gangguan saat sinkron ke Health Connect.',
      );
    }
  }

  MealType _mapMealType(MealCategory category) {
    switch (category) {
      case MealCategory.breakfast:
        return MealType.BREAKFAST;
      case MealCategory.lunch:
        return MealType.LUNCH;
      case MealCategory.dinner:
        return MealType.DINNER;
      case MealCategory.snack:
        return MealType.SNACK;
    }
  }
}
