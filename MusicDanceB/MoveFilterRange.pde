class MoveFilterRange extends MoveFilterBase {
  float min, max;
  
  MoveFilterRange(float start, float min, float max) {
    this.min = min;
    this.max = max;
    this.value = start;
  }
  
  float input(float current, float time) {
    if (min <= current && current <= max) {
      value = current;
    }
    return value;
  }
}
