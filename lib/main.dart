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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Dashboard.dart';
import 'placeholder_widget.dart';

import 'package:firebase_database/firebase_database.dart';
import 'Settings.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';








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
List<Marker> loadMarkers = new List();

List<Widget> _children = [
      PlaceholderWidget(Colors.black),
      PlaceholderWidget(Colors.black),
      PlaceholderWidget(Colors.black),
      PlaceholderWidget(Colors.black)
    ];

//phone saved
List<Trail> trails = new List();
//db saved
List<Trail> localTrails = new List();

Location onLoadLoc;

MapView mapView = new MapView();

bool isRecording = false;

//Settings
Settings settings;

//Themes
final ThemeData darkTheme = new ThemeData(
  brightness: Brightness.dark,
  primaryTextTheme: new TextTheme(caption: new TextStyle(color: Colors.white)),
  buttonColor: Colors.grey,
  splashColor: Colors.teal,
  hintColor: Colors.grey,
  disabledColor: Colors.grey[700]
);
final ThemeData lightTheme = new ThemeData(
  brightness: Brightness.light,
  hintColor: Colors.grey,
  disabledColor: Colors.grey[200]
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
var _currentIndex = 0;

ThemeData theme;
bool showDebug = false;
bool isKph = false;
bool isMeters = false;

//authenticate stuff following steps in api
final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;
String uID = "";

List<String> constants = new List();


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
  Screen.keepOn(true);


  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {


  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    home: new MapPage(),
  ));

});

}

class MapPage extends StatefulWidget{
  _MapPageState createState() => new _MapPageState();
}

class _MapPageState extends State<MapPage> {
//  create MapView object from map_view plugin

  //MapView mapView = new MapView();

  //Colors used for icons and indicating a non usable icon
  Color iconColor;
  Color disabledIconColor;

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

  final String signInPref = "signInPref";
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

  double dist = 0.0;
  FirebaseUser fbUser;
  Future<FirebaseUser> _handleSignIn() async {

    try {
      GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print("access token" + googleAuth.accessToken);
      print("idToken " + googleAuth.idToken);
      FirebaseUser user = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print("signed in " + user.displayName);
      uID = user.uid;
      loginSync(uID);
      return user;
    } catch (e){
      print(e);
      return null;
    }
  }

  Future _silentSignIn() async {

    try {
      GoogleSignInAccount googleUser = await _googleSignIn.signInSilently();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      FirebaseUser user = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print("signed in on app launch " + user.displayName);
      uID = user.uid;
      loginSync(uID);
      fbUser = user;
    } catch (e){
      print(e);
    }
  }

  bool isRiding = false;
  Trail ridingTrail;



  //@sam
  Future _handleSignOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  sendData(dynamic temp, String trailID){
    DatabaseReference database = FirebaseDatabase.instance.reference().child("Trails").child("Public").child(trailID);
    print("Attempting to send to database...");
    database.set(temp);
  }


  //@Sam this method is to save ther user
  sendDataUser(dynamic temp,String trailID){
    DatabaseReference database = FirebaseDatabase.instance.reference().child("Trails").child(uID).child(trailID);
    print("Attempting to send to database...");
    database.set(temp);
  }

  getData(){
    var ref =  FirebaseDatabase.instance.reference().child("Trails").child("Public");
    ref.onChildAdded.listen((event) {
      handler(event);
    });
  }

  //@sam this is to load user data
  getDataUser(String uName){
    var ref =  FirebaseDatabase.instance.reference().child("Trails").child(uName);
    ref.onChildAdded.listen((event) {
      userHandler(event);
    });
  }

