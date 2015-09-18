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
              radiusPlus = dancer.strokeWeight(357, 143, 0, 20);
            } else {
              fill(userClr[userMap[index] % userClr.length]);
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
