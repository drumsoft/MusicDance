import java.util.*;
import java.util.Map.*;

class DepthMapContours extends DepthMapVisualizer {
  int steps = 20;
  int contourSpan = 50;
  
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
  void findIntercepts(HashMap<Integer, LinkedList<PVector>> linesHash, PVector a, PVector b) {
    if (a.z <= b.z) {
      float zSpan = b.z - a.z;
      for (int d = upperContourDepth(a.z), to = upperContourDepth(b.z); d <= to; d += contourSpan) {
        LinkedList<PVector> xyzList = linesHash.containsKey(d) ? linesHash.get(d) : new LinkedList<PVector>();
        float p = (float)d - a.z / zSpan;
        float q = 1 - p;
        xyzList.push(new PVector( q * a.x + p * b.x, q * a.y + p * b.y, (float)d ));
      }
    } else {
      float zSpan = a.z - b.z;
      for (int d = upperContourDepth(a.z), to = upperContourDepth(b.z); d >= to; d -= contourSpan) {
        LinkedList<PVector> xyzList = linesHash.containsKey(d) ? linesHash.get(d) : new LinkedList<PVector>();
        float p = (float)d - b.z / zSpan;
        float q = 1 - p;
        xyzList.push(new PVector( p * a.x + q * b.x, p * a.y + q * b.y, (float)d ));
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
        PVector pointLT = depthMapReal[idxLT];
        PVector pointRT = depthMapReal[idxRT];
        PVector pointLB = depthMapReal[idxLB];
        PVector pointRB = depthMapReal[idxRB];
        // 線を引き始める位置を選択
        HashMap<Integer, LinkedList<PVector>> linesHash = new HashMap<Integer, LinkedList<PVector>>();
        findIntercepts(linesHash, pointLT, pointRT);
        findIntercepts(linesHash, pointRT, pointRB);
        findIntercepts(linesHash, pointLB, pointRB);
        findIntercepts(linesHash, pointLT, pointLB);
        // 設定
        if(userMap[idxRB] == 0) {
          stroke(100);
          strokeWeight(1);
        } else {
          BPMDetector bpmd = _main.getBpmDetector(userMap[idxRB]);
          if (bpmd != null) {
            stroke(bpmd.getUserColor());
          } else {
            stroke(userClr[userMap[idxRB] % userClr.length]);
          }
          BodyMoveDetector bmd = _main.getBodyMoveDetector(userMap[idxRB]);
          if (bmd != null) {
            strokeWeight(Math.max(Math.min(4, (bmd.getValue()-100) / 50), 1));
          } else {
            strokeWeight(3);
          }
        }
        // 線を引く
        for (Iterator<Entry<Integer,LinkedList<PVector>>> it = linesHash.entrySet().iterator(); it.hasNext(); ) {
          Entry<Integer,LinkedList<PVector>> entry = it.next();
          LinkedList<PVector> intercepts = entry.getValue();
          PVector prev = null;
          for (ListIterator<PVector> itr = intercepts.listIterator(0); itr.hasNext(); ) {
            PVector cur = itr.next();
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