  //@patton
  Future loginSync(String uName) async{
    print("uname " + uName);
    List<String> dbTrails = [];
    var ref =  FirebaseDatabase.instance.reference().child("Trails").child(uName);
    //first get trails from the db
    ref.onChildAdded.listen((event) {
      dbTrails.add(event.snapshot.value["fileName"]);
      var found = false;
      //check if they exist locally
      for(var trail in trails){
        if(event.snapshot.value["fileName"] == trail.id){
          found = true;
        }
      }
      //if they dont then add them
      if(!found){
        userHandler(event);
        print("saved");
      }
      });

    trails.forEach((trail){
      Map<String, dynamic> tInfo = trail.polyline.toMap();
      tInfo["avgSpeed"] = trail.avgSpeed;
      tInfo["distance"] = trail.length;
      tInfo["name"] = trail.name;
      tInfo["time"] = trail.time;
      tInfo["fileName"] = trail.id;
      sendDataUser(tInfo, trail.id);
    });
  }


  //@sam @braedin
  //this needs to be added where they delete their trails so it removes it from db also
  deleteDataUser(String uName, String trailID){
    FirebaseDatabase.instance.reference().child("Trails").child(uName).child(trailID).remove();
  }

  handler(event){
    var data = new Map<String, dynamic>.from(event.snapshot.value);
    var jointType, color, width, id, points, name, fileName, avgSpeed,time,distance;

    jointType = data["jointType"];
    color = data["color"];
    width = data["width"];
    id = data["id"];
    points = data["points"];
    name = data["name"];
    fileName = data["fileName"];
    avgSpeed = data["avgSpeed"];
    time = data["time"];
    distance = data["distance"];
    Polyline line = buildFromdb(jointType, color, width, id, points);

    /////////////////////////////////////////////////////////////////////////////////

    Polyline lineTemp = new Polyline(fileName,
        line.points,
        width: 15.0,
        color: Colors.green,
        jointType: FigureJointType.round);

    loadLines.add(lineTemp);


    String titleString = isMeters ? "$name | " + convertDist(distance).toStringAsFixed(2) + " km" : "$name | " + convertDist(distance).toStringAsFixed(2) + " mi";


    Marker marker = new Marker(
      fileName,
      titleString,
      line.points[0].latitude,
      line.points[0].longitude,
      color: Colors.green,
      markerIcon: new MarkerIcon(
        "lib/assets/bike-icon.png",
        height: 75.0,
        width: 75.0,
      ),
    );

    loadMarkers.add(marker);


    generateTrails(fileName, name, line.points,
        line, "this is a test", time, avgSpeed.toDouble(), distance.toDouble(), false);
  }

  //we can trim down the code in these eventually
  userHandler(event){
    var data = new Map<String, dynamic>.from(event.snapshot.value);
    var jointType, color, width, id, points, name, fileName, avgSpeed,time,distance;

    jointType = data["jointType"];
    color = data["color"];
    width = data["width"];
    id = data["id"];
    points = data["points"];
    name = data["name"];
    fileName = data["fileName"];
    avgSpeed = data["avgSpeed"];
    time = data["time"];
    distance = data["distance"];
    Polyline line = buildFromdb(jointType, color, width, id, points);
    //this line will need to be changed so they know its coming from the users db
    //not the public one
    generateTrails(fileName, name, line.points,
        line, "this is a test", time, avgSpeed.toDouble(), distance, true);
  }

