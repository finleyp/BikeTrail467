import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:map_view/polyline.dart';
import 'package:map_view/figure_joint_type.dart';
import 'package:map_view/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'Constants.dart';
import 'SettingsMenu.dart';
import 'SavedTrails.dart';
import 'Trail.dart';
import 'LocalTrails.dart';
import 'SaveDialog.dart';

typedef void SaveCallback(String trailName, List<Polyline> lines, String time, double avgSpeed, double distance, bool isPublic);


var geolocator = Geolocator();

List<Polyline> polyLines = new List();
List<Polyline> loadLines = new List();
List<Polyline> dbLines = new List();
List<Marker> loadMarkers = new List();

List<Widget> _children = [];

List<Trail> trails = new List();
List<Trail> localTrails = new List();

Location onLoadLoc;

MapView mapView = new MapView();

bool isRecording = false;

//Settings
//Settings settings;

//Themes
final ThemeData darkTheme = new ThemeData(
  brightness: Brightness.dark,
  primaryTextTheme: new TextTheme(caption: new TextStyle(color: Colors.white)),
  hintColor: Colors.white,
  highlightColor: Colors.white,
  textSelectionColor: Colors.white,
  textSelectionHandleColor: Colors.white,
  buttonColor: Colors.grey,
  splashColor: Colors.teal,
);
final ThemeData lightTheme = new ThemeData(
    brightness: Brightness.light
);


StreamSubscription<Position> positionStream;




var trailNameController = new TextEditingController();

var isDev = true;
var count = 0;
var aveCount = 1;
var aveSpeed = 0.0;
var uuid = new Uuid();
var _currentIndex = 0;

bool publicCheck = false;

ThemeData theme;


Polyline newLine = new Polyline(
    "1",
    <Location>[
    ],
    width: 15.0,
    color: Colors.blue,
    jointType: FigureJointType.round);

Polyline loadLine = new Polyline(
    "1",
    <Location>[
    ],
    width: 15.0,
    color: Colors.black,
    jointType: FigureJointType.round);


class Dashboard extends StatefulWidget {
  final SaveCallback callback;
  final ThemeData theme;
  final bool isMeters;
  final bool isKph;
  final bool isDebug;
  final Trail rideTrail;

  Dashboard({
    Key key,
    @required this.theme,
    @required this.isKph,
    @required this.isMeters,
    @required this.isDebug,
    this.rideTrail,
    @required this.callback}) : super(key: key);

  @override
  DashboardState createState() {
    return DashboardState();
  }
}

class DashboardState extends State<Dashboard> {

  //Dashboard Values
  double speedVal = 0.0;
  double aveSpeedVal = 0.0;
  String timeVal = "00:00:00:00";
  double distanceLeftVal = 0.0;
  double distanceTraveledVal = 0.0;
  int countVal = 0;
  double latVal = 0.0;
  double longVal = 0.0;
  double altVal = 0.0;


  //Stopwatch
  Stopwatch stopWatch;

  //Timer to determine how frequently the stopwatch gui updates
  Timer timer;


  final String speedPref = "speedPref";
  final String distPref = "distPref";
  final String darkPref = "darkPref";
  final String debugPref = "debugPref";
  // Initilize cameraPosition which displays the location on google maps
  CameraPosition cameraPosition;

  //Initilizes a static map with our google api_key
  //var staticMapProvider = new StaticMapProvider(api_key);

  //Uri for static map, Used later to display static map
  Uri staticMapUri;


  List<Polyline> polyLine = new List();

  //save stuff
  File trailsJsonFile;
  Directory dir;
  String fileName = "Trails.json";
  bool fileExists = false;
  Map<String, dynamic> trailContent;

  double dist = 0.0;


  void initState() {
    super.initState();

    stopWatch = new Stopwatch();

    if (widget.rideTrail != null){
      toggleRecording(true);
    }
  }

  double convertSpeed(var speed){

    if(widget.isKph) {
      //Convert from Mps to Kph -- 1 mps = 3.6 kph
      double speedKph = speed * 3.6;
      return speedKph;//.toStringAsFixed(1);

    } else {
      //Convert to Mph -- 1 mps = 2.236934 mph
      double speedMph = speed * 2.236934;
      return speedMph;//.toStringAsFixed(1);

    }
  }

