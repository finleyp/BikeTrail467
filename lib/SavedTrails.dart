import 'package:flutter/material.dart';
import 'Trail.dart';


class SavedTrails extends StatelessWidget {
  final List<Trail> trails;

  SavedTrails({Key key, @required this.trails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Trails'),
        ),
        body: ListView.builder(
          itemCount: trails.length,
          itemBuilder: (context, index){
            return new Card(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new ListTile(
                    //leading: const Icon(Icons.album),
                    title: Text(trails[index].name),
                    subtitle: Text(trails[index].id),
                  ),
                  new Image.network(trails[index].uri.toString()),
                  new ButtonTheme.bar( // make buttons use the appropriate styles for cards
                    child: new ButtonBar(
                      children: <Widget>[
                        new FlatButton(
                          child: const Text('View Map'),
                          onPressed: () { /* ... */ },
                        ),
                        new FlatButton(
                          child: const Text('Delete'),
                          onPressed: () { /* ... */ },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  void deleteTrail(String id) {


  }
}
