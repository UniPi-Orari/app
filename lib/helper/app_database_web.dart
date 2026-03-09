import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection(String dbName) {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: dbName,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'), // optional shared worker
    );

    if (result.missingFeatures.isNotEmpty) {
      // The browser doesn't support all desired features (e.g. shared workers).
      // WasmDatabase will fall back gracefully, so this is just informational.
      print(
        'Drift/sqlite3 is using a compatibility mode. '
        'Missing features: ${result.missingFeatures}',
      );
    }

    return result.resolvedExecutor;
  }));
}
