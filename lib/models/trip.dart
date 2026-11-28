class Trip {
  final int? id;
  final String name;
  final String location;
  final String startDate;
  final double budget;
  final String itinerary;

  Trip({
    this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.budget,
    required this.itinerary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'startDate': startDate,
      'budget': budget,
      'itinerary': itinerary,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      name: (map['name'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      startDate: (map['startDate'] ?? '').toString(),
      budget: ((map['budget'] ?? 0) as num).toDouble(),
      itinerary: (map['itinerary'] ?? '').toString(),
    );
  }
}