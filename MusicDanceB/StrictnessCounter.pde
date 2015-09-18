class StrictnessCounter {
  boolean validity;
  int score, min, max;
  float value;
  
  StrictnessCounter(int min, int max) {
    this.min = min;
    this.max = max;
    validity = true;
    score = 0;
    value = 0;
  }
  
  void input(boolean isValid) {
    if (!isValid) validity = false;
  }
  
  float update() {
    if (validity) {
      if (score < max) score++;
    } else {
      if (score > min) score--;
    }
    validity = true;
    value = (float)score / max;
    value = value * value;
    return value;
  }
  
  float value() {
    return value;
  }
  
  int score() {
    return score;
  }
}
