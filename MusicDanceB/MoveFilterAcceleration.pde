class MoveFilterAcceleration extends MoveFilterBase {
  float previousP;
  float previousV;
  float previousTime;
  
  MoveFilterAcceleration(float time) {
    super();
    previousP = 0;
    previousV = 0;
    previousTime = time;
  }
  
  float input(float current, float time) {
    float timeSpan = time - previousTime;
    float currentV = (current - previousP) / timeSpan;
    value = (currentV - previousV) / timeSpan;
    previousV = currentV;
    previousP = current;
    previousTime = time;
    return value;
  }
}
