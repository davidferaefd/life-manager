import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';

class LocalStorageService {
  LocalStorageService(this._preferences);

  static const _storageKey = 'life_manager.app_data.v1';

  final SharedPreferences _preferences;

  AppData load() {
    final jsonString = _preferences.getString(_storageKey);
    if (jsonString == null) return AppData.empty();

    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Os dados locais do Life Manager estão inválidos.');
    }
    return AppData.fromJson(decoded);
  }

  Future<void> save(AppData data) async {
    final saved = await _preferences.setString(
      _storageKey,
      jsonEncode(data.toJson()),
    );
    if (!saved) {
      throw StateError('Não foi possível salvar os dados do Life Manager.');
    }
  }
}
