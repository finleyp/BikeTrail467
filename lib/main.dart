import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:map_view/polyline.dart';
import 'package:map_view/figure_joint_type.dart';
import 'package:map_view/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'Constants.dart';
import 'SettingsMenu.dart';
import 'SavedTrails.dart';
import 'Trail.dart';


//api_key for google maps
var api_key = "AIzaSyBZodZXTiZIxcz6iBwL076yNEq_11769Fo";

var geolocator = Geolocator();

List<Polyline> polyLines = new List();
List<Polyline> loadLines = new List();

List<Trail> trails = new List();

Location onLoadLoc;

MapView mapView = new MapView();

bool isRecording = false;
bool isMetricSpeed = false;
bool isMetricDist = false;

StreamSubscription<Position> positionStream;

//debug
var countController = new TextEditingController();
var latController = new TextEditingController();
var longController = new TextEditingController();
var altitudeController = new TextEditingController();



var speedController = new TextEditingController();
var timeController = new TextEditingController();
var leftDistanceController = new TextEditingController();
var traveledDistanceController = new TextEditingController();
var aveSpeedController = new TextEditingController();

var trailNameController = new TextEditingController();


var count = 0;
var uuid = new Uuid();




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

  showMap(Location location, double zoom) async {
    //this needs to be updated with gps location on start up
    //mapviewtype terrain currently, can be changed to satellite or normal
    //needs a cool title eventually

    mapView.show(new MapOptions(
        mapViewType: MapViewType.normal,
        initialCameraPosition:
        new CameraPosition(Locations.centerOfUSA, 0.0),

        showUserLocation: true,
        title: "This is a title"));


    if (location == null) {
      Position pos = await geolocator.getCurrentPosition();
      location = new Location(pos.latitude, pos.longitude);
    }



    //mapView.zoomToFit(padding: 50);

    //Show polylines on map load
    mapView.onMapReady.listen((_) {
      mapView.setCameraPosition(new CameraPosition(new Location(location.latitude,location.longitude), zoom));
      loadLines.clear();
      buildFromJson();

      print('Setting Polylines from local storage_________________________________________');

    });

  }


  void toggleRecording() {

    //Get correct units
    SettingsMenu settings = new SettingsMenu();

    isMetricSpeed = settings.isMetricSpeed;
    isMetricDist = settings.isMeticDist;

    //toggle the isRecording boolean
    setState(() => isRecording = !isRecording);

    //starts stream if isRecording is true
    if (isRecording){
      getPositionStream();
    } else {

      //cancels the stream if isRecording is false
      positionStream.cancel();
    }
  }

  void getPositionStream() {

    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.best, distanceFilter: 1);

    //streamSubscription to get location on update
    positionStream = geolocator.getPositionStream(
        locationOptions).listen(
            (Position position) {
          print(
              position == null ? 'Unknown' : position.latitude.toString() + ', ' +
                  position.longitude.toString());

          //Unit conversions, rounding, and string building
          String speed = convertSpeed(position.speed);
          String altitude = convertAlt(position.altitude);

          //convert the Position object to Location object to be usable with map_view
          Location loc = new Location.full(position.latitude, position.longitude, 0,
                          position.altitude, position.speed, position.heading, 0.0, 0.0);

          //Add point to polylines object
          newLine.points.add(loc);


          count++;

          countController.text = "Update Count: " + count.toString();
          latController.text = "Latitude: " + loc.latitude.toString();
          //position.latitude.toString();
          longController.text = "Longitude: " + loc.longitude.toString();
          speedController.text = "Speed: $speed";
          altitudeController.text = "Altitude: $altitude";




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

  String convertSpeed(var speed){

    if(isMetricSpeed) {
      //Convert from Mps to Kph -- 1 mps = 3.6 kph
      double speedKph = speed * 3.6;
      return speedKph.toStringAsFixed(1) + " kph";

    } else {
      //Convert to Mph -- 1 mps = 2.236934 mph
      double speedMph = speed * 2.236934;
      return speedMph.toStringAsFixed(1) + " mph";

    }
  }

  String convertAlt(var alt){
    if(isMetricDist) {
      //return modified string
      return alt.toStringAsFixed(0) + " meters";

    } else {
      //Convert to feet -- 1 meter = 3.28084 feet
      double altFt = alt * 3.28084;
      return altFt.toStringAsFixed(0) + " feet";

    }
  }



    
  //this class builds the initial static map we need to figure out what
  //size we want it for the app lay out
  void initState() {
    // TODO: implement initState?
    super.initState();
    //we need to update cameraPosition with user position
    cameraPosition = new CameraPosition(new Location(42.9634, -85.6681), 30.0);
    //set static map to user position
    //height and width should change size of map, currently having issues with them
    staticMapUri = staticMapProvider.getStaticUri(
        new Location(42.9634, -85.6681), 12,
        height: 400, width: 900, mapType: StaticMapViewType.terrain);
    getApplicationDocumentsDirectory().then((Directory directory){
      dir = directory;
      //trailsJsonFile = new File(dir.path + "/" + fileName);
      //fileExists = trailsJsonFile.existsSync();
      //HEREREREERERHERERER
      //Later when we are loading more than one file this will need to be moved into the load method and trailsJsonFile will need to be the name of the file we want.
//      if (fileExists) this.setState(() => trailContent = json.decode(trailsJsonFile.readAsStringSync()));
    });

    getCurrentLocation();

    //Get saved trails on open
    buildFromJson();
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

  //saveTrail Method
  //woo time to save
  void saveTrail(String trailName, List<Polyline> lines){

    String id = uuid.v1();
    String fileName = "trail-" + trailName + "-" + id;

    if(count > 1) {
      Map<String, dynamic> tInfo = lines[0].toMap();
      //lines.forEach((line) => print(line.toMap()));

      createJson(tInfo, dir, fileName);

      this.setState(() =>
      trailContent = json.decode(trailsJsonFile.readAsStringSync()));
      print("saved: $fileName");
      print(trailContent);

      //Clear the polyLines object and set fileExists back to false
      polyLines.clear();
      newLine.points.clear();

      print('Clear Polylines');

    }
  }

  void generateTrails(String id, String name, List<Location> points, Polyline polyline, String description) {

    bool exists = false;

    trails.forEach((element) {

      if (element.id == id){
        exists = true;
      }

    });

    if (!exists) {

      var staticMapUri = staticMapProvider.getStaticUriWithPath(points,
          width: 500, height: 200, maptype: StaticMapViewType.terrain);

      trails.add(new Trail(id, name, points, polyline, staticMapUri, description));
    }

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

            //loadLines = [];
            for(var pointMap in trailContent["points"]){
              //can probs reduce to one line later
              Location temp = Location.fromMapFull(pointMap);
              points.add(temp);
            }
            Polyline line = new Polyline(trailContent["id"],
                points,
                width: 15.0,
                color: Colors.red,
                jointType: FigureJointType.round);

            loadLines.add(line);

            generateTrails(id, name, points, line, "Temp Description");

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

  void savedTrailsOption(String choice, Trail trail) {

    if (choice == '0'){
      int middle = (trail.points.length / 2).round();
      showMap(trail.points[middle], 14.0);
    } else if (choice == '1') {
      deleteFile(trail.id);
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


    timeController.text = "0:00:00";
    leftDistanceController.text = "10.0";
    traveledDistanceController.text = "0.00";
    aveSpeedController.text = "0.00";

    countController.text = "Update Count: 0";
    latController.text = "Latitude: 0";
    longController.text = "Longitude: 0";
    speedController.text = "0";
    altitudeController.text = "Altitude: 0";

    return new Scaffold(
      //appBar is the bar displayed at the top of the screen
      appBar: AppBar(
        title: Text("Bike Trail"),
        backgroundColor: Colors.black,
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
        decoration: new BoxDecoration(color: Colors.black87),
        child: new Column(


        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[


        new Container(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center ,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: <Widget>[
          new Container(
            //width: 300.0,
            //height: 20.0,
            //color: Colors.blue,
            child: new TextField(
                controller: speedController,
                enabled: false,
                textAlign: TextAlign.center,
                style: new TextStyle(color: Colors.white, fontSize: 48.0, fontWeight: FontWeight.bold,  ),
            ),
          ),
          new Container(
            //width: 300.0,
            //height: 20.0,
            //color: Colors.blue,
            child: new Text(
              'Current Speed(mph)',
              textAlign: TextAlign.center,
              style: new TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold, ),


            ),
          ),
          ],
          ),
        ),


 /*


          new Container(
            width: 150.0,
            height: 40.0,
            color: Colors.yellowAccent,
            child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new TextField(controller: countController),
                  new Container(
                    width: 150.0,
                    height: 40.0,
                    color: Colors.yellowAccent,
                    child: new TextField(controller: latController),
                  ),
                  new Container(
                    width: 150.0,
                    height: 40.0,
                    color: Colors.yellowAccent,
                    child: new TextField(controller: longController),
                  ),
                ],



            ),

          ),

*/

          new Row(// upper middle
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[

                new Container(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center ,
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: <Widget>[
                      new Container(
                        width: 150.0,
                        height: 40.0,
                        //color: Colors.blue,
                        child: new TextField(
                          controller: timeController,
                          enabled: false,
                          textAlign: TextAlign.center,
                          style: new TextStyle(color: Colors.white, fontSize: 18.0,fontWeight: FontWeight.bold, ),
                        ),
                      ),
                      new Container(
                        //width: 300.0,
                        //height: 20.0,
                        //color: Colors.blue,
                        child: new Text(
                          'Time',
                          textAlign: TextAlign.center,
                          style: new TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold, ),


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
                        width: 150.0,
                        height: 40.0,
                        //color: Colors.yellowAccent,
                        child: new TextField(
                          controller: aveSpeedController,
                          enabled: false,
                          textAlign: TextAlign.center,
                          style: new TextStyle(color: Colors.white, fontSize: 18.0,fontWeight: FontWeight.bold, ),
                        ),
                      ),

                      new Container(
                        //width: 300.0,
                        //height: 20.0,
                        //color: Colors.blue,
                        child: new Text(
                          'Average Speed(mph)',
                          textAlign: TextAlign.center,
                          style: new TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold, ),


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
                      width: 150.0,
                      height: 40.0,
                      //color: Colors.blue,
                      child: new TextField(
                        controller: traveledDistanceController,
                        enabled: false,
                        textAlign: TextAlign.center,
                        style: new TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold,),
                      ),
                    ),
                    new Container(
                      //width: 300.0,
                      //height: 20.0,
                      //color: Colors.blue,
                      child: new Text(
                        'Distance Traveled(mi)',
                        textAlign: TextAlign.center,
                        style: new TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold, ),


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
                      width: 150.0,
                      height: 40.0,
                      //color: Colors.blue,
                      child: new TextField(
                        controller: leftDistanceController,
                        enabled: false,
                        textAlign: TextAlign.center,
                        style: new TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold,),
                      ),
                    ),

                    new Container(
                      //width: 300.0,
                      //height: 20.0,
                      //color: Colors.blue,
                      child: new Text(
                        'Remaining Distance(mi)',
                        textAlign: TextAlign.center,
                        style: new TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold, ),


                      ),
                    ),
                  ],
                ),
              ),


            ],
          ),








      new Container(

        decoration: new BoxDecoration(color: Colors.black),
        child: new Column(
        children: <Widget>[

          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new RaisedButton(
                  child: Text('Map'),
                  elevation: 2.0,
                  onPressed: () => showMap(null, 12.0)
              ),
              new RaisedButton(
                  child: Text("Trails"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder:
                        (context) => SavedTrails(trails: trails, callback: (str, trail) => savedTrailsOption(str, trail))));
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
                  saveTrail(trailNameController.text, polyLines);
                  trailNameController.text = "";
                })
          ],
        );
      },
    );
  }

  void choiceAction(String choice) {
    if (choice == Constants.Settings){
      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsMenu()),
      );
    }
  }

}
