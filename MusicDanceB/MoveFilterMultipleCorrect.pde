class MoveFilterMultipleCorrect extends MoveFilterBase {
  float base;
  float min, max;
  int limit;
  int upperCorrectCount, lowerCorrectCount;
  boolean isValid;
  
  // fps / (120 / 60), 1.5, 60
  MoveFilterMultipleCorrect(float start, float threshold, int limit) {
    base = start;
    min = 1 / threshold;
    max = threshold;
    upperCorrectCount = 0;
    lowerCorrectCount = 0;
    this.limit = limit;
    isValid = false;
  }
  
  float input(float current, float time) {
    if (current > base && current > max * base) {
      if (upperCorrectCount < limit) {
        value = current / Math.round(current / base);
      } else {
        value = current;
      }
      upperCorrectCount++;
      lowerCorrectCount = 0;
      isValid = false;
    } else if (current < base && current < min * base) {
      if (lowerCorrectCount < limit) {
        value = current * Math.round(base / current);
      } else {
        value = current;
      }
      upperCorrectCount = 0;
      lowerCorrectCount++;
      isValid = false;
    } else {
      value = current;
      upperCorrectCount = 0;
      lowerCorrectCount = 0;
      isValid = true;
    }
    return value;
  }
  
  void feedback(float v) {
    base = v;
  }
  
  boolean isValid() {
    return isValid;
  }
}
