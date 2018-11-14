new Container(
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

Navigator.push(context, MaterialPageRoute(builder:
(context) => SavedTrails(trails: trails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail) => savedTrailsOption(str, trail))));

}
),
new RaisedButton(
child: Text("Local Trails"),
onPressed: () {
//getData("test");
getData();

Navigator.push(context, MaterialPageRoute(builder:
(context) => LocalTrails(trails: localTrails, theme: theme, isKph: isKph, isMeters: isMeters, viewTrail: null, callback: (str, trail) => savedTrailsOption(str, trail))));

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