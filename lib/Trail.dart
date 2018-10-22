import 'package:map_view/location.dart';
import 'package:map_view/polyline.dart';

class Trail {
  final String id;
  final String name;
  final List<Location> points;
  final Polyline polyline;
  final Uri uri;
  final String description;

  Trail(this.id, this.name, this.points, this.polyline, this.uri, this.description);
}