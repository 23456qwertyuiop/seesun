import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<({double lat, double lon})?> getBrowserPosition({required bool isManual}) async {
  final completer = Completer<({double lat, double lon})?>();
  try {
    final geo = web.window.navigator.geolocation;
    geo.getCurrentPosition(
      ((web.GeolocationPosition pos) {
        if (!completer.isCompleted) {
          completer.complete((
            lat: pos.coords.latitude.toDouble(),
            lon: pos.coords.longitude.toDouble(),
          ));
        }
      }).toJS,
      ((web.GeolocationPositionError _) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }).toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 6000,
        maximumAge: isManual ? 0 : 300000,
      ),
    );
  } catch (_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }
  return completer.future.timeout(
    const Duration(seconds: 7),
    onTimeout: () => null,
  );
}
