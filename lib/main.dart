import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:map_view/polyline.dart';
import 'package:map_view/figure_joint_type.dart';
import 'package:map_view/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';


//api_key for google maps
var api_key = "AIzaSyBZodZXTiZIxcz6iBwL076yNEq_11769Fo";

List<Polyline> polyLines = new List();
List<Polyline> loadLines = new List();

MapView mapView = new MapView();

bool isRecording = false;

StreamSubscription<Position> positionStream;

var countController = new TextEditingController();
var latController = new TextEditingController();
var longController = new TextEditingController();
var count = 0;




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
    mapView.setPolylines(loadLines);


  }


  void toggleRecording() {

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

          //convert the Position object to Location object to be usable with map_view
          Location loc = new Location(position.latitude, position.longitude);

          //Add point to polylines object
          newLine.points.add(loc);



          count++;

          countController.text = "Update Count: " + count.toString();
          latController.text = "Latitude: " + loc.latitude.toString();
          //position.latitude.toString();
          longController.text = "Longitude: " + loc.longitude.toString();




          //Clear the list of polylines before adding the new version
          polyLines.clear();

          //Add newLine to List of polylines
          polyLines.add(newLine);

          mapView.clearPolylines();

          //Update lines on map
          mapView.setPolylines(polyLines);
          mapView.setPolylines(loadLines);

            });



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
      trailsJsonFile = new File(dir.path + "/" + fileName);
      fileExists = trailsJsonFile.existsSync();
      //HEREREREERERHERERER
      //Later when we are loading more than one file this will need to be moved into the load method and trailsJsonFile will need to be the name of the file we want.
      if (fileExists) this.setState(() => trailContent = json.decode(trailsJsonFile.readAsStringSync()));
    });
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
  void saveTrail(String name, List<Polyline> lines){
    if(count > 1) {
      Map<String, dynamic> tInfo = lines[0].toMap();
      //lines.forEach((line) => print(line.toMap()));
      if (fileExists) {
        //Map<String, dynamic> jsonFileContent = json.decode(trailsJsonFile.readAsStringSync());
        //jsonFileContent.addAll(tInfo);
        print("Ha found you scrub");
        trailsJsonFile.writeAsStringSync(json.encode(tInfo));
      } else {
        createJson(tInfo, dir, fileName);
      }
      this.setState(() =>
      trailContent = json.decode(trailsJsonFile.readAsStringSync()));
      print("saved");
      print(trailContent);
    }
  }

  void buildFromJson(){
    if(trailContent.isNotEmpty){
        //So when you do a map of a polyline it makes the location a map
        //we need to get the map form the map to get the list
        List<Location> points = [];
        loadLines = [];
        for(var pointMap in trailContent["points"]){
          //can probs reduce to one line later
          Location temp = Location.fromMapFull(pointMap);
          points.add(temp);
         // print(temp);
        }
        print(points);
        loadLine = new Polyline(trailContent["id"],points);
        print(loadLine.points);
        loadLines.add(loadLine);
      mapView.setPolylines(loadLines);
      print(loadLines.toString());
      print(loadLines[0].points.toString());
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
    countController.text = "Update Count: 0";
    latController.text = "Latitude: 0";
    longController.text = "Longitude: 0";

    return new Scaffold(
      //appBar is the bar displayed at the top of the screen
      appBar: AppBar(
        title: Text("Bike Trail"),
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
          new RaisedButton(
            child:  Text("SAVE TRAIL"),
            onPressed: () => saveTrail("Trail", polyLines),),
          new RaisedButton(
            child: new Text("LOAD TRAIL"),
            onPressed: () => buildFromJson(),)
        ],
      ),

    );
  }
}
