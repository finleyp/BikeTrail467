import 'package:flutter/material.dart';
import 'Trail.dart';

typedef void StringCallback(String val, Trail trail);


class SavedTrails extends StatefulWidget {
  final List<Trail> trails;
  final StringCallback callback;
  final bool darkTheme;


  SavedTrails({Key key, @required this.trails, this.darkTheme, this.callback}) : super(key: key);

  @override
  SavedTrailsState createState() {
    return SavedTrailsState();
  }

}

class SavedTrailsState extends State<SavedTrails> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: widget.darkTheme ? ThemeData.dark() : ThemeData.light() ,
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
              // Show a red background as the item is swiped away
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
                        //leading: const Icon(Icons.album),
                        title: Text(widget.trails[index].name),
                        subtitle: Text(widget.trails[index].id),
                      ),
                      new Image.network(widget.trails[index].uri.toString()),
                      new ButtonTheme.bar( // make buttons use the appropriate styles for cards
                        child: new ButtonBar(
                          children: <Widget>[
                            new FlatButton(
                              child: const Text('View Map'),
                              onPressed: () => showOnMap(widget.trails[index]),
                            ),
                          ],
                        ),
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


  void deleteTrail(Trail trail) {

    widget.callback("1" , trail);
  }

  void showOnMap(Trail trail) {

    widget.callback("0", trail);
  }

}
