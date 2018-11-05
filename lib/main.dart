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
import 'package:great_circle_distance/great_circle_distance.dart';
import 'dart:convert';
import 'Constants.dart';
import 'SettingsMenu.dart';
import 'SavedTrails.dart';
import 'Trail.dart';

import 'package:firebase_database/firebase_database.dart';
import 'Settings.dart';

///
/// Stopwatch source and inspiration
///
/// https://gist.github.com/bizz84/2cdddf0ac2b7db3df1ceb0618a317597
///

//api_key for google maps
var api_key = "AIzaSyBZodZXTiZIxcz6iBwL076yNEq_11769Fo";

var geolocator = Geolocator();

List<Polyline> polyLines = new List();
List<Polyline> loadLines = new List();

List<Trail> trails = new List();

Location onLoadLoc;

MapView mapView = new MapView();

bool isRecording = false;

//Settings
Settings settings;

//Themes
final ThemeData darkTheme = new ThemeData(
  brightness: Brightness.dark,
  cardColor: Colors.grey[700],
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

//debug
var countController = new TextEditingController();
var latController = new TextEditingController();
var longController = new TextEditingController();
var altitudeController = new TextEditingController();

//Dashboard variables
//var timeController = new TextEditingController();
//var leftDistanceController = new TextEditingController();
//var traveledDistanceController = new TextEditingController();
//var aveSpeedController = new TextEditingController();


var trailNameController = new TextEditingController();

var isDev = true;
var count = 0;
var aveCount = 1;
var aveSpeed = 0.0;
var uuid = new Uuid();
var tempSpeed = 0.0;

ThemeData theme;
bool showDebug = false;
bool isKph = false;
bool isMeters = false;


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


void main(){
  MapView.setApiKey(api_key);
  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    home: new MapPage(),
  ));
}

class MapPage extends StatefulWidget{
  _MapPageState createState() => new _MapPageState();
}

class _MapPageState extends State<MapPage> {
//  create MapView object from map_view plugin

  //MapView mapView = new MapView();


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
  var staticMapProvider = new StaticMapProvider(api_key);

  //Uri for static map, Used later to display static map
  Uri staticMapUri;


  List<Polyline> polyLine = new List();

  //save stuff
  File trailsJsonFile;
  Directory dir;
  String fileName = "Trails.json";
  bool fileExists = false;
  Map<String, dynamic> trailContent;




  sendData(dynamic temp, String uName){
    DatabaseReference database = FirebaseDatabase.instance.reference().child("Trails").child(uName);
    print("Attempting to send to database...");
    database.set(temp);
  }

  getData(String uName){
    print("Attempting to receive from database...");
    var list;
    var query = FirebaseDatabase.instance.reference();
    query.once()
        .then((DataSnapshot snapshot) {
    var key = snapshot.key;
    var temp = snapshot.value;
    var test = temp["Trails"]["points"];
    //Trail T = test;
    print(test);
    });

//    for (var i in list)
//    print(list[i]);
  }



  showMap(List<Location> list, Location location, double zoom) async {
    //this needs to be updated with gps location on start up
    //mapviewtype terrain currently, can be changed to satellite or normal
    //needs a cool title eventually
    mapView = new MapView();
    mapView.show(new MapOptions(
        mapViewType: MapViewType.normal,
        initialCameraPosition:
        new CameraPosition(Locations.centerOfUSA, 0.0),

        showUserLocation: true,
        title: "This is a title"));


    if (location == null) {
      Position pos = await geolocator.getCurrentPosition();
      location = new Location(pos.latitude, pos.longitude);
      mapView.setCameraPosition(new CameraPosition(new Location(location.latitude,location.longitude), zoom));
      buildFromJson();
    }else {
      mapView.onMapReady.listen((Null _) {
        mapView.setCameraPosition(new CameraPosition(new Location(location.latitude,location.longitude), zoom));
        loadLines.clear();
        buildSingle(list);

        print('Setting Polylines from local storage_________________________________________');

      });
    }

  }

  void buildSingle(List<Location> list){
    Polyline line = new Polyline(
        "1",
        list,
        width: 15.0,
        color: Colors.black,
        jointType: FigureJointType.round);

    loadLines.add(line);
    mapView.setPolylines(loadLines);
  }

