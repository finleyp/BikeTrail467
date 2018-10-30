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

  Color titleColor;
  Color backgroundColor;
  Color foregroundColor;
  Color textColor;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (widget.darkTheme) {
      titleColor = Colors.black;
      backgroundColor = Colors.grey[600];
      foregroundColor = Colors.grey[800];
      textColor = Colors.white;
    } else {
      titleColor = Colors.blue;
      backgroundColor = Colors.white;
      foregroundColor = Colors.white;
      textColor = Colors.black;
    }

  }

  final greyColor = const Color(0x68696b);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Saved Trails'),
          backgroundColor: titleColor,
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
                color: foregroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTileTheme(
                  style: ListTileStyle.list,
                  textColor:  textColor,
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
                              textColor: textColor,
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
