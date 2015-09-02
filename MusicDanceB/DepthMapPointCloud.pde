class DepthMapPointCloud extends DepthMapVisualizer {
  int steps = 10;
  
  DepthMapPointCloud() {
  }
  
  void draw(int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    pushMatrix();
    noStroke();
    for(int y=0; y < _height; y += steps) {
      for(int x=0; x < _width; x += steps) {
        int index = x + y * _width;
        if(depthMap[index] > 0) {
          PVector realWorldPoint = depthMapReal[index];
          float radiusPlus;
          if(userMap[index] == 0) {
            fill(100);
            radiusPlus = 0;
          } else {
            Dancer dancer = _main.getDancer(userMap[index]);
            if (dancer != null) {
              fill(dancer.getUserColor());
              realWorldPoint = dancer.movePoint(realWorldPoint);
            } else {
              fill(userClr[userMap[index] % userClr.length]);
            }
            BodyMoveDetector bmd = _main.getBodyMoveDetector(userMap[index]);
            if (bmd != null) {
              radiusPlus = Math.max(Math.min(20, (bmd.getValue()-100) / 10), 0);
            } else {
              radiusPlus = 10;
            }
          }
          pushMatrix();
          translate(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z);
          ellipse(0, 0, 10+radiusPlus, 10+radiusPlus);
          popMatrix();
        } // if depth
      } // for x
    } // for y
    popMatrix();
  }
  
}
