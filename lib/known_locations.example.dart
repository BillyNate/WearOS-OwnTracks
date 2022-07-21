class Location {
  late double latitude;
  late double longitude;

  Location({required this.latitude, required this.longitude});
}

Map<String, Location> knownLocations = {
  '00:00:00:00:00:00': Location(latitude: 0.0, longitude: 0.0),
};
