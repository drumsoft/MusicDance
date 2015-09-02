class CycleFounderShift extends CycleFounder {
  int minCycle, maxCycle, samplesToSee;
  int numOfSamples;
  int cur;
  float[] samples;
  int numOfSums;
  float[] sums;
  float cycle;
  
  CycleFounderShift(int minCycle, int maxCycle, int samplesToSee) {
    this.minCycle = minCycle;
    this.maxCycle = maxCycle;
    this.samplesToSee = samplesToSee;
    
    cur = 0;
    numOfSamples = samplesToSee + maxCycle;
    samples = new float[numOfSamples];
    for (int i = 0; i < numOfSamples; i++) {
      samples[i] = 0;
    }
    
    numOfSums = maxCycle - minCycle + 1;
    sums = new float[numOfSums];
    for (int i = 0; i < numOfSums; i++) {
      sums[i] = 0;
    }
  }
  
  float sample(int index) {
    while (index < 0) { index += numOfSamples; }
    while (index >= numOfSamples) { index -= numOfSamples; }
    return samples[index];
  }
  
  boolean input(float current, float currentTime) {
    // update sums and find maximum
    int minIndex = -1;
    float minSum = 0;
    for (int i = 0; i < numOfSums; i++) {
      int k = i + minCycle;
      sums[i] = sums[i]
       + Math.abs(current - sample(cur - k))
       - Math.abs(sample(cur - k) - sample(cur - k - k));
      if (minIndex < 0 || minSum > sums[i]) {
        minSum = sums[i];
        minIndex = i;
      }
    }
    
    // cycle
    float cycle = minCycle + minIndex;
    // liner interpolate
    if (minIndex > 0 && minIndex < numOfSums - 1) {
      float slope = Math.max(sums[minIndex - 1], sums[minIndex + 1]) - minSum;
      float ip = - (sums[minIndex + 1] - sums[minIndex - 1]) / 2 / slope;
//      println("cycle: " + String.valueOf(cycle) + " ip: " + String.valueOf(ip) + ", BPM: " + String.valueOf(60 * 29 / cycle));
    } else {
//      println("cycle: " + String.valueOf(cycle) + ", BPM: " + String.valueOf(60 * 29 / cycle));
    }
    
    // push current to samples
    samples[cur] = current;
    cur = (cur + 1) % numOfSamples;
    
    if (cycle != value) {
      updated = true;
    } else {
      updated = false;
    }
    value = cycle;
    return updated;
  }
}