  Polyline buildFromdb(jointType, color, width, id, points){
    var attempt = new List.from(points);
    List<Location> pointslist = [];
    for(var pointMap in attempt){
      //Location temp = new Location.fromMap(pointMap);
      Location temp = new Location.full(pointMap["latitude"], pointMap["longitude"], pointMap["time"],
          pointMap["altitude"].toDouble(), pointMap["speed"].toDouble(), pointMap["heading"], 0.0, 0.0);
      pointslist.add(temp);
    }
    var a = color["a"];
    var r = color["r"];
    var b = color["b"];
    var g = color["g"];
    Polyline line = new Polyline(
        id,
        pointslist,
        width: width.toDouble(),
        color: Color.fromARGB(a, r, g, b),
        jointType: FigureJointType.round);
    return line;
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
        title: "Bike Trail"));


    if (location == null) {
      Position pos = await geolocator.getCurrentPosition();
      location = new Location(pos.latitude, pos.longitude);
      mapView.setCameraPosition(new CameraPosition(new Location(location.latitude,location.longitude), zoom));
      buildFromJson();

    }else {
      mapView.onMapReady.listen((Null _) {
        mapView.setCameraPosition(new CameraPosition(new Location(location.latitude,location.longitude), zoom));
        loadLines.clear();
        loadMarkers.clear();
        buildSingle(list);
        print('Setting Polylines from local storage_________________________________________');
      });
    }

    //Follow user if recording or riding
    mapView.onLocationUpdated.listen((location) {
      if (isRiding || isRecording) {
        mapView.setCameraPosition(new CameraPosition(new Location(location.latitude,location.longitude), 18.0));
      }
    });

    //Listener for marker taps
    mapView.onTouchAnnotation.listen((annotation) {

        for (var line in loadLines) {
          if (line.id == annotation.id) {
            mapView.addPolyline(line);
          }
        }
    });

    //Listener for infoWindow taps
    mapView.onInfoWindowTapped.listen((marker) {

      mapView.dismiss();

      //Navigate to saved trails list or local trails list at certain trail

      for (var trail in localTrails) {
        if (marker.id == trail.id){
          setState(() {
            _onItemTapped(2, trailID: marker.id);
          });
        }
      }

      for(var trail in trails) {
        if (marker.id == trail.id){
          setState(() {
            _onItemTapped(3, trailID: marker.id);
          });
        }
      }

//      Navigator.push(context, MaterialPageRoute(builder:
//          (context) => SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: marker.id, callback: (str, trail) => savedTrailsOption(str, trail))));
    });

    //Listener for polyline taps
    mapView.onTouchPolyline.listen((polyline) {

      mapView.removePolyline(polyline);

    });
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

//  void toggleRecording() {
//
//    //Get correct units
////    SettingsMenu settings = new SettingsMenu();
////
////    isMetricSpeed = settings.getIsMetricSpeed;
////    isMetricDist = settings.getIsMetricDist;
//
//    //toggle the isRecording boolean
//    setState(() => isRecording = !isRecording);
//
//    //starts stream if isRecording is true
//    if (isRecording){
//      //Reset and start stopwatch
//      stopWatch.reset();
//      stopWatch.start();
//      //start timer for stopwatch gui updates
//      timer = new Timer.periodic(new Duration(milliseconds: 30), setStopWatchGui);
//
//      getPositionStream();
//
//
//    } else {
//
//      //Stop the stopwatch
//      stopWatch.stop();
//      //Stop the timer
//      timer.cancel();
//
//      //cancels the stream if isRecording is false
//      positionStream.cancel();
//
//      setState(() {
//        speedVal = 0.0;
//        //aveSpeedVal = 0.0;
//      });
//
//    }
//  }

