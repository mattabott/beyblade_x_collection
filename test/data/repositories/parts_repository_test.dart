import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/datasources/remote_datasource.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/data/repositories/parts_repository_impl.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}
class MockRemoteDatasource extends Mock implements RemoteDatasource {}

void main() {
  late MockLocalDatasource mockLocal;
  late MockRemoteDatasource mockRemote;
  late PartsRepositoryImpl repository;

  final testDb = PartsDatabase(
    blades: {'Test': PartStats(attack: 5, defense: 5, stamina: 5, weight: 5)},
    ratchets: {}, bits: {}, version: 1,
  );
  final updatedDb = testDb.copyWith(version: 2);

  setUp(() {
    mockLocal = MockLocalDatasource();
    mockRemote = MockRemoteDatasource();
    repository = PartsRepositoryImpl(local: mockLocal, remote: mockRemote);
  });

  group('getDatabase', () {
    test('returns local DB when available', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      final result = await repository.getDatabase();
      expect(result.version, 1);
      verifyNever(() => mockLocal.loadBundledDatabase());
    });

    test('falls back to bundled DB when local is null', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => null);
      when(() => mockLocal.loadBundledDatabase()).thenAnswer((_) async => testDb);
      final result = await repository.getDatabase();
      expect(result.version, 1);
    });
  });

  group('checkForUpdate', () {
    test('returns remote DB when version is higher', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      when(() => mockRemote.fetchDatabase()).thenAnswer((_) async => updatedDb);
      final result = await repository.checkForUpdate();
      expect(result, isNotNull);
      expect(result!.version, 2);
    });

    test('returns null when remote version is same or lower', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      when(() => mockRemote.fetchDatabase()).thenAnswer((_) async => testDb);
      final result = await repository.checkForUpdate();
      expect(result, isNull);
    });

    test('returns null when remote fetch fails', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      when(() => mockRemote.fetchDatabase()).thenAnswer((_) async => null);
      final result = await repository.checkForUpdate();
      expect(result, isNull);
    });
  });
}
