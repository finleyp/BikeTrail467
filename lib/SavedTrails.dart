import 'package:flutter/material.dart';
import 'Trail.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:map_view/location.dart';

typedef void StringCallback(String val, Trail trail);

bool isM;
bool isK;


class SavedTrails extends StatefulWidget {
  final List<Trail> trails;
  final StringCallback callback;
  final ThemeData theme;
  final bool isMeters;
  final bool isKph;


  SavedTrails({
    Key key, 
    @required this.trails, 
    @required this.theme, 
    @required this.isKph, 
    @required this.isMeters, 
    @required this.callback}) : super(key: key);

  @override
  SavedTrailsState createState() {
    return SavedTrailsState();
  }

}

class SavedTrailsState extends State<SavedTrails> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    isM = widget.isMeters;
    isK = widget.isKph;
  }

  void deleteTrail(Trail trail) {

    widget.callback("1" , trail);
  }

  void showOnMap(Trail trail) {

    widget.callback("0", trail);
  }


  List<charts.Series<Point, int>> createData(List<Location> points) {

    List<Point> data = [];


    for (var loc in points) {
      data.add(new Point(points.indexOf(loc), convertAlt(loc.altitude).round(), convertSpeed(loc.speed)));
    }

    return [
      new charts.Series<Point, int>(
        id: 'Alt',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (Point alt, _) => alt.count,
        measureFn: (Point alt, _) => alt.alt,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: widget.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Trails'),
        ),
        body: ListView.builder(
          itemCount: widget.trails.length,
          itemBuilder: (context, index){
            return Dismissible(
              key: Key(widget.trails[index].id),
              onDismissed: (direction) {

                Trail temp = widget.trails[index];

                // Remove the item from our data source.
                setState(() {
                  widget.trails.removeAt(index);
                });

                // Then show a snackbar!
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text(temp.name + " dismissed")));

                // Then delete trail
                deleteTrail(temp);

              },
              // Show a trash can as the item is swiped away
              background: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.all(20.0),
                  child: Icon(Icons.delete)),
              secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.all(20.0),
                  child: Icon(Icons.delete)),
              child: new Card(
                elevation: 10.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTileTheme(
                  style: ListTileStyle.list,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new ListTile(
                        title: Text(widget.trails[index].name),
                        subtitle: Text(widget.trails[index].id),
                      ),
                      new Image.network(widget.trails[index].uri.toString()),
                      new ButtonTheme.bar( // make buttons use the appropriate styles for cards
                        child: new ButtonBar(
                          children: <Widget>[
//                            new FlatButton(
//                              child: const Text('View Map'),
//                              onPressed: () => showOnMap(widget.trails[index]),
//                            ),
                          ],
                        ),
                      ),
                      new ExpansionTile(
                        title: Text("Stats"),
                        children: <Widget>[
                          new SimpleLineChart(seriesList: (createData(widget.trails[index].points)), trail: widget.trails[index]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

double convertSpeed(var speed){

  if(isK) {
    //Convert from Mps to Kph -- 1 mps = 3.6 kph
    double speedKph = speed * 3.6;
    return speedKph;//.toStringAsFixed(1);

  } else {
    //Convert to Mph -- 1 mps = 2.236934 mph
    double speedMph = speed * 2.236934;
    return speedMph;//.toStringAsFixed(1);

  }
}

double convertAlt(var alt){
  if(isM) {
    //return meters
    return alt;

  } else {
    //Convert to feet -- 1 meter = 3.28084 feet
    double altFt = alt * 3.28084;
    return altFt;

  }
}

double convertDist(var distInKm){
  if(isM) {
    //return Km
    return distInKm;

  } else {
    //Convert to miles -- 1 meter = 3.28084 feet
    double dist = distInKm / 1.609;
    return dist;

  }
}

class SimpleLineChart extends StatefulWidget {
  final List<charts.Series> seriesList;
  final bool animate;
  final Trail trail;

  SimpleLineChart({Key key, @required this.seriesList, @required this.trail, this.animate }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SimpleLineChartState();
  }
}


class SimpleLineChartState extends State<SimpleLineChart> {

  String selectedAlt = "Altitude: ";
  String selectedSpeed = "Speed: ";
  String length = "Length: ";
  String bestTime = "Best Time: ";
  String avgSpeed = "Average Speed: ";

  
  onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;

    final measures = <String, num>{};

    if (selectedDatum.isNotEmpty) {
      selectedDatum.forEach((charts.SeriesDatum datumPair) {
        measures["alt"] = datumPair.datum.alt;
        measures["speed"] = datumPair.datum.speed;
      });
    }

    // Request a build.
    setState(() {
      selectedAlt = "Altitude: " + measures["alt"].toString();
      selectedSpeed = "Speed: " + measures["speed"].toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: EdgeInsets.all(10.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget> [
          new SizedBox(
            height: 150.0,
            child: charts.LineChart(
              widget.seriesList,
              animate: widget.animate,
              selectionModels: [
                new charts.SelectionModelConfig(
                  type: charts.SelectionModelType.info,
                  changedListener: onSelectionChanged,
                )
              ],
              primaryMeasureAxis: new charts.NumericAxisSpec(
                  tickProviderSpec: charts.BasicNumericTickProviderSpec(desiredTickCount: 4)),
              secondaryMeasureAxis: new charts.NumericAxisSpec(
                  tickProviderSpec: charts.BasicNumericTickProviderSpec(desiredTickCount: 0)),
//              layoutConfig: new charts.LayoutConfig(
//                  leftMarginSpec: new charts.MarginSpec.fixedPixel(30),
//                  topMarginSpec: new charts.MarginSpec.fixedPixel(20),
//                  rightMarginSpec: new charts.MarginSpec.fixedPixel(20),
//                  bottomMarginSpec: new charts.MarginSpec.fixedPixel(10)),
            ),
          ),
          new Divider(),
          Text("Selected Point", style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          Text(selectedAlt),
          Text(selectedSpeed),
          new Divider(),
          Text("Overall", style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          Text(length + convertDist(widget.trail.length).toStringAsFixed(3)),
          Text(bestTime + widget.trail.time),
          Text(avgSpeed + widget.trail.avgSpeed.toStringAsFixed(1)),
        ],
      ),
    );
  }
}


/// Sample linear data type.
class Point {
  final int count;
  final int alt;
  final double speed;

  Point(this.count, this.alt, this.speed);
}
