import 'package:building_management_tycoon/data/local_save_store.dart';

class MemorySaveStore implements LocalSaveStore {
  String? value;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<String?> read() async {
    if (failReads) throw StateError('Read failed');
    return value;
  }

  @override
  Future<void> write(String next) async {
    if (failWrites) throw StateError('Write failed');
    value = next;
  }
}
