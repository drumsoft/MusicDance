class MoveFilterBase {
  float value;
  
  MoveFilterBase() {
  }
  
  float input(float current, float time) {
    value = current;
    return value;
  }
  
  float value() {
    return value;
  }
}