//  void getPositionStream() {
//
//    var locationOptions = LocationOptions(
//        accuracy: LocationAccuracy.best, distanceFilter: 1);
//
//    Location loc1;
//    Location loc2;
//
//    //streamSubscription to get location on update
//    positionStream = geolocator.getPositionStream(
//        locationOptions).listen(
//            (Position position) {
//          print(
//              position == null ? 'Unknown' : position.latitude.toString() + ', ' +
//                  position.longitude.toString());
//
//          tempSpeed = position.speed.toDouble();
//          //Unit conversions, rounding, and string building
//          double speed = tempSpeed;
//          double altitude = convertAlt(position.altitude);
//
//          //convert the Position object to Location object to be usable with map_view
//          Location loc = new Location.full(position.latitude, position.longitude, stopWatch.elapsed.inSeconds,
//              position.altitude, position.speed, position.heading, 0.0, 0.0);
//
//          //Add point to polylines object
//          newLine.points.add(loc);
//
//          //calculate distance
//          if (loc1 != null && loc2 != null) {
//
//            //move to the next section of the path
//            loc1 = loc2;
//            loc2 = loc;
//
//            calculateDistance(loc1, loc2);
//          } else if (loc1 == null && loc2 == null) {
//            loc1 = loc;
//          } else if (loc1 != null && loc2 == null) {
//            loc2 = loc;
//            //first section of path
//            calculateDistance(loc1, loc2);
//          }
//
//          count++;
//
//
//          if (aveCount <= 1){
//            aveSpeed = speed;
//            aveCount++;
//          }else if (speed > 0.25){
//            aveSpeed = ((aveSpeed * ((aveCount-1).toDouble()/aveCount.toDouble()))+(speed * (1.0/aveCount.toDouble())));
//            aveCount++;
//          }
//
//
//
//
//          setState(() {
//            speedVal = convertSpeed(speed);
//            aveSpeedVal = convertSpeed(aveSpeed);
//            countVal = count;
//            latVal = loc.latitude;
//            longVal = loc.longitude;
//            altVal = altitude;
//          });
//
//          print("BEFORE________________________________________$isRiding");
//          if (!isRiding) {
//            print("AFTER___________________________________________");
//            //Clear the list of polylines before adding the new version
//            polyLines.clear();
//
//            //Add newLine to List of polylines
//            polyLines.add(newLine);
//
//            mapView.clearPolylines();
//
//            //Update lines on map
//            mapView.setPolylines(polyLines);
//            //mapView.setPolylines(loadLines);
//          }
//
//        });
//
//
//
//  }

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

  void rideTrail(Trail trail) async{

    isRiding = true;
    ridingTrail = trail;
    isRecording = true;


    _children = [
      Dashboard(theme: theme, isKph: isKph, isMeters: isMeters, isDebug: showDebug, rideTrail: trail, callback: (trailName, lines, time, avgSpeed, distance, isPublic) => saveCallback(trailName, lines, time, avgSpeed, distance, isPublic)),
      null,
      LocalTrails(trails: localTrails, savedTrails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> localTrailCallback(str, trail)),
      SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail))
    ];

    setState(() {
      _currentIndex = 0;
    });

  }

  void updateWidget() {
    _children = [
      Dashboard(theme: theme, isKph: isKph, isMeters: isMeters, isDebug: showDebug, callback: (trailName, lines, time, avgSpeed, distance, isPublic) => saveCallback(trailName, lines, time, avgSpeed, distance, isPublic)),
      null,
      LocalTrails(trails: localTrails, savedTrails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> localTrailCallback(str, trail)),
      SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail))
    ];
  }


  //this class builds the initial static map we need to figure out what
  //size we want it for the app lay out
  void initState() {
    // TODO: implement initState?
      super.initState();

      //_googleSignIn.signOut();

      _silentSignIn();

      //get the users settings, do init stuff that depends on settings
      getSettings().then((result){
        setState(() {
          toggleSettings(result);
        });
        //Get saved trails
        buildFromJson();

        iconColor = theme.hintColor;
        disabledIconColor = theme.disabledColor;

        _children = [
          Dashboard(theme: theme, isKph: isKph, isMeters: isMeters, isDebug: showDebug, callback: (trailName, lines, time, avgSpeed, distance, isPublic) => saveCallback(trailName, lines, time, avgSpeed, distance, isPublic)),
          null,
          LocalTrails(trails: localTrails, savedTrails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> localTrailCallback(str, trail)),
          SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail))
        ];


        //Handle whether a user is signed in or not
        print("Constants_______ " + constants.toString());


      });
      //get th users current location
      getCurrentLocation();

      getData();
      //Make Stopwatch -- stopped with zero elapsed time
      stopWatch = new Stopwatch();

      //_children = new List();
