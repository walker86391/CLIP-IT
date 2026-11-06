/// Remote config boundary (Supabase-backed later).
///
/// Step 0: no implementation — interface only, so call sites can already be
/// written against it.
abstract class RemoteConfigService {
  Future<void> init();

  String? getString(String key);

  int? getInt(String key);

  bool? getBool(String key);

  Future<void> refresh();
}
