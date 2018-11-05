import 'package:map_view/location.dart';
import 'package:map_view/polyline.dart';
import 'package:map_view/marker.dart';

class Trail {
  final String id;
  final String name;
  final List<Location> points;
  final Polyline polyline;
  final Marker startMarker;
  final Marker endMarker;
  final Uri uri;
  final String description;
  final String time;
  final double length;
  final double avgSpeed;



  Trail(this.id, this.name, this.points, this.startMarker,
      this.endMarker, this.polyline, this.uri, this.description,
      this.time, this.length, this.avgSpeed);
}