//      _children.add(LocalTrails(trails: localTrails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail)));
//      _children.add(SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail)));
//    _children = [
//      PlaceholderWidget(Colors.white),
//      PlaceholderWidget(Colors.deepOrange),
//      PlaceholderWidget(Colors.green)
//    ];


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

    settings = new Settings(await getSignInPref(), await getSpeedPref(), await getDistPref(), await getDarkPref(), await getDebugPref());

    return settings;
  }

  Duration convertToDuration(String val) {

    List<String> temp = val.split(new RegExp("([:.])"));

    Duration d = new Duration(
        hours: int.parse(temp[0]),
        minutes: int.parse(temp[1]),
        seconds: int.parse(temp[2]),
        milliseconds: int.parse(temp[3])
    );

    return d;

  }


  //saveTrail Method
  //woo time to save
  void saveTrail(String trailName, List<Polyline> lines, String time, double avgSpeed, double distance, bool isPublic, bool isUpdate, {String file}){

    String fileName;

    if (file == null) {
      String id = uuid.v1();
      fileName = "trail-" + trailName + "-" + id;
    } else {
      fileName = file;
    }


    if(lines[0].points.length > 1) {

      if (isUpdate){
        Map<String, dynamic> tInfo = lines[0].toMap();

        //get the trail to compare to
        for (var trail in trails) {
          if (trail.id == file) {

            if(convertToDuration(time) < convertToDuration(trail.time)) {
              tInfo["time"] = time;
            } else {
              tInfo["time"] = trail.time;
            }

            tInfo["avgSpeed"] = (avgSpeed + trail.avgSpeed) / 2;
            tInfo["distance"] = trail.length;

            break;
          }
        }

        createJson(tInfo, dir, fileName);
        tInfo["name"] = trailName;
        tInfo["fileName"] = fileName;

        //Send to database only if make public was checked.
//        if (isPublic) {
//          sendData(tInfo, fileName);
//        }

        this.setState(() =>
        trailContent = json.decode(trailsJsonFile.readAsStringSync()));
        print("saved: $fileName");

        //remove trail form trail list so it gets rebuilt
        for (var trail in trails) {
          if (trail.id == file) {
            trails.remove(trail);
            break;
          }
        }


      } else {
        Map<String, dynamic> tInfo = lines[0].toMap();
        tInfo["time"] = time;
        tInfo["avgSpeed"] = avgSpeed;
        tInfo["distance"] = distance;
        //lines.forEach((line) => print(line.toMap()));

        //Function call to add new trail onto the database


        print("Filename $fileName");
        createJson(tInfo, dir, fileName);
        tInfo["name"] = trailName;
        tInfo["fileName"] = fileName;

        //Send to database only if make public was checked.
        if (isPublic) {
          sendData(tInfo, fileName);
        }



//        this.setState(() =>
//        trailContent = json.decode(trailsJsonFile.readAsStringSync()));
        print("saved: $fileName");
        //only try to back up if logged in
        if(fbUser != null) {
          sendDataUser(tInfo, fileName);
        }
      }


      //Clear the polyLines object and set fileExists back to false
      polyLines.clear();
      newLine.points.clear();
      count = 0;
      countController.text = "Update Count: " + count.toString();

      print('Clear Polylines');

      setState(() {
        speedVal = 0.0;
        timeVal = "00:00:00:00";
        distanceTraveledVal = 0.000;
        aveSpeedVal = 0.0;
        altVal = 0.0;
        countVal = 0;
        latVal = 0.0;
        longVal = 0.0;
      });

      buildFromJson();

    }
  }


  //Builds a List of trail objects for the saved trails list
  void generateTrails(String id, String name, List<Location> points,
      Polyline polyline, String description, String time, double avgSpeed, double distance, bool fromSaved) {

    Trail newTrail;

    bool existsLocal = false;
    bool existsSaved = false;


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
          existsSaved = true;
        }
      });
      localTrails.forEach((element) {
        if (element.id == id) {
          existsLocal = true;
        }
      });

      //if the trail doesn't exist add the trail
      if ((fromSaved && !existsSaved) || !fromSaved) {

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


          newTrail = new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed);
        } else {
          var staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(points, markers,
              width: 500, height: 200, maptype: StaticMapViewType.terrain, style: style, pathColor: "green", customIcon: true);

          newTrail = new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed);
        }

        if (!fromSaved) {
          //put into db list
          localTrails.add(newTrail);
        } else {
          //put into saved trails list
          trails.add(newTrail);
        }
      }
    } else {
      //Light theme

      trails.forEach((element) {
        if (element.id == id){
          existsSaved = true;
        }
      });
      localTrails.forEach((element) {
        if (element.id == id) {
          existsLocal = true;
        }
      });

      //if the trail doesn't exist add the trail
      if ((fromSaved && !existsSaved) || !fromSaved) {

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

          newTrail = new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed);
        } else {
          var staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(points, markers,
              width: 500, height: 200, maptype: StaticMapViewType.terrain, pathColor: "green", customIcon: true);

          newTrail = new Trail(id, name, points, markers[0], markers[1], polyline, staticMapUri, description, time, distance, avgSpeed);
        }

        if (!fromSaved) {
          //put into db list
          localTrails.add(newTrail);
        } else {
          //put into saved trails list
          trails.add(newTrail);
        }
      }
    }

    sortTrails();
    sortLocalTrails();

