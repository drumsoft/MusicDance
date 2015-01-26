class DepthMapVisualizer {
  MusicDanceB main;
  int width;
  int height;
  int steps = 10;
  
  DepthMapVisualizer() {
  }
  
  void initilize(MusicDanceB md, int w, int h) {
    main = md;
    width = w;
    height = h;
  }
  
  void draw(int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    pushMatrix();
    noStroke();
    for(int y=0; y < height; y += steps) {
      for(int x=0; x < width; x += steps) {
        int index = x + y * width;
        if(depthMap[index] > 0) {
          PVector realWorldPoint = depthMapReal[index];
          float radiusPlus;
          if(userMap[index] == 0) {
            fill(100);
            radiusPlus = 0;
          } else {
            BPMDetector bpmd = main.getBpmDetector(userMap[index]);
            if (bpmd != null) {
              fill(bpmd.getUserColor());
              realWorldPoint = bpmd.movePoint(realWorldPoint);
            } else {
              fill(userClr[userMap[index] % userClr.length]);
            }
            BodyMoveDetector bmd = main.getBodyMoveDetector(userMap[index]);
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
