import 'package:geolocator/geolocator.dart';
import 'package:runpro9ja_agent/Services/sockect_service.dart';

final socketService = SocketService();

void startTrackingAgent() async {
  LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // send update every 10m
  );

  Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) {
    socketService.sendAgentLocation(position.latitude, position.longitude);
  });
}
