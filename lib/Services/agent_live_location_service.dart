import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:http/http.dart' as http;

class LiveLocationService {
  StreamSubscription<Position>? _positionStream;

  void startSendingLocation(String agentId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // every 10 meters
      ),
    ).listen((Position position) {
      print('📍 Agent new location: ${position.latitude}, ${position.longitude}');
      _sendToBackend(agentId, position.latitude, position.longitude);
    });
  }

  void _sendToBackend(String agentId, double lat, double lng) async {
    // Use your API endpoint here
    // e.g. PUT /api/agents/{agentId}/location
    final body = {
      "latitude": lat,
      "longitude": lng,
    };

    // Example with http package
    await http.put(Uri.parse('https://runpro9ja-pxqoa.ondigitalocean.app/agents/$agentId/location'), body: jsonEncode(body));
  }

  void stopSending() {
    _positionStream?.cancel();
  }
}
