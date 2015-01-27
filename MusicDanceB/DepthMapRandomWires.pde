class DepthMapRandomWires extends DepthMapVisualizer {
  int steps = 7;
  
  DepthMapRandomWires() {
  }
  
  void drawLine(int from, int to, int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    if(depthMap[from] > 0 && depthMap[to] > 0 && userMap[from] == userMap[to]) {
      PVector fromRealPoint = depthMapReal[from];
      PVector toRealPoint = depthMapReal[to];
      if(userMap[from] == 0) {
        stroke(100);
        strokeWeight(1);
      } else {
        BPMDetector bpmd = _main.getBpmDetector(userMap[from]);
        if (bpmd != null) {
          stroke(bpmd.getUserColor());
          fromRealPoint = bpmd.movePoint(fromRealPoint);
          toRealPoint = bpmd.movePoint(toRealPoint);
        } else {
          stroke(userClr[userMap[from] % userClr.length]);
        }
        BodyMoveDetector bmd = _main.getBodyMoveDetector(userMap[from]);
        if (bmd != null) {
          strokeWeight(Math.max(Math.min(4, (bmd.getValue()-100) / 50), 1));
        } else {
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
    // ポイントをグループ化
    HashMap<Integer, LinkedList<PVector>> pointsGroups = new HashMap<Integer, LinkedList<PVector>>();
    for(int y = steps; y < _height; y += steps) {
      for(int x = steps; x < _width; x += steps) {
        int index = x + y * _width;
        int user = userMap[index];
        LinkedList<PVector> points = pointsGroups.containsKey(user) ? pointsGroups.get(user) : new LinkedList<PVector>();
        points.push(depthMapReal[index]);
      } // for x
    } // for y
    // 線を引く
    for (Iterator<Entry<Integer,LinkedList<PVector>>> it = pointsGroups.entrySet().iterator(); it.hasNext(); ) {
      Entry<Integer,LinkedList<PVector>> entry = it.next();
      Integer user = entry.getKey();
      LinkedList<PVector> points = entry.getValue();
      // 色設定
      if(user == 0) {
        stroke(100);
        strokeWeight(1);
      } else {
        BPMDetector bpmd = _main.getBpmDetector(user);
        if (bpmd != null) {
          stroke(bpmd.getUserColor());
        } else {
          stroke(userClr[user % userClr.length]);
        }
        BodyMoveDetector bmd = _main.getBodyMoveDetector(user);
        if (bmd != null) {
          strokeWeight(Math.max(Math.min(4, (bmd.getValue()-100) / 50), 1));
        } else {
          strokeWeight(3);
        }
      }
      // 線を引く
      PVector prev = null;
      while (points.size() > 0) {
        int i = (int)random(points.size());
        PVector cur = points.remove(i);
        if (prev != null) {
          line(cur.x, cur.y, cur.z, prev.x, prev.y, prev.z);
        }
        prev = cur;
      }
    }
    popMatrix();
  }
  
}
