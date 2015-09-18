class DepthMapMeshedWires extends DepthMapVisualizer {
  int steps = 7;
  
  DepthMapMeshedWires() {
  }
  
  void drawLine(int from, int to, int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    if(depthMap[from] > 0 && depthMap[to] > 0 && userMap[from] == userMap[to]) {
      PVector fromRealPoint = depthMapReal[from];
      PVector toRealPoint = depthMapReal[to];
      if(userMap[from] == 0) {
        stroke(100);
        strokeWeight(1);
      } else {
        Dancer dancer = _main.getDancer(userMap[from]);
        if (dancer != null) {
          stroke(dancer.getUserColor());
          fromRealPoint = dancer.movePoint(fromRealPoint);
          toRealPoint = dancer.movePoint(toRealPoint);
          strokeWeight(Math.max(Math.min(6, (dancer.getBodyMove()-80) / 40), 2));
        } else {
          stroke(userClr[userMap[from] % userClr.length]);
          strokeWeight(3);
        }
      }
      line(fromRealPoint.x, fromRealPoint.y, fromRealPoint.z,
           toRealPoint.x, toRealPoint.y, toRealPoint.z);
    } // if depth
    
  }
  
  void draw(int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    pushMatrix();
    noStroke();
    for(int y = steps; y < _height; y += steps) {
      for(int x = steps; x < _width; x += steps) {
        int index = x + y * _width;
        int upper = (x - steps) + y * _width;
        int left = x + (y - steps) * _width;
        drawLine(index, upper, depthMap, depthMapReal, userMap);
        drawLine(index, left, depthMap, depthMapReal, userMap);
      } // for x
    } // for y
    popMatrix();
  }
  
}