  double convertAlt(var altInM){
    if(widget.isMeters) {
      //return meters
      return altInM;

    } else {
      //Convert to feet -- 1 meter = 3.28084 feet
      double altFt = altInM * 3.28084;
      return altFt;

    }
  }

  double convertDist(var distInKm){
    if(widget.isMeters) {
      //return Km
      return distInKm;

    } else {
      //Convert to miles -- 1 meter = 3.28084 feet
      double dist = distInKm / 1.609;
      return dist;

    }
  }


  double calculateDistance(Location loc1, Location loc2) {

    /// Source for calculation, needed because all the plugins don't work
    ///
    /// https://stackoverflow.com/questions/27928/calculate-distance-between-two-latitude-longitude-points-haversine-formula
    ///
    /// author: https://stackoverflow.com/users/1090562/salvador-dali

    var p = 0.017453292519943295;    // Math.PI / 180
    var c = math.cos;
    var a = 0.5 - c((loc2.latitude - loc1.latitude) * p)/2 +
        c(loc1.latitude * p) * c(loc2.latitude * p) *
            (1 - c((loc2.longitude - loc1.longitude) * p))/2;

    var distanceInKm = 12742 * math.asin(math.sqrt(a));

    return distanceInKm;

  }

  double calculateDistanceLeft(Location currentLoc) {

    Location closestLoc;
    double closestDist = -1.0;

    //Finds the closest point on the trail to the users current location
    for (var point in widget.rideTrail.points) {
      double temp = calculateDistance(currentLoc, point);
      if (temp < closestDist || closestDist == -1.0) {
        closestDist = temp;
        closestLoc = point;
      }
    }

    bool pointFound = false;
    double distanceLeft = 0.0;
    Location loc1;
    Location loc2;

    //Find remaining distance
    for (var point in widget.rideTrail.points) {
      if (point == closestLoc) {
        pointFound = true;
      }
      if (pointFound) {
        //calculate distance
        if (loc1 != null && loc2 != null) {

          //move to the next section of the path
          loc1 = loc2;
          loc2 = point;

          distanceLeft += calculateDistance(loc1, loc2);
        } else if (loc1 == null && loc2 == null) {
          loc1 = point;
        } else if (loc1 != null && loc2 == null) {
          loc2 = point;
          //first section of path
          distanceLeft += calculateDistance(loc1, loc2);
        }
      }
    }

//    print(distanceLeft);

    return distanceLeft;


  }

  void clearDashboard() {
    setState(() {
      timeVal = "00:00:00:00";
      speedVal = 0.0;
      aveSpeedVal = 0.0;
      countVal = 0;
      latVal = 0.0;
      longVal = 0.0;
      altVal = 0.0;
      distanceTraveledVal = 0.0;
      distanceLeftVal = 0.0;
    });

    dist = 0.0;
    countVal = 0;
    count = 0;
    newLine = new Polyline(
        "1",
        <Location>[
        ],
        width: 15.0,
        color: Colors.blue,
        jointType: FigureJointType.round);
    polyLines = [];

    if(isRecording) {
      toggleRecording(true);
    }

    widget.callback(null, null, "-1", null, null, null);

  }

