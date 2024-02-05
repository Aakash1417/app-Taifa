class Pins {
  String name;
  String client;
  double latitude;
  double longitude;
  DateTime lastUpdated;
  String createdBy;
  String? description;

  Pins({
    required this.name,
    required this.client,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    required this.createdBy,
    required this.description,
  });
}
