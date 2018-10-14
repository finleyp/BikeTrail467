import 'package:flutter/material.dart';
import 'Trail.dart';

typedef void StringCallback(String val, Trail trail);


class SavedTrails extends StatefulWidget {
  final List<Trail> trails;
  final StringCallback callback;


  SavedTrails({Key key, @required this.trails, this.callback}) : super(key: key);

  @override
  SavedTrailsState createState() {
    return SavedTrailsState();
  }

}

class SavedTrailsState extends State<SavedTrails> {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              background: Container(color: Colors.red),
              child: new Card(
                child: new Column(
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
                            onPressed: () => deleteTrail(widget.trails[index]),
                          ),
                        ],
                      ),
                    ),
                  ],
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
