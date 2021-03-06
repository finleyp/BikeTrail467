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

  ThemeData theme;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    toggleColor();

  }

  //Workaround for updating while looking at the page
  void toggleColor() {
    if (widget.settings.isDarkTheme) {

      theme = ThemeData.dark();

    } else {

      theme = ThemeData.light();

    }
  }

  @override
  Widget build(BuildContext context) {
    String signInValue = widget.settings.signInValue;
    bool isMetricSpeed = widget.settings.isMetricSpeed;
    bool isMetricDist = widget.settings.isMetricDist;
    bool isDarkTheme = widget.settings.isDarkTheme;
    bool isShowDebug = widget.settings.showDebug;

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: new Container (
            child: Center(
                child: ListTileTheme(
                  style: ListTileStyle.list,
                  child: Column(
                    children: <Widget>[
                      SwitchListTile(title: Text('Metric Speed: '),
                          value: isMetricSpeed,
                          onChanged: (bool value) {
                            setState(() {
                              widget.settings.setMetricSpeed = value;
                            });
                            updatePref(value);
                          }),
                      SwitchListTile(title: Text('Metric Distance: '),
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
                          }),
                      SwitchListTile(title: Text('Advanced Dashboard: '),
                          value: isShowDebug,
                          onChanged: (bool value) {
                            setState(() {
                              widget.settings.setDebug = value;
                            });
                            updatePref(value);
                          }),
                      Text(signInValue != null ? "You are signed in as $signInValue" : "You are not signed in"),
                    ],
                  ),
                )
            )
        ),
      ),
    );
  }

  void updatePref(bool val) {
    widget.callback();
  }


}