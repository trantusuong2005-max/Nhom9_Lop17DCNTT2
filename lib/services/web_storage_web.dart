import 'dart:html' as html;

const _storageKey = 'travel_diary_trips_v1';

String? readWebTripsJson() {
  try {
    return html.window.localStorage[_storageKey];
  } catch (_) {
    return null;
  }
}

void writeWebTripsJson(String jsonStr) {
  try {
    html.window.localStorage[_storageKey] = jsonStr;
  } catch (_) {}
}