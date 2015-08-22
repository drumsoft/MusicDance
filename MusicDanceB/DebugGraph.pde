import SimpleOpenNI.*;
import java.util.LinkedList;
import java.util.ListIterator;

class DebugGraph {
  float constLine = 1.0;
  float displayZoomY = 10.0;
  int samples = 90;
  
  float base_y, additional_y;
  int numOfSeries;
  LinkedList<Float>[] yList;
  int[] colors;
  
  DebugGraph(float y, int numberOfSeries, int[] colorsOfSeries) {
    numOfSeries = numberOfSeries;
    base_y = y;
    additional_y = constLine * displayZoomY; 
    
    yList = new LinkedList[numOfSeries];
    for (int i = 0; i < numOfSeries; i++) {
      yList[i] = new LinkedList<Float>();
      while (yList[i].size() < samples) {
        yList[i].push(new Float(0));
      }
    }
    
    colors = colorsOfSeries;
  }
  
  void addValue(int series, float y) {
    yList[series].addFirst(y * displayZoomY + base_y);
    yList[series].removeLast();
  }
  
  void draw() {
    pushMatrix();
    stroke(255, 255, 255);
    line(uiDisplayLeft, base_y, uiDisplayLeft+uiDisplayWidth, base_y);
    stroke(200, 200, 200);
    line(uiDisplayLeft, base_y + additional_y, uiDisplayLeft+uiDisplayWidth, base_y + additional_y);
    line(uiDisplayLeft, base_y - additional_y, uiDisplayLeft+uiDisplayWidth, base_y - additional_y);
    
    for (int i = 0; i < yList.length; i++) {
      stroke(colors[i]);
      float px = uiDisplayLeft + uiDisplayWidth, py = yList[i].getFirst();
      int number, xIndex;
      number = xIndex = yList[i].size() - 1;
      ListIterator<Float> itr = yList[i].listIterator(0);
      while (itr.hasNext()) {
        float x = uiDisplayLeft + (uiDisplayWidth * xIndex / number);
        float y = itr.next().intValue();
        line(px,py, x,y);
        px = x; py = y;
        xIndex--;
      }
    }
    popMatrix();
  }
}
