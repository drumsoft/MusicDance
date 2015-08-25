class MoveFilterMultipleCorrect {
  float value;
  float base;
  float min, max;
  
  MoveFilterMultipleCorrect(float start, float threshold) {
    base = start;
    min = 1 / threshold;
    max = threshold;
  }
  
  float input(float current, float time) {
    if (current > base && current > max * base) {
      value = base + current - Math.round(current / base) * base;
    } else if (current < base && current < min * base) {
      value = base + current - base / Math.round(base / current);
    } else {
      value = current;
    }
    return value;
  }
  
  void feedback(float v) {
    base = v;
  }
}
