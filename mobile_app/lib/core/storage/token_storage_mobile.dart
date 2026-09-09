// Mobile/non-web stub — these functions are never called on mobile
// because token_storage.dart uses SharedPreferences directly for non-web.

void webSet(String key, String value) {}
String? webGet(String key) => null;
void webRemove(String key) {}
