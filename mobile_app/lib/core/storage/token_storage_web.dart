// Web implementation — uses localStorage via dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void webSet(String key, String value) {
  html.window.localStorage[key] = value;
}

String? webGet(String key) {
  return html.window.localStorage[key];
}

void webRemove(String key) {
  html.window.localStorage.remove(key);
}
