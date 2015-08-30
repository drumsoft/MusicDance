class CycleFounderThreshold extends CycleFounder {
  float upperThreshold;
  float lowerThreshold;
  float previous;
  boolean isReady;
  
  int count;
  int previousCount;
  float cycle;
  
  CycleFounderThreshold(float upperThreshold, float lowerThreshold) {
    this.upperThreshold = upperThreshold;
    this.lowerThreshold = lowerThreshold;
    previous = 0;
    isReady = true;
    count = 0;
    previousCount = 0;
    cycle = 0;
  }
  
  float input(float current) {
    if (isReady && previous <= upperThreshold && upperThreshold < current) {
      cycle = count - previousCount;
      previousCount = count;
      isReady = false;
    } else if (!isReady && previous >= lowerThreshold && lowerThreshold > current ) {
      isReady = true;
    }
    previous = current;
    count++;
    return cycle;
  }
}
