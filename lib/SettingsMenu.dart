import 'package:flutter/material.dart';

bool _isMetricSpeed = false;
bool _isMetricDist = false;

class SettingsMenu extends StatefulWidget {

  @override
  _SelectionControl createState() => _SelectionControl();

  bool get isMetricSpeed => _isMetricSpeed;

  bool get isMeticDist => _isMetricDist;

}

class _SelectionControl extends State<SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              SwitchListTile(title: Text('Use kph: '), value: _isMetricSpeed, onChanged: (bool value) {
                setState(() => _isMetricSpeed = value);
              }),
              SwitchListTile(title: Text('Use Meters: '), value: _isMetricDist, onChanged: (bool value) {
                setState(() => _isMetricDist = value);
              })
            ],
          ),
        )
    );
  }
}