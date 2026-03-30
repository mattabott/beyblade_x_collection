import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:beyblade_x_collection/core/constants/app_constants.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';

class LocalDatasource {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<PartsDatabase> loadBundledDatabase() async {
    final jsonString = await rootBundle.loadString('assets/data/beyblade_parts_db.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PartsDatabase.fromJson(json);
  }

  Future<PartsDatabase?> loadLocalDatabase() async {
    try {
      final path = await _localPath;
      final file = File('$path/${AppConstants.dbFileName}');
      if (!await file.exists()) return null;
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PartsDatabase.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDatabase(PartsDatabase db) async {
    final path = await _localPath;
    final file = File('$path/${AppConstants.dbFileName}');
    final jsonString = jsonEncode(db.toJson());
    await file.writeAsString(jsonString);
  }

  Future<UserCollection> loadCollection() async {
    try {
      final path = await _localPath;
      final file = File('$path/${AppConstants.collectionFileName}');
      if (!await file.exists()) return const UserCollection();
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserCollection.fromJson(json);
    } catch (_) {
      return const UserCollection();
    }
  }

  Future<void> saveCollection(UserCollection collection) async {
    final path = await _localPath;
    final file = File('$path/${AppConstants.collectionFileName}');
    final jsonString = jsonEncode(collection.toJson());
    await file.writeAsString(jsonString);
  }

  Future<String> exportCollectionToString(UserCollection collection) async {
    return const JsonEncoder.withIndent('  ').convert(collection.toJson());
  }

  Future<UserCollection?> importCollectionFromString(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserCollection.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
