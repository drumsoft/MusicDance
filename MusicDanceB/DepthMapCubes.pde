class DepthMapCubes extends DepthMapVisualizer {
  int steps = 10;
  
  DepthMapCubes() {
  }
  
  float rotation = 0;
  
  void draw(int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    directionalLight(255, 255, 255, -0.7, -1, 1);
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
              radiusPlus = Math.max(Math.min(20, (dancer.getBodyMove()-100) / 10), 0);
            } else {
              fill(userClr[userMap[index] % userClr.length]);
              radiusPlus = 10;
            }
          }
          pushMatrix();
          translate(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z);
          if (radiusPlus > 0) {
            rotateX(radiusPlus * (rotation + index / 100));
            rotateY(radiusPlus * (rotation + index / 100));
          }
          box(20 + 2 * radiusPlus);
          popMatrix();
        } // if depth
      } // for x
    } // for y
    popMatrix();
    rotation = (rotation + 0.010) % TWO_PI;
  }
  
}