//    print("Trails: " + trails.length.toString());
//    print("Local Trails: " + localTrails.length.toString());

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
      return shortenPointsList(newPoints);
    } else {
//      print("________" + newPoints.length.toString() + "____________" );

      return newPoints;
    }

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
          "http://oi66.tinypic.com/fay1yr.jpg",
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
            double distance = trailContent["distance"];

            //loadLines = [];
            for(var pointMap in trailContent["points"]){
              //can probs reduce to one line later
              Location temp = Location.fromMapFull(pointMap);
              points.add(temp);
            }
            Polyline line = new Polyline(id,
                points,
                width: 15.0,
                color: Colors.green,
                jointType: FigureJointType.round);

            loadLines.add(line);

            //Make marker for polyline

            String titleString = isMeters ? "$name | " + convertDist(distance).toStringAsFixed(2) + " km" : "$name | " + convertDist(distance).toStringAsFixed(2) + " mi";

            Marker marker = new Marker(
              id,
              titleString,
              points[0].latitude,
              points[0].longitude,
              color: Colors.green,
              markerIcon: new MarkerIcon(
                "lib/assets/bike-icon.png",
                height: 75.0,
                width: 75.0,
              ),
            );

            loadMarkers.add(marker);

            generateTrails(id, name, points, line, "Temp Description", time, avgSpeed, distance, true);


          }
        }
      });
      //mapView.setPolylines(loadLines);
      mapView.setMarkers(loadMarkers);

    });
  }

  void addToSavedList(Trail trail) {

    List<Polyline> lines = [trail.polyline];
    saveTrail(trail.name, lines, trail.time, trail.avgSpeed, trail.length, false, false, file: trail.id);
    updateWidget();
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

    if (uID != null) {
      //delete trail from db
      deleteDataUser(uID, file);
    }

  }

  Future<String> getSignInPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(signInPref) ?? null;
  }

  Future<bool> setSignInPref(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(signInPref, value);
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

  void settingsCallback() async {

    //Saves the settings using shared preferences
    setSignInPref(settings.signInValue);
    setSpeedPref(settings.isMetricSpeed);
    setDistPref(settings.isMetricDist);
    setDarkPref(settings.isDarkTheme);
    setDebugPref(settings.showDebug);

    //Clears the saved trails and rebuilds them
    //this ensures that the static map has the correct style
//    trails.clear();
//    localTrails.clear();
//    loadMarkers.clear();
    //buildFromJson();

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

    for (var trail in trails) {

      Location startPoint = trail.points.first;
      Location endPoint = trail.points.last;

      List<Marker> markers = createMarkers(startPoint, endPoint);

      List<Location> newPoints = shortenPointsList(trail.points);

      //Retain first and last points
      newPoints.insert(0, startPoint);
      newPoints.add(endPoint);

      if (settings.isDarkTheme) {
        trail.uri = staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(newPoints, markers,
            width: 500, height: 200, maptype: StaticMapViewType.terrain, style: style, pathColor: "green", customIcon: true);
      } else {
        trail.uri = staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(newPoints, markers,
            width: 500, height: 200, maptype: StaticMapViewType.terrain, pathColor: "green", customIcon: true);
      }
    }

    for (var trail in localTrails) {

      Location startPoint = trail.points.first;
      Location endPoint = trail.points.last;

      List<Marker> markers = createMarkers(startPoint, endPoint);

      List<Location> newPoints = shortenPointsList(trail.points);

      //Retain first and last points
      newPoints.insert(0, startPoint);
      newPoints.add(endPoint);

      if (settings.isDarkTheme) {
        trail.uri = staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(newPoints, markers,
            width: 500, height: 200, maptype: StaticMapViewType.terrain, style: style, pathColor: "green", customIcon: true);
      } else {
        trail.uri = staticMapUri = staticMapProvider.getStaticUriWithPathAndMarkers(newPoints, markers,
            width: 500, height: 200, maptype: StaticMapViewType.terrain, pathColor: "green", customIcon: true);
      }
    }

//    getData();
    toggleSettings(settings);
  }

  void savedTrailsOption(String choice, Trail trail) {

    if (choice == '0'){
      int middle = (trail.points.length / 2).round();
      showMap(trail.points, trail.points[middle], 14.0);
    } else if (choice == '1') {
      deleteFile(trail.id);

      //remove from the list
      Trail temp;
      for (var t in trails) {
        if (trail.id == t.id) {
          temp = t;
          break;
        }
      }
      trails.remove(temp);
    } else if (choice == '2') {
      rideTrail(trail);
    }

  }

  void localTrailCallback(String choice, Trail trail) {
    if (choice == '0'){
      int middle = (trail.points.length / 2).round();
      showMap(trail.points, trail.points[middle], 14.0);
    } else if (choice == '1') {
      addToSavedList(trail);
    } else if (choice == '2') {
      deleteFile(trail.id);

      //remove from the list
      Trail temp;
      for (var t in trails) {
        if (trail.id == t.id) {
          temp = t;
          break;
        }
      }
      trails.remove(temp);
    }
  }

  void saveCallback(String trailName, List<Polyline> lines, String time, double avgSpeed, double distance, bool isPublic) {

    if(isPublic != null) {
      saveTrail(trailName, lines, time, avgSpeed, distance, isPublic, false);
      isRecording = false;
    } else if (isPublic == null && trailName != null){
      saveTrail(trailName, lines, time, avgSpeed, distance, isPublic, true, file: trailName);
      isRiding = false;
    } else if (time == "-1") {
      //Callback for clear
      isRecording = false;
      isRiding = false;
      setState(() {});

    }else if (time == "rec" && !isRiding){
      //Callback to control state of bottom navigation bar
//      isRecording = true;

      setState(() {
        isRecording = true;
      });
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

    List<String> constantsTemp = new List();

    //change ellipses menu options
    if(settings.signInValue != null) {
      constantsTemp.add(Constants.Settings);
      constantsTemp.add(Constants.SignOut);
    } else {
      constantsTemp.add(Constants.Settings);
      constantsTemp.add(Constants.SignIn);
    }

    //set new constants
    setState(() {
      constants = constantsTemp;
      updateWidget();
    });
  }


  void setStopWatchGui(Timer timer){
    if (stopWatch.isRunning) {
      setState(() {
        timeVal = stopWatch.elapsed.toString().substring(0, 10);
      });
    }
  }

  void sortTrails() {
    trails.sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  void sortLocalTrails() {
    localTrails.sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
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
              return constants.map((String choice){
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          )
        ],
      ),
      body:_children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          fixedColor: Colors.black,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: new Icon(Icons.directions_bike, color: iconColor),
                title: new Text(""),
                activeIcon: new Icon(Icons.directions_bike, color: Colors.black)
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.map, color: iconColor),
              title: new Text(""),
                activeIcon: new Icon(Icons.map, color: Colors.black)
            ),
            BottomNavigationBarItem(
                icon: new Icon(Icons.public, color: isRecording ? disabledIconColor : iconColor),
                title: new Text(""),
                activeIcon: new Icon(Icons.public, color: Colors.black)
            ),
            BottomNavigationBarItem(
                icon: new Icon(Icons.favorite, color: isRecording ? disabledIconColor : iconColor),
                title: new Text(""),
                activeIcon: new Icon(Icons.favorite, color: Colors.black)
            )
            ],
          onTap: _onItemTapped,
        ),
    ),
    );
  }

  void _onItemTapped(int index, {String trailID}) {

    if(trailID == null) {

      if(isRiding){
        _children = [
          Dashboard(theme: theme, isKph: isKph, isMeters: isMeters, isDebug: showDebug, rideTrail: ridingTrail, callback: (trailName, lines, time, avgSpeed, distance, isPublic) => saveCallback(trailName, lines, time, avgSpeed, distance, isPublic)),
          null,
          LocalTrails(trails: localTrails, savedTrails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> localTrailCallback(str, trail)),
          SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail))
        ];
      } else {
        _children = [
          Dashboard(theme: theme, isKph: isKph, isMeters: isMeters, isDebug: showDebug, callback: (trailName, lines, time, avgSpeed, distance, isPublic) => saveCallback(trailName, lines, time, avgSpeed, distance, isPublic)),
          null,
          LocalTrails(trails: localTrails, savedTrails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> localTrailCallback(str, trail)),
          SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail))
        ];
      }

      setState(() {
        if (index == 1 && !isRiding) {
          showMap(null, null, 12.0);
          _currentIndex = 0;
        } else if (index == 1 && isRiding) {
          showMap(ridingTrail.points, ridingTrail.points[0], 14.0);
          _currentIndex = 0;
        } else if (!isRecording){
          _currentIndex = index;
        }
      });
    } else {

      if(isRiding) {
        _children = [
          Dashboard(theme: theme, isKph: isKph, isMeters: isMeters, isDebug: showDebug, rideTrail: ridingTrail, callback: (trailName, lines, time, avgSpeed, distance, isPublic) => saveCallback(trailName, lines, time, avgSpeed, distance, isPublic)),
          null,
          LocalTrails(trails: localTrails, savedTrails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> localTrailCallback(str, trail)),
          SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail)=> savedTrailsOption(str, trail))
        ];
      } else {
        _children = [
          Dashboard(theme: theme, isKph: isKph, isMeters: isMeters, isDebug: showDebug, callback: (trailName, lines, time, avgSpeed, distance, isPublic) => saveCallback(trailName, lines, time, avgSpeed, distance, isPublic)),
          null,
          LocalTrails(trails: localTrails, savedTrails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: trailID, callback: (str, trail)=> localTrailCallback(str, trail)),
          SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: trailID, callback: (str, trail)=> savedTrailsOption(str, trail))
        ];
      }

      setState(() {
        if (index == 1 && !isRiding) {
          showMap(null, null, 12.0);
          _currentIndex = 0;
        } else if (index == 1 && isRiding) {
          showMap(ridingTrail.points, ridingTrail.points[0], 14.0);
          _currentIndex = 0;
        } else if (!isRecording) {
          _currentIndex = index;
        }
      });
    }


  }

  void choiceAction(String choice) async {
    if (choice == Constants.Settings){
      Navigator.push(context, MaterialPageRoute(builder:
          (context) => SettingsMenu(settings: settings, darkTheme: settings.isDarkTheme, callback: () => settingsCallback())));
    } else if (choice == Constants.SignIn) {
      FirebaseUser user = await _handleSignIn();
      if (user != null) {
        setSignInPref(user.displayName);
        settings.signInValue = user.displayName;
        toggleSettings(settings);
        fbUser = user;
      } else {
        print ("sign in failed");
      }
    } else if (choice == Constants.SignOut) {
      setSignInPref(null);
      settings.signInValue = null;
      toggleSettings(settings);
      _handleSignOut();

    }
  }

}

