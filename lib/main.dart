import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:map_view/polyline.dart';

//api_key for google maps
var api_key = "";
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
  MapView mapView = new MapView();

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
        mapViewType: MapViewType.terrain,
        initialCameraPosition:
          new CameraPosition(new Location(42.9634, -85.6681), 2.0),
        showUserLocation: true,
        title: "This is a title"));
    mapView.zoomToFit(padding: 50);

    Location loc1;
    Location loc2;
    int count = 0;
    Polyline temp;

    mapView.onLocationUpdated
        .listen((location) {
      //print("Location updated $location");

      if (loc1 == null){
        loc1 = location;
      } else if (loc2 == null){
        loc2 = location;
      }else if (loc1 !=  null && loc2 != null) {

        print('location1: $loc1');
        print('location2: $loc2');
       /* mapView.addPolyline(new Polyline(
            "12",
            <Location>[
              loc1,
              loc2,
            ],
            width: 15.0));*/
        count ++;
        temp = new Polyline(
            count.toString(),
            <Location>[
              loc1,
              loc2,
            ],
            width: 15.0);
        polyLine.add(temp);
        //setPoly(loc1, loc2, count.toString());
        setPolyLine(temp);
        loc1 = loc2;

        loc2 = null;
      }

    });


    //Essential a button listener for flutter
    //Currently zooms out to random location like example
    mapView.onMapTapped.listen((_) {
      setState(() {
        mapView.setCameraPosition(new CameraPosition(new Location(42.9639, -85.8889),15.0));
        mapView.zoomToFit(padding: 100);
      });
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
  }

  void setPoly(Location loc1, Location loc2, String x){
    print("here: " + x);
    mapView.addPolyline(new Polyline(
        x,
        <Location>[
          loc1,
          loc2,
        ],
        width: 15.0));
    print("WOOHOO I DID IT");
  }

  void setPolyLine(Polyline line){
    mapView.addPolyline(line);
  }
  /*
  * This is the face of the app. It will determine what it looks like
  * from the app bar at the top, to each column that is placed below it
  * we need to eventually design it to look how we imagine for now lets
  * focus more on getting the maps working right
  *
  * */
  Widget build(BuildContext context){
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
        )
      ],
    ),

    );
  }
}
