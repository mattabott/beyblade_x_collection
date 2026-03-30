import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/datasources/remote_datasource.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/repositories/parts_repository_impl.dart';
import 'package:beyblade_x_collection/domain/repositories/parts_repository.dart';

final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  return LocalDatasource();
});

final remoteDatasourceProvider = Provider<RemoteDatasource>((ref) {
  return RemoteDatasource();
});

final partsRepositoryProvider = Provider<PartsRepository>((ref) {
  return PartsRepositoryImpl(
    local: ref.watch(localDatasourceProvider),
    remote: ref.watch(remoteDatasourceProvider),
  );
});

final partsDatabaseProvider =
    AsyncNotifierProvider<PartsDatabaseNotifier, PartsDatabase>(
  PartsDatabaseNotifier.new,
);

class PartsDatabaseNotifier extends AsyncNotifier<PartsDatabase> {
  @override
  Future<PartsDatabase> build() async {
    final repo = ref.watch(partsRepositoryProvider);
    final db = await repo.getDatabase();
    _checkForUpdate(repo);
    return db;
  }

  Future<void> _checkForUpdate(PartsRepository repo) async {
    final update = await repo.checkForUpdate();
    if (update != null) {
      await repo.updateDatabase(update);
      state = AsyncData(update);
    }
  }

  Future<void> forceUpdate() async {
    state = const AsyncLoading();
    final repo = ref.read(partsRepositoryProvider);
    final update = await repo.checkForUpdate();
    if (update != null) {
      await repo.updateDatabase(update);
      state = AsyncData(update);
    } else {
      state = AsyncData(await repo.getDatabase());
    }
  }
}
