/// One of: pathway | intersection | entrance | destination
enum RouteNodeType {
  pathway,
  intersection,
  entrance,
  destination;

  static RouteNodeType fromString(String value) {
    return RouteNodeType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => RouteNodeType.pathway,
    );
  }
}

class RouteNode {
  const RouteNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  final String id;
  final double latitude;
  final double longitude;
  final RouteNodeType type;

  factory RouteNode.fromJson(Map<String, dynamic> json) => RouteNode(
        id: json['id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        type: RouteNodeType.fromString(json['type'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'type': type.name,
      };
}

class RouteEdge {
  const RouteEdge({
    required this.id,
    required this.fromNode,
    required this.toNode,
    required this.distance,
    required this.accessible,
    required this.indoor,
    required this.outdoor,
  });

  final String id;
  final String fromNode;
  final String toNode;
  final double distance;
  final bool accessible;
  final bool indoor;
  final bool outdoor;

  factory RouteEdge.fromJson(Map<String, dynamic> json) => RouteEdge(
        id: json['id'] as String,
        fromNode: json['fromNode'] as String,
        toNode: json['toNode'] as String,
        distance: (json['distance'] as num).toDouble(),
        accessible: json['accessible'] as bool? ?? true,
        indoor: json['indoor'] as bool? ?? false,
        outdoor: json['outdoor'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromNode': fromNode,
        'toNode': toNode,
        'distance': distance,
        'accessible': accessible,
        'indoor': indoor,
        'outdoor': outdoor,
      };
}
