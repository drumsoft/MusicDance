class DepthMapRandomWires extends DepthMapVisualizer {
  int steps = 7;
  
  DepthMapRandomWires() {
  }
  
  void draw(int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    pushMatrix();
    noStroke();
    // ポイントをグループ化
    HashMap<Integer, LinkedList<PVector>> pointsGroups = new HashMap<Integer, LinkedList<PVector>>();
    for(int y = 0; y < _height; y += steps) {
      for(int x = 0; x < _width; x += steps) {
        int index = x + y * _width;
        if (depthMap[index] > 0) {
          int user = userMap[index];
          LinkedList<PVector> points;
          if (pointsGroups.containsKey(user)) {
            points = pointsGroups.get(user);
          } else {
            points = new LinkedList<PVector>();
            pointsGroups.put(new Integer(user), points);
          }
          points.push(depthMapReal[index]);
        }
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
          strokeWeight(Math.max(Math.min(8, (bmd.getValue()-80) / 30), 2));
        } else {
          strokeWeight(3);
        }
      }
      // 線を引く
      PVector prev = null;
      int limit = (int)max(points.size() - 200, points.size() * 0.6);
      int jump = max(5, points.size() / (int)random(8, 200));
      for (int i = 0, l = points.size(); i < l; i += (int)random(jump * 0.1, jump * 1.9)) {
        PVector cur = points.get(i);
        if (prev != null) {
          line(cur.x, cur.y, cur.z, prev.x, prev.y, prev.z);
        }
        prev = cur;
      }
    }
    popMatrix();
  }
  
}
