// Package imports:
import 'package:mocktail/mocktail.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/backend/core/infrastructure/backend_headers.dart';
import 'package:flutter_template/backend/core/infrastructure/backend_headers_cache.dart';
import 'package:flutter_template/core/infrastructure/sembast_database.dart';

class FakeSembastDatabase extends Fake implements SembastDatabase {
  FakeSembastDatabase(this._database);
  final Database _database;

  @override
  Database get instance => _database;
}

void main() {
  group('BackendHeadersCache', () {
    group('.saveHeaders', () {
      test('stores headers json string with uri string as key ', () async {
        final factory = newDatabaseFactoryMemory();

        final memoryDatabase = await factory.openDatabase('test.db');

        final SembastDatabase fakeSembastDatabase = FakeSembastDatabase(memoryDatabase);

        final backendHeadersCache = BackendHeadersCache(fakeSembastDatabase);

        final uri = Uri(path: '');

        final backendHeadersJson = <String, dynamic>{
          'etag': '33a64df551425fcc55e4d42a148795d9f25f89d4',
        };
        final backendHeaders = BackendHeaders.fromJson(backendHeadersJson);

        await backendHeadersCache.saveHeaders(uri, backendHeaders);

        final actualData = await BackendHeadersCache.store.record(uri.toString()).get(fakeSembastDatabase.instance);
        final expectedData = backendHeaders.toJson();

        expect(actualData, expectedData);
      });
    });

    group('.getHeaders', () {
      test('retrieves the headers stored in the database', () async {
        final factory = newDatabaseFactoryMemory();

        final memoryDatabase = await factory.openDatabase('test.db');

        final SembastDatabase fakeSembastDatabase = FakeSembastDatabase(memoryDatabase);

        final backendHeadersCache = BackendHeadersCache(fakeSembastDatabase);

        final uri = Uri(path: '');

        final backendHeadersJson = <String, dynamic>{
          'etag': '33a64df551425fcc55e4d42a148795d9f25f89d4',
        };

        final backendHeaders = BackendHeaders.fromJson(backendHeadersJson);

        await BackendHeadersCache.store.record(uri.toString()).put(fakeSembastDatabase.instance, backendHeadersJson);

        final actualData = await backendHeadersCache.getHeaders(uri);

        final expectedData = backendHeaders;

        expect(actualData, expectedData);
      });
    });

    group('.deleteHeaders', () {
      test('delete the headers stored in the database', () async {
        final factory = newDatabaseFactoryMemory();

        final memoryDatabase = await factory.openDatabase('test.db');

        final SembastDatabase fakeSembastDatabase = FakeSembastDatabase(memoryDatabase);

        final backendHeadersCache = BackendHeadersCache(fakeSembastDatabase);

        final uri = Uri(path: '');

        final backendHeadersJson = <String, dynamic>{
          'etag': '33a64df551425fcc55e4d42a148795d9f25f89d4',
        };

        await BackendHeadersCache.store.record(uri.toString()).put(fakeSembastDatabase.instance, backendHeadersJson);

        await backendHeadersCache.deleteHeaders(uri);

        final actualData = await BackendHeadersCache.store.record(uri.toString()).get(fakeSembastDatabase.instance);

        // ignore: prefer_void_to_null
        const Null expectedData = null;

        expect(actualData, expectedData);
      });
    });
  });
}
