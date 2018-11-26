class Settings {
   String signInValue;
   bool isMetricSpeed;
   bool isMetricDist;
   bool isDarkTheme;
   bool showDebug;

  Settings(this.signInValue, this.isMetricSpeed, this.isMetricDist, this.isDarkTheme, this.showDebug);

  set setSignInValue(String value) {
    signInValue = value;
  }

  set setMetricSpeed(bool value) {
    isMetricSpeed = value;
  }

  set setMetricDist(bool value) {
    isMetricDist = value;
  }

  set setDarkTheme(bool value) {
    isDarkTheme = value;
  }

  set setDebug(bool value) {
    showDebug = value;
  }
}