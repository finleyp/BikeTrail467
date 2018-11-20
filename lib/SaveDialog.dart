import 'package:flutter/material.dart';

typedef void StringCallback(String val, bool isPublic);


class SaveDialog extends StatefulWidget{
  final TextEditingController trailNameController = new TextEditingController();
  final StringCallback callback;

  SaveDialog({
    Key key, @required this.callback}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SaveDialogState();
  }

}

class SaveDialogState extends State<SaveDialog> {

  bool publicCheck = false;

  @override
  void initState() {
    super.initState();
  }

  _showDialog() {

    return new AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: new Row(
        children: <Widget>[
          new Expanded(
            child: new TextField(
              autofocus: true,
              controller: widget.trailNameController,
              decoration: new InputDecoration(
                  labelText: 'Trail Information', hintText: 'Trail Name', contentPadding: const EdgeInsets.only(top: 16.0)),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        new Column(
          children: <Widget> [
            new Row(
              children: <Widget>[
                new Text("Make Public"),
                new Checkbox(
                    value: publicCheck,
                    onChanged: (bool value) {
                      setState(() {
                        publicCheck = value;
                      });
                    }
                ),
              ],
            ),
            new Row(
              children: <Widget> [
                new FlatButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                new FlatButton(
                    child: const Text('Save'),
                    onPressed: () {
                      Navigator.pop(context);
                      print(widget.trailNameController.text);
                      saveTrail(widget.trailNameController.text, publicCheck);
                      //widget.saveTrail(widget.trailNameController.text, polyLines, timeVal, aveSpeed, distanceTraveledVal);
                    })
              ],
            ),
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return _showDialog();
  }

  void saveTrail(String name, bool isPublic) {
    widget.callback(name, isPublic);
  }

}