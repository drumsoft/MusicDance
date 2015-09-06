class MoveFilterRange extends MoveFilterBase {
  float min, max;
  boolean isValid;
  
  MoveFilterRange(float start, float min, float max) {
    this.min = min;
    this.max = max;
    if (start < min) start = min;
    if (start > max) start = max;
    this.value = start;
    isValid = false;
  }
  
  float input(float current, float time) {
    if (min <= current && current <= max) {
      value = current;
      isValid = true;
    } else {
      isValid = false;
    }
    return value;
  }
  
  boolean isValid() {
    return isValid;
  }
}
