import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:map_view/polyline.dart';
import 'package:map_view/figure_joint_type.dart';
import 'package:map_view/location.dart';
import 'package:geolocator/geolocator.dart';
import 'Constants.dart';
import 'SettingsMenu.dart';


//api_key for google maps
var api_key = "AIzaSyBZodZXTiZIxcz6iBwL076yNEq_11769Fo";

List<Polyline> polyLines = new List();

MapView mapView = new MapView();

bool isRecording = false;
bool isMetricSpeed = false;
bool isMetricDist = false;

StreamSubscription<Position> positionStream;

var countController = new TextEditingController();
var latController = new TextEditingController();
var longController = new TextEditingController();
var speedController = new TextEditingController();
var altitudeController = new TextEditingController();
var count = 0;




Polyline newLine = new Polyline(
    "1",
    <Location>[
    ],
    width: 15.0,
    color: Colors.blue,
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

  showMap() {
    //this needs to be updated with gps location on start up
    //mapviewtype terrain currently, can be changed to satellite or normal
    //needs a cool title eventually

    mapView.show(new MapOptions(
        mapViewType: MapViewType.normal,
        initialCameraPosition:
        new CameraPosition(new Location(42.9634, -85.6681), 12.0),

        showUserLocation: true,
        title: "This is a title"));
    mapView.zoomToFit(padding: 50);

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
    var geolocator = Geolocator();
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
  }

  /*
  * This is the face of the app. It will determine what it looks like
  * from the app bar at the top, to each column that is placed below it
  * we need to eventually design it to look how we imagine for now lets
  * focus more on getting the maps working right
  *
  * */
  Widget build(BuildContext context){
    countController.text = "Update Count: 0";
    latController.text = "Latitude: 0";
    longController.text = "Longitude: 0";
    speedController.text = "Speed: 0";
    altitudeController.text = "Altitude: 0";

    return new Scaffold(
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
      body: new Column(

        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new Container(
            //height will set the column at  certain height from the top of the
            //screen defualt height is right below last column or appbar
            //height: 300
            child: new Stack(
              children: <Widget>[
                new Center(
                  child: Container(
                    child: new Text(
                      "Error loading map",
                      textAlign: TextAlign.center,
                    ),
                    padding: const EdgeInsets.all(20.0),
                  ),
                ),
                new InkWell(
                  child: new Center(
                    child: new Image.network(staticMapUri.toString()),
                  ),
                  onTap: showMap,
                )
              ],
            ),
          ),
          new Container(
            padding: new EdgeInsets.only(top: 10.0),
            child: new Text(
              "Tap the map to interact",
              style: new TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          new RaisedButton(
              child: isRecording ? Text("Stop Recording") : Text("Start Recording"),
              elevation: 2.0,
              color: isRecording ? Colors.red : Colors.green,
              onPressed: toggleRecording),
          new TextField(controller: countController),
          new TextField(controller: latController),
          new TextField(controller: longController),
          new TextField(controller: speedController),
          new TextField(controller: altitudeController)
        ],
      ),

    );
  }

  void choiceAction(String choice) {
    if (choice == Constants.Settings){
      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsMenu()),
      );
    }
  }

}
