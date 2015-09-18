class MoveFilterMeasureAmp extends MoveFilterBase {
  int samples;
  float[] history;
  int index;
  
  MoveFilterMeasureAmp(int samplesNumber, float initialValue) {
    super();
    samples = samplesNumber;
    history = new float[samples];
    for (int i = 0; i < samples; i++) {
      history[i] = initialValue;
    }
    index = 0;
  }
  
  float input(float current, float time) {
    history[index] = current;
    index = (index + 1) % samples;
    float min = history[0];
    float max = history[0];
    for (int i = 1; i < samples; i++) {
      if (min > history[i]) min = history[i];
      if (max < history[i]) max = history[i];
    }
    value = max - min;
    return value;
  }
}
