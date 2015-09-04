class MoveFilterSpeed extends MoveFilterBase {
  float previous;
  float previousTime;
  
  MoveFilterSpeed(float time) {
    super();
    previous = 0;
    previousTime = -1;
  }
  
  float input(float current, float time) {
    if (time > previousTime && previousTime > 0) {
      value = (current - previous) / (time - previousTime);
    }
    previousTime = time;
    previous = current;
    return value;
  }
}
