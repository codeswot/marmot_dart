import 'rust/frb_generated.dart';

bool _libraryReady = false;

Future<void> ensureNativeLibrary() async {
  if (!_libraryReady) {
    await RustLib.init();
    _libraryReady = true;
  }
}
