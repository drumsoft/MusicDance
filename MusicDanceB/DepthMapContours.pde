import java.util.*;
import java.util.Map.*;

class DepthMapContours extends DepthMapVisualizer {
  int steps = 10;
  int contourSpan = 100;
  
  DepthMapContours() {
  }
  
  // 指定の z 座標に対して、より高い側の等高線座標を返す
  int upperContourDepth(float depth) {
    return (int)ceil(depth / (float)contourSpan) * contourSpan;
  }
  // 指定の z 座標に対して、より低い側の等高線座標を返す
  int lowerContourDepth(float depth) {
    return (int)floor(depth / (float)contourSpan) * contourSpan;
  }
  // 指定のポイント a, b 間に対して、等高線の切片となる位置の配列を linesHash に詰め込む
  void findIntercepts(HashMap<Integer, LinkedList<UserPVector>> linesHash, PVector a, PVector b, int userA, int userB) {
    if (a.z <= b.z) {
      float zSpan = b.z - a.z;
      for (int d = upperContourDepth(a.z), to = lowerContourDepth(b.z); d <= to; d += contourSpan) {
        LinkedList<UserPVector> xyzList;
        if (linesHash.containsKey(d)) {
          xyzList = linesHash.get(d);
        } else {
          xyzList = new LinkedList<UserPVector>();
          linesHash.put(new Integer(d), xyzList);
        }
        float p = ((float)d - a.z) / zSpan;
        float q = 1 - p;
        int user = p > 0.5 ? userB : userA;
        xyzList.push(new UserPVector( q * a.x + p * b.x, q * a.y + p * b.y, (float)d, user));
      }
    } else {
      float zSpan = a.z - b.z;
      for (int d = lowerContourDepth(a.z), to = upperContourDepth(b.z); d >= to; d -= contourSpan) {
        LinkedList<UserPVector> xyzList;
        if (linesHash.containsKey(d)) {
          xyzList = linesHash.get(d);
        } else {
          xyzList = new LinkedList<UserPVector>();
          linesHash.put(new Integer(d), xyzList);
        }
        float p = ((float)d - b.z) / zSpan;
        float q = 1 - p;
        int user = p > 0.5 ? userA : userB;
        xyzList.push(new UserPVector( p * a.x + q * b.x, p * a.y + q * b.y, (float)d, user));
      }
    }
  }
  
  void draw(int[] depthMap, PVector[] depthMapReal, int[] userMap) {
    pushMatrix();
    noStroke();
    for(int y = steps; y < _height; y += steps) {
      for(int x = steps; x < _width; x += steps) {
        // 4隅の index と point
        int idxLT = (x - steps) + (y - steps) * _width;
        int idxRT = x + (y - steps) * _width;
        int idxLB = (x - steps) + y * _width;
        int idxRB = x + y * _width;
        if (depthMap[idxLT] <= 0 || depthMap[idxRT] <= 0 || depthMap[idxLB] <= 0 || depthMap[idxRB] <= 0) {
          continue;
        }
        PVector pointLT = depthMapReal[idxLT];
        PVector pointRT = depthMapReal[idxRT];
        PVector pointLB = depthMapReal[idxLB];
        PVector pointRB = depthMapReal[idxRB];
        int userLT = userMap[idxLT];
        int userRT = userMap[idxRT];
        int userLB = userMap[idxLB];
        int userRB = userMap[idxRB];
        // 線を引き始める位置を選択
        HashMap<Integer, LinkedList<UserPVector>> linesHash = new HashMap<Integer, LinkedList<UserPVector>>();
        findIntercepts(linesHash, pointLT, pointRT, userLT, userRT);
        findIntercepts(linesHash, pointRT, pointRB, userRT, userRB);
        findIntercepts(linesHash, pointLB, pointRB, userLB, userRB);
        findIntercepts(linesHash, pointLT, pointLB, userLT, userLB);
        // 線を引く
        for (Iterator<Entry<Integer,LinkedList<UserPVector>>> it = linesHash.entrySet().iterator(); it.hasNext(); ) {
          Entry<Integer,LinkedList<UserPVector>> entry = it.next();
          LinkedList<UserPVector> intercepts = entry.getValue();
          UserPVector prev = null;
          for (ListIterator<UserPVector> itr = intercepts.listIterator(0); itr.hasNext(); ) {
            UserPVector cur = itr.next();
            int user = cur.user;
            // 設定
            if(user == 0) {
              stroke(100);
              strokeWeight(1);
            } else {
              Dancer dancer = _main.getDancer(user);
              if (dancer != null) {
                stroke(dancer.getUserColor());
                strokeWeight(Math.max(Math.min(7, (dancer.getBodyMove()-50) / 30), 1));
              } else {
                stroke(userClr[user % userClr.length]);
                strokeWeight(3);
              }
            }
            if (prev != null) {
              line(cur.x, cur.y, cur.z, prev.x, prev.y, prev.z);
            }
            prev = cur;
          }
        }
        
      } // for x
    } // for y
    popMatrix();
  }
  
}

class UserPVector extends PVector {
  int user;
  UserPVector(float x, float y, float z, int u) {
    super(x, y, z);
    user = u;
  }
}