  void toggleRecording(bool isRiding) {

    //Get correct units
//    SettingsMenu settings = new SettingsMenu();
//
//    isMetricSpeed = settings.getIsMetricSpeed;
//    isMetricDist = settings.getIsMetricDist;

    //toggle the isRecording boolean
    if(mounted == true) {
      setState(() => isRecording = !isRecording);
    }

    print("__________ $isRecording _________________");

    //starts stream if isRecording is true
    if (isRecording){
      //Reset and start stopwatch
      stopWatch.reset();
      stopWatch.start();
      //start timer for stopwatch gui updates
      timer = new Timer.periodic(new Duration(milliseconds: 30), setStopWatchGui);

      getPositionStream(isRiding);

      widget.callback(null, null, "rec", null, null, null);

    } else {

      //Stop the stopwatch
      stopWatch.stop();
      //Stop the timer
      timer.cancel();

      //cancels the stream if isRecording is false
      positionStream.cancel();

      if(mounted == true) {
        setState(() {
          speedVal = 0.0;
          //aveSpeedVal = 0.0;
        });
      }

      if(widget.rideTrail != null && !isRiding) {
        stopRide(widget.rideTrail.id, polyLines, timeVal, aveSpeed, distanceTraveledVal, null);
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(widget.rideTrail.name + " updated, clear dashboard")));

      } else if (widget.rideTrail != null && isRiding) {
        stopRide(null, null, "-1", null, null, null);
      }

    }
  }

  void setStopWatchGui(Timer timer){
    if (stopWatch.isRunning && mounted) {
      setState(() {
        timeVal = stopWatch.elapsed.toString().substring(0, 10);
      });
    }
  }

  void getPositionStream(bool isRiding) {

    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.best, distanceFilter: 1);

    double distance = 0.0;

    Location loc1;
    Location loc2;

    //streamSubscription to get location on update
    positionStream = geolocator.getPositionStream(
        locationOptions).listen(
            (Position position) {
          print(
              position == null ? 'Unknown' : position.latitude.toString() + ', ' +
                  position.longitude.toString());


          //Unit conversions, rounding, and string building
          double speed = position.speed.toDouble();


          double altitude = convertAlt(position.altitude);

          //convert the Position object to Location object to be usable with map_view
          Location loc = new Location.full(position.latitude, position.longitude, stopWatch.elapsed.inSeconds,
              position.altitude, position.speed, position.heading, 0.0, 0.0);

          //Add point to polylines object
          newLine.points.add(loc);

          //calculate distance
          if (loc1 != null && loc2 != null) {

            //move to the next section of the path
            loc1 = loc2;
            loc2 = loc;

            distance = calculateDistance(loc1, loc2);
          } else if (loc1 == null && loc2 == null) {
            loc1 = loc;
          } else if (loc1 != null && loc2 == null) {
            loc2 = loc;
            //first section of path
            distance = calculateDistance(loc1, loc2);
          }

          count++;


          if (aveCount <= 1){
            aveSpeed = speed;
            aveCount++;
          }else if (speed > 0.25){
            aveSpeed = ((aveSpeed * ((aveCount-1).toDouble()/aveCount.toDouble()))+(speed * (1.0/aveCount.toDouble())));
            aveCount++;
          }

          if(mounted == true) {
            setState(() {
              speedVal = convertSpeed(speed);
              aveSpeedVal = convertSpeed(aveSpeed);
              countVal = count;
              latVal = loc.latitude;
              longVal = loc.longitude;
              altVal = altitude;
              distanceTraveledVal += distance;

              if (isRiding) {
                distanceLeftVal = calculateDistanceLeft(loc);
              }

            });

            dist += distance;

          }



          //Clear the list of polylines before adding the new version
          polyLines.clear();

          //Add newLine to List of polylines
          polyLines.add(newLine);

          mapView.clearPolylines();

          //Update lines on map
          mapView.setPolylines(polyLines);
          //mapView.setPolylines(loadLines);

        });



  }

  void saveTrail(String trailName, List<Polyline> lines, String time, double avgSpeed, double distance, bool isPublic) {
    clearDashboard();
    widget.callback(trailName, lines, time, avgSpeed, distance, isPublic);
  }

  void stopRide(String trailID, List<Polyline> lines, String time, double avgSpeed, double distance, bool isPublic) {
    widget.callback(trailID, polyLines, timeVal, aveSpeed, distanceTraveledVal, isPublic);
  }

  //Redundant
  void saveTrailDialogCallback(String trailName, bool isPublic){
    saveTrail(trailName, polyLines, timeVal, aveSpeed, distanceTraveledVal, isPublic);
  }

  _showDialog() async {
    await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return new SaveDialog(callback: (name, public) => saveTrailDialogCallback(name, public));
        }
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
// decoration: new BoxDecoration(color: Colors.black87),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          new Container(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Container(
                  child: new Text(
                      speedVal.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: new TextStyle(
                          fontSize: 60.0, fontWeight: FontWeight.bold)
                  ),
                ),
                new Container(
                  child: new Text(
                      widget.isKph ? 'Current Speed(kph)' : 'Current Speed(mph)',
                      textAlign: TextAlign.center,
                      style: new TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          ),
          new Row( // upper middle
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Container(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Container(
//                        width: 150.0,
//                        height: 40.0,
//color: Colors.blue,
                      child: new Text(
                          timeVal,
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 30.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                    new Container(
                      child: new Text(
                          'Time',
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 12.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
              new Container(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Container(
//                        width: 150.0,
//                        height: 40.0,
                      child: new Text(
                          convertDist(distanceTraveledVal).toStringAsFixed(3),
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 30.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                    new Container(
                      child: new Text(
                        widget.isMeters
                            ? 'Distance Traveled(km)'
                            : 'Distance Traveled(mi)',
                        textAlign: TextAlign.center,
                        style: new TextStyle(
                          fontSize: 12.0, fontWeight: FontWeight.bold,),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Container(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Container(
//                        width: 150.0,
//                        height: 40.0,
                      child: new Text(
                          aveSpeedVal.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                    new Container(
                      child: new Text(
                        widget.isKph ? 'Average Speed(kph)' : 'Average Speed(mph)',
                        textAlign: TextAlign.center,
                        style: new TextStyle(
                          fontSize: 12.0, fontWeight: FontWeight.bold,),
                      ),
                    ),
                  ],
                ),
              ),
              new Container(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Container(
//                        width: 150.0,
//                        height: 40.0,
                      child: new Text(
                          widget.rideTrail != null ? convertDist(distanceLeftVal).toStringAsFixed(3) : "--",
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                      new Container(
                        child: new Text(
                          'Remaining Distance(mi)',
                          textAlign: TextAlign.center,
                          style: new TextStyle( fontSize: 12.0, fontWeight: FontWeight.bold, ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
//Debug optional Widgets
          new Container(
//height: 40.0,
            child: widget.isDebug ? new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Column(
                  children: <Widget>[
                    new Container(
// width: 100.0,
//height: 20.0,
                      child: new Text(
                          countVal.toString(),
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 15.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                    new Container(
                        child: new Text('Count')
                    )
                  ],
                ),
                new Column(
                  children: <Widget>[
                    new Container(
//width: 100.0,
// height: 20.0,
                      child: new Text(
                          latVal.toString(),
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 15.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                    new Container(
                        child: new Text('Latitude')
                    )
                  ],
                ),
                new Column(
                  children: <Widget>[
                    new Container(
//width: 100.0,
//height: 20.0,
                      child: new Text(
                          longVal.toString(),
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 15.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                    new Container(
                        child: new Text('Longitude')
                    )
                  ],
                ),
                new Column(
                  children: <Widget>[
                    new Container(
//width: 100.0,
//height: 20.0,
                      child: new Text(
                          altVal.round().toString(),
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 15.0, fontWeight: FontWeight.bold)
                      ),
                    ),
                    new Container(
                        child: new Text(
                            widget.isMeters ? 'Altitude(m)' : 'Altitude(ft)')
                    )
                  ],
                ),
              ],
            ) : null,
          ),
          new Container(
            child: new Column(
              children: <Widget>[
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
//                    new RaisedButton(
//                        child: Text('Map'),
//                        elevation: 2.0,
//                        onPressed: () => showMap(null, null, 12.0)
//                    ),
//                    new RaisedButton(
//                        child: Text("Trails"),
//                        onPressed: () {
//                          Navigator.push(context, MaterialPageRoute(builder:
//                              (context) =>
//                              SavedTrails(trails: trails,
//                                  theme: theme,
//                                  isKph: isKph,
//                                  isMeters: isMeters,
//                                  viewTrail: null,
//                                  callback: (str, trail) =>
//                                      savedTrailsOption(str, trail))));
//                        }
//                    ),
//                    new RaisedButton(
//                        child: Text("Local Trails"),
//                        onPressed: () {
////getData("test");
//                          getData();
//
//                          Navigator.push(context, MaterialPageRoute(builder:
//                              (context) =>
//                              LocalTrails(trails: localTrails,
//                                  theme: theme,
//                                  isKph: isKph,
//                                  isMeters: isMeters,
//                                  viewTrail: null,
//                                  callback: (str, trail) =>
//                                      savedTrailsOption(str, trail))));
//                        }
//
//                    )
                  ],
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    new RaisedButton(
                        child: Text("Clear"),
                        elevation: 2.0,
                        onPressed: () => clearDashboard()),
                    new RaisedButton(
                        child: isRecording ? Text("Stop Recording") : Text(
                            "Start Recording"),
                        elevation: 2.0,
                        color: isRecording ? Colors.red : Colors.green,
                        onPressed: () => toggleRecording(false)),
                    new RaisedButton(
                        child: Text("Save"),
                        padding: const EdgeInsets.all(8.0),
                        onPressed: _showDialog
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}