class ScreenSaver {
  static final int timeout = 10 * 30; // frames
  
  boolean isVisible, isNoUser;
  int count;
  float bottom, right;
  
  int lines = 10;
  float[] lineWidths = { 80, 60, 20, 10,  8,  6,  4, 99, 66, 33 };
  float[] lineSpeeds = { 54, 33, 58, 22, 33, 86, 27, 17, 31, 43 };
  float[] lineX      = { 37, 44, 48, 06, 47, 41, 46, 19, 87, 61 };
  int[] lineColor    = { 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 };
  
  ScreenSaver() {
    isVisible = true;
    isNoUser = true;
    count = 0;
    
    bottom = uiDisplayTop + uiDisplayHeight;
    right = uiDisplayLeft + uiDisplayWidth;
    
    for (int i = 0; i < lines; i++) {
      lineWidths[i] *= 0.01 * 30.0;
      lineSpeeds[i] *= 0.01 * 10.0;
      lineX[i] *= uiDisplayWidth * 0.01 + uiDisplayLeft;
      lineColor[i] *= #ffffff;
    }
  }
  
  void setPopulation(int number) {
    println("[SAVER] population:" + number);
    if (number == 0) {
      isNoUser = true;
      if (!isVisible) {
        count = 0;
      }
    } else {
      isVisible = false;
      isNoUser = false;
    }
  }
  
  void draw() {
    if (!isNoUser) return;
    if (!isVisible) {
      if (++count < timeout) return;
      isVisible = true;
    }
    
    pushMatrix();
    for (int i = 0; i < lines; i++) {
      lineX[i] += lineSpeeds[i];
      if (lineX[i] > right) lineX[i] = uiDisplayLeft;
      stroke(lineColor[i]);
      strokeWeight(lineWidths[i]);
      line(lineX[i] , uiDisplayTop, lineX[i], bottom);
    }
    popMatrix();
  }
}
