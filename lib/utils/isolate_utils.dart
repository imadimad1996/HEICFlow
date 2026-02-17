import 'dart:async';
import 'dart:isolate';

Future<T> runInBackground<T>(FutureOr<T> Function() computation) {
  return Isolate.run<T>(computation);
}
