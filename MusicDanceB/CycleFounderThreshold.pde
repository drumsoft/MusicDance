class CycleFounderThreshold extends CycleFounder {
  float upperThreshold;
  float lowerThreshold;
  float previous, previousTime;
  boolean isReady;
  
  CycleFounderThreshold(float upperThreshold, float lowerThreshold, float currentTime) {
    this.upperThreshold = upperThreshold;
    this.lowerThreshold = lowerThreshold;
    previous = 0;
    isReady = true;
    previousTime = currentTime;
  }
  
  boolean input(float current, float currentTime) {
    updated = false;
    if (isReady && previous <= upperThreshold && upperThreshold < current) {
      value = currentTime - previousTime;
      previousTime = currentTime;
      isReady = false;
      updated = true;
    } else if (!isReady && previous >= lowerThreshold && lowerThreshold > current ) {
      isReady = true;
    }
    previous = current;
    return updated;
  }
}
