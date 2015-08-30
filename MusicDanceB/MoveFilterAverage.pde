class MoveFilterAverage extends MoveFilterBase {
  int samples;
  float[] history;
  float sum;
  int index;
  
  MoveFilterAverage(int samplesNumber, float initialValue) {
    super();
    samples = samplesNumber;
    history = new float[samples];
    for (int i = 0; i < samples; i++) {
      history[i] = initialValue;
      sum += initialValue;
    }
    index = 0;
  }
  
  float input(float current, float time) {
    sum += current - history[index];
    history[index] = current;
    index = (index + 1) % samples;
    value = sum / (float)samples;
    return value;
  }
}
