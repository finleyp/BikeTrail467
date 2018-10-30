import 'package:flutter/material.dart';
import 'Settings.dart';

typedef void StringCallback();


class SettingsMenu extends StatefulWidget {
  final Settings settings;
  final StringCallback callback;
  final bool darkTheme;

  SettingsMenu({Key key, @required this.settings, this.darkTheme, this.callback}) : super(key: key);


  @override
  _SelectionControl createState() => _SelectionControl();

}

class _SelectionControl extends State<SettingsMenu> {

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

  void toggleColor() {
    if (widget.settings.isDarkTheme) {
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

  @override
  Widget build(BuildContext context) {
    bool isMetricSpeed = widget.settings.isMetricSpeed;
    bool isMetricDist = widget.settings.isMetricDist;
    bool isDarkTheme = widget.settings.isDarkTheme;

    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        backgroundColor: titleColor,
        title: Text('Settings'),
      ),
      body: new Container (
          color: foregroundColor,
          child: Center(
              child: ListTileTheme(
                style: ListTileStyle.list,
                textColor:  textColor,
                child: Column(
                  children: <Widget>[
                    SwitchListTile(title: Text('Speed in kph: '),
                        value: isMetricSpeed,
                        onChanged: (bool value) {
                          setState(() {
                            widget.settings.setMetricSpeed = value;
                          });
                          updatePref(value);
                        }),
                    SwitchListTile(title: Text('Distance in meters: '),
                        value: isMetricDist,
                        onChanged: (bool value) {
                          setState(() {
                            widget.settings.setMetricDist = value;
                          });
                          updatePref(value);
                        }),
                    SwitchListTile(title: Text('Dark Theme: '),
                        value: isDarkTheme,
                        onChanged: (bool value) {
                          setState(() {
                            widget.settings.setDarkTheme = value;
                            toggleColor();
                          });
                          updatePref(value);
                        })
                  ],
                ),
              )
          )
      ),
    );
  }

  void updatePref(bool val) {
    widget.callback();
  }


}