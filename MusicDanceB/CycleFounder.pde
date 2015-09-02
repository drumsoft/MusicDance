class CycleFounder {
  float value;
  boolean updated;
  
  CycleFounder() {
    value = 0;
    updated = false;
  }
  
  boolean input(float current, float currentTime) {
    return false;
  }
  
  float value() {
    return value;
  }
  
  boolean updated() {
    return updated;
  }
}