  void toggleRecording() {

    //Get correct units
//    SettingsMenu settings = new SettingsMenu();
//
//    isMetricSpeed = settings.getIsMetricSpeed;
//    isMetricDist = settings.getIsMetricDist;

    //toggle the isRecording boolean
    setState(() => isRecording = !isRecording);

    //starts stream if isRecording is true
    if (isRecording){
      //Reset and start stopwatch
      stopWatch.reset();
      stopWatch.start();
      //start timer for stopwatch gui updates
      timer = new Timer.periodic(new Duration(milliseconds: 30), setStopWatchGui);

      getPositionStream();
    } else {

      //Stop the stopwatch
      stopWatch.stop();
      //Stop the timer
      timer.cancel();

      //cancels the stream if isRecording is false
      positionStream.cancel();

      setState(() {
        speedVal = 0.0;
        aveSpeedVal = 0.0;
      });

    }
  }

  void getPositionStream() {

    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.best, distanceFilter: 1);

    Location loc1;
    Location loc2;

    //streamSubscription to get location on update
    positionStream = geolocator.getPositionStream(
        locationOptions).listen(
            (Position position) {
          print(
              position == null ? 'Unknown' : position.latitude.toString() + ', ' +
                  position.longitude.toString());

          tempSpeed = position.speed.toDouble();
          //Unit conversions, rounding, and string building
          double speed = convertSpeed(tempSpeed);
          double altitude = convertAlt(position.altitude);

          //convert the Position object to Location object to be usable with map_view
          Location loc = new Location.full(position.latitude, position.longitude, 0,
              position.altitude, position.speed, position.heading, 0.0, 0.0);

          //Add point to polylines object
          newLine.points.add(loc);

          //calculate distance
          if (loc1 != null && loc2 != null) {

            //move to the next section of the path
            loc1 = loc2;
            loc2 = loc;

            calculateDistance(loc1, loc2);
          } else if (loc1 == null && loc2 == null) {
            loc1 = loc;
          } else if (loc1 != null && loc2 == null) {
            loc2 = loc;
            //first section of path
            calculateDistance(loc1, loc2);
          }

          count++;


          if (aveCount <= 1){
            aveSpeed = speed;
            aveCount++;
          }else if (speed > 0.25){
            aveSpeed = ((aveSpeed * ((aveCount-1).toDouble()/aveCount.toDouble()))+(speed * (1.0/aveCount.toDouble())));
            aveCount++;
          }




          setState(() {
            speedVal = speed;
            aveSpeedVal = aveSpeed;
            countVal = count;
            latVal = loc.latitude;
            longVal = loc.longitude;
            altVal = altitude;
          });


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

  //String
  double convertSpeed(var speed){
    
    if(isKph) {
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
    if(isMeters) {
      //return meters
      return altInM;

    } else {
      //Convert to feet -- 1 meter = 3.28084 feet
      double altFt = altInM * 3.28084;
      return altFt;

    }
  }

  double convertDist(var distInKm){
    if(isMeters) {
      //return Km
      return distInKm;

    } else {
      //Convert to miles -- 1 meter = 3.28084 feet
      double dist = distInKm / 1.609;
      return dist;

    }
  }

  double dist = 0.0;

  void calculateDistance(Location loc1, Location loc2) async {
    
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

    
    setState(() {
      distanceTraveledVal += distanceInKm;
    });

    dist += distanceInKm;
  }




  //this class builds the initial static map we need to figure out what
  //size we want it for the app lay out
  void initState() {
    // TODO: implement initState?
    super.initState();

    //get the users settings
    getSettings().then((result){
      setState(() {
        toggleSettings(result);
      });
      //Get saved trails
      buildFromJson();
    });
    //get th users current location
    getCurrentLocation();

    //Make Stopwatch -- stopped with zero elapsed time
    stopWatch = new Stopwatch();



  }

  //Gets the current location on load
  void getCurrentLocation() async{
    Position pos = await geolocator.getCurrentPosition();
    onLoadLoc = new Location(pos.latitude, pos.longitude);
  }

  //createJsonFile method
  //feels redundent
  void createJson(Map<String, dynamic> tInfo, Directory dir, String fileName){
    File file = new File(dir.path + "/" + fileName);
    file.createSync();
    fileExists = true;
    file.writeAsStringSync(json.encode(tInfo));
  }

  Future<Settings> getSettings() async {

    settings = new Settings(await getSpeedPref(), await getDistPref(), await getDarkPref(), await getDebugPref());

    return settings;
  }


  //saveTrail Method
  //woo time to save
  void saveTrail(String trailName, List<Polyline> lines, String time, double avgSpeed, double distance){

    String id = uuid.v1();
    String fileName = "trail-" + trailName + "-" + id;

    if(count > 1) {
      Map<String, dynamic> tInfo = lines[0].toMap();
      tInfo["time"] = time;
      tInfo["avgSpeed"] = avgSpeed;
      tInfo["distance"] = distance;
      //lines.forEach((line) => print(line.toMap()));

      //Function call to add new trail onto the database
      sendData(tInfo , fileName);
      createJson(tInfo, dir, fileName);

      this.setState(() =>
      trailContent = json.decode(trailsJsonFile.readAsStringSync()));
      print("saved: $fileName");

//      print("LOOK HERE: " + lines[0].points.toString());
//
//      List<Location> points = lines[0].points;
//
//      //Add to the saved trail list
//      generateTrails(fileName, trailName, points, lines[0], "Trail");

      //Clear the polyLines object and set fileExists back to false
      polyLines.clear();
      newLine.points.clear();
      count = 0;
      countController.text = "Update Count: " + count.toString();

      print('Clear Polylines');

      buildFromJson();

    }
  }

  //Builds a List of trail objects for the saved trails list
  void generateTrails(String id, String name, List<Location> points,
      Polyline polyline, String description, String time, double avgSpeed, double distance) {


    bool exists = false;

    //Set style for the static maps
    if (settings.isDarkTheme) {
      //Dark Theme
      List<String> style = [
        "feature:all|hue: 0xff1a00",
        "feature:all|invert_lightness:true",
        "feature:all|saturation:-100",
        "feature:all|lightness:45",
        "feature:all|gamma:0.5",
        "feature:all|element:labels.text.stroke|color:0x000000",
        "feature:all|element:labels.text.stroke|lightness:12",
        "feature:water|element:geometry|color:0x0f252e",
        "feature:water|element:geometry|lightness:17"
      ];


      trails.forEach((element) {
        if (element.id == id){
          exists = true;
        }
      });

      //if the trail doesn't exist add the trail
      if (!exists) {

        Location startPoint = points.first;
        Location endPoint = points.last;

        List<Marker> markers = createMarkers(startPoint, endPoint);

        //Due to static map url character limits a rough estimate of 300 points is the maximum
        if (points.length > 300) {
          List<Location> newPoints = shortenPointsList(points);

          //Retain first and last points
          newPoints.insert(0, startPoint);
          newPoints.add(endPoint);

          var staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(newPoints, markers,
              width: 500, height: 200, maptype: StaticMapViewType.terrain, style: style, pathColor: "green", customIcon: true);

          trails.add(new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed));
        } else {
          var staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(points, markers,
              width: 500, height: 200, maptype: StaticMapViewType.terrain, style: style, pathColor: "green", customIcon: true);

          trails.add(
              new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed));
        }
      }
    } else {
      //Light theme

      trails.forEach((element) {
        if (element.id == id){
          exists = true;
        }
      });

      //if the trail doesn't exist add the trail
      if (!exists) {

        Location startPoint = points.first;
        Location endPoint = points.last;

        List<Marker> markers = createMarkers(startPoint, endPoint);

        //Due to static map url character limits a rough estimate of 300 points is the maximum
        if (points.length > 300) {
          List<Location> newPoints = shortenPointsList(points);

          //Retain first and last points
          newPoints.insert(0, startPoint);
          newPoints.add(endPoint);

          var staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(newPoints, markers,
              width: 500, height: 200, maptype: StaticMapViewType.terrain, pathColor: "green", customIcon: true);

          trails.add(new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed));
        } else {
          var staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(points, markers,
              width: 500, height: 200, maptype: StaticMapViewType.terrain, pathColor: "green", customIcon: true);

          trails.add(
              new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed));
        }
      }
    }
  }

  //Recursive function to reduce the number of points in the list for use with the static maps
  List<Location> shortenPointsList(List<Location> points) {
    List<Location> newPoints = new List();

    for (int i = 0; i < points.length; i++) {
      if (i % 2 == 0) {
        newPoints.add(points[i]);
      }
    }

    if (newPoints.length > 300) {
      shortenPointsList(newPoints);
    }

    return newPoints;
  }

  //Set markers for the static maps
  List<Marker> createMarkers(Location start, Location end){
    List<Marker> markers = <Marker>[
      new Marker(
        "1",
        "start",
        start.latitude,
        start.longitude,
        color: Colors.green,
        markerIcon: new MarkerIcon(
          "https://goo.gl/1VVHYw",
//          width: 112.0,
//          height: 75.0,
        ),
      ),
      new Marker(
        "2",
        "end",
        end.latitude,
        end.longitude,
        color: Colors.red,
        markerIcon: new MarkerIcon(
          "https://goo.gl/g3ZkBN",
//          width:112.0,
//          height: 75.0,
        )
      )
    ];

    return markers;

  }

  void buildFromJson(){

    getApplicationDocumentsDirectory().then((Directory directory){
      dir = directory;
      //trailsJsonFile = new File(dir.path + "/" + fileName);

      List<FileSystemEntity> files = dir.listSync().toList();

      //print(files);

      files.forEach((entity) {
        if (entity is File && entity.toString().contains('trail-')){

          print('_________' + entity.toString());

          trailsJsonFile = entity;

          var id = entity.toString().split("/")[6].split("'")[0];
          var name = entity.toString().split("-")[1];


          //HEREREREERERHERERER
          //Later when we are loading more than one file this will need to be moved into the load method and trailsJsonFile will need to be the name of the file we want.
          //if (fileExists) this.setState(() => trailContent = json.decode(trailsJsonFile.readAsStringSync()));

          trailContent = json.decode(trailsJsonFile.readAsStringSync());

          if(trailContent.isNotEmpty){
            //So when you do a map of a polyline it makes the location a map
            //we need to get the map form the map to get the list
            List<Location> points = [];

            var time = trailContent["time"];
            var avgSpeed = trailContent["avgSpeed"];
            var distance = trailContent["distance"];

            //loadLines = [];
            for(var pointMap in trailContent["points"]){
              //can probs reduce to one line later
              Location temp = Location.fromMapFull(pointMap);
              points.add(temp);
            }
            Polyline line = new Polyline(trailContent["id"],
                points,
                width: 15.0,
                color: Colors.green,
                jointType: FigureJointType.round);

            loadLines.add(line);

            generateTrails(id, name, points, line, "Temp Description", time, avgSpeed, distance);

          }
        }
      });
      mapView.setPolylines(loadLines);
    });
  }

  void deleteFile(String file){

    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;

      List<FileSystemEntity> files = dir.listSync().toList();

      //print(files);

      files.forEach((entity) {
        if (entity is File && entity.toString().contains(file)) {
          entity.deleteSync();
        }
      });
    });

  }

  //gets the speed preference
  Future<bool> getSpeedPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(speedPref) ?? false;
  }

  //sets the speed preference
  Future<bool> setSpeedPref(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(speedPref, value);
  }

  //gets the distance preference
  Future<bool> getDistPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(distPref) ?? false;
  }

  //sets the distance preference
  Future<bool> setDistPref(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(distPref, value);
  }

  //gets dark theme preference
  Future<bool> getDarkPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(darkPref) ?? false;
  }

  //sets dark theme preference
  Future<bool> setDarkPref(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(darkPref, value);
  }

  //gets debug ui preference
  Future<bool> getDebugPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(debugPref) ?? false;
  }

  //sets debug ui preference
  Future<bool> setDebugPref(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(debugPref, value);
  }

  void settingsCallback(){

    //Saves the settings using shared preferences
    setSpeedPref(settings.isMetricSpeed);
    setDistPref(settings.isMetricDist);
    setDarkPref(settings.isDarkTheme);
    setDebugPref(settings.showDebug);

    //Clears the saved trails and rebuilds them
    //this ensures that the static map has the correct style
    trails.clear();
    buildFromJson();
    toggleSettings(settings);
  }

  void savedTrailsOption(String choice, Trail trail) {

    if (choice == '0'){
      int middle = (trail.points.length / 2).round();
      showMap(trail.points, trail.points[middle], 14.0);
    } else if (choice == '1') {
      deleteFile(trail.id);
    }

  }

  void toggleSettings(Settings set) {
    //Choose correct theme
    if (set.isDarkTheme) {
      setState(() {
        theme = darkTheme;
      });
    } else {
      setState(() {
        theme = lightTheme;
      });
    }

    //Set debug ui
    setState(() {
      showDebug = set.showDebug;
    });

    //Set speed unit
    setState(() {
      isKph = set.isMetricSpeed;
    });

    //Set measurement unit
    setState(() {
      isMeters = set.isMetricDist;
    });
  }


  void setStopWatchGui(Timer timer){
    if (stopWatch.isRunning) {
      setState(() {
        timeVal = stopWatch.elapsed.toString();
      });
    }
  }

  /*
  * This is the face of the app. It will determine what it looks like
  * from the app bar at the top, to each column that is placed below it
  * we need to eventually design it to look how we imagine for now lets
  * focus more on getting the maps working right
  *
  * */
  Widget build(BuildContext context){
    return MaterialApp(
      theme : theme,
      home: Scaffold(
      //appBar is the bar displayed at the top of the screen
      appBar: AppBar(
        title: Text("Bike Trail"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: choiceAction,
            itemBuilder: (BuildContext context){
              return Constants.choices.map((String choice){
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          )
        ],
      ),
      body: new Container(
       // decoration: new BoxDecoration(color: Colors.black87),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new Container(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center ,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new Container(
                    child: new Text(
                        speedVal.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: new TextStyle(fontSize: 60.0, fontWeight: FontWeight.bold)
                    ),
                  ),
                  new Container(
                    child: new Text(
                      isKph ? 'Current Speed(kph)' : 'Current Speed(mph)',
                      textAlign: TextAlign.center,
                      style: new TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
            new Row(// upper middle
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Container(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center ,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Container(
//                        width: 150.0,
//                        height: 40.0,
                        //color: Colors.blue,
                        child: new Text(
                            timeVal,
                            textAlign: TextAlign.center,
                            style: new TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold)
                        ),
                      ),
                      new Container(
                        child: new Text(
                          'Time',
                          textAlign: TextAlign.center,
                          style: new TextStyle( fontSize: 12.0, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center ,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Container(
//                        width: 150.0,
//                        height: 40.0,
                        child: new Text(
                            convertDist(distanceTraveledVal).toStringAsFixed(3),
                            textAlign: TextAlign.center,
                            style: new TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold)
                        ),
                      ),
                      new Container(
                        child: new Text(
                          isMeters ? 'Distance Traveled(km)' : 'Distance Traveled(mi)',
                          textAlign: TextAlign.center,
                          style: new TextStyle( fontSize: 12.0, fontWeight: FontWeight.bold, ),
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
                    mainAxisAlignment: MainAxisAlignment.center ,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Container(
//                        width: 150.0,
//                        height: 40.0,
                        child: new Text(
                            aveSpeedVal.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: new TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)
                        ),
                      ),
                      new Container(
                        child: new Text(
                          isKph ? 'Average Speed(kph)' : 'Average Speed(mph)',
                          textAlign: TextAlign.center,
                          style: new TextStyle( fontSize: 12.0, fontWeight: FontWeight.bold, ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center ,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Container(
//                        width: 150.0,
//                        height: 40.0,
                        child: new Text(
                            "                           "/*distanceLeftVal.toStringAsFixed(1)*/,
                            textAlign: TextAlign.center,
                            style: new TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)
                        ),
                      ),
//                      new Container(
//                        child: new Text(
//                          'Remaining Distance(mi)',
//                          textAlign: TextAlign.center,
//                          style: new TextStyle( fontSize: 12.0, fontWeight: FontWeight.bold, ),
//                        ),
//                      ),
                    ],
                  ),
                ),
              ],
            ),
            //Debug optional Widgets
            new Container(
              //height: 40.0,
              child: showDebug ? new Row(
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
                            style: new TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)
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
                            style: new TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)
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
                            style: new TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)
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
                            style: new TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)
                        ),
                      ),
                      new Container(
                          child: new Text(isMeters ? 'Altitude(m)' : 'Altitude(ft)')
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
              new RaisedButton(
                  child: Text('Map'),
                  elevation: 2.0,
                  onPressed: () => showMap(null, null,12.0)
              ),
              new RaisedButton(
                  child: Text("Trails"),
                  onPressed: () {
                    getData("test");

                    Navigator.push(context, MaterialPageRoute(builder:
                        (context) => SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, callback: (str, trail) => savedTrailsOption(str, trail))));

                  }
              )
            ],
          ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                          child: isRecording ? Text("Stop Recording") : Text("Start Recording"),
                          elevation: 2.0,
                          color: isRecording ? Colors.red : Colors.green,
                          onPressed: toggleRecording),
                      new RaisedButton(
                          child:  Text("Save"),
                          padding: const EdgeInsets.all(8.0),
                          onPressed: _showDialog
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //new RaisedButton(
            // child: new Text("LOAD TRAIL"),
            //  onPressed: () => buildFromJson(),)
          ],
        ),
      ),
    ),
    );
  }

  //Have user enter trail information
  _showDialog() async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  autofocus: true,
                  controller: trailNameController,
                  decoration: new InputDecoration(
                      labelText: 'Trail Information', hintText: 'Trail Name', contentPadding: const EdgeInsets.only(top: 16.0)),
                ),
              )
            ],
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            new FlatButton(
                child: const Text('Save'),
                onPressed: () {
                  Navigator.pop(context);
                  print(trailNameController.text);
                  saveTrail(trailNameController.text, polyLines, timeVal, aveSpeedVal, distanceTraveledVal);
                  trailNameController.text = "";
                })
          ],
        );
      },
    );
  }

  void choiceAction(String choice) {
    if (choice == Constants.Settings){
      Navigator.push(context, MaterialPageRoute(builder:
          (context) => SettingsMenu(settings: settings, darkTheme: settings.isDarkTheme, callback: () => settingsCallback())));
    }
  }

}
