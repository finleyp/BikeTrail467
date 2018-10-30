class Settings {
   bool isMetricSpeed;
   bool isMetricDist;
   bool isDarkTheme;

  Settings(this.isMetricSpeed, this.isMetricDist, this.isDarkTheme);

  set setMetricSpeed(bool value) {
    isMetricSpeed = value;
  }

  set setMetricDist(bool value) {
    isMetricDist = value;
  }

  set setDarkTheme(bool value) {
    isDarkTheme = value;
  }
}