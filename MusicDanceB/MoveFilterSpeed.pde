class MoveFilterSpeed extends MoveFilterBase {
  float previous;
  float previousTime;
  
  MoveFilterSpeed(float time) {
    super();
    previous = 0;
    previousTime = time;
  }
  
  float input(float current, float time) {
    float speed = (current - previous) / (time - previousTime);
    previousTime = time;
    previous = current;
    return speed;
  }
}
