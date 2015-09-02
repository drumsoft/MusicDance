import ddf.minim.*;
import ddf.minim.analysis.*;

class CycleFounderFFT extends CycleFounder {
  ddf.minim.analysis.FFT fft;
  
  int size;
  float[] buffer;
  int cur;
  
  float cycle;
  
  CycleFounderFFT(int size, int fps) {
    this.size = size;
    fft = new ddf.minim.analysis.FFT(size, fps);
    buffer = new float[size];
    cur = 0;
  }
  
  boolean input(float current, float currentTime) {
    buffer[cur++] = current;
    if (cur < size) return false;
    cur = 0;
    
    fft.forward(buffer);
    
    int specSize = fft.specSize();
    float maxBand = 0;
    int maxIndex = 0;
//    String hist = String.valueOf(specSize) + ": ";
    for (int i = 0; i < specSize; i++) {
//      hist += String.valueOf(fft.indexToFreq(i)) + "=" + String.valueOf(fft.getBand(i)) + " ";
      if (maxBand < fft.getBand(i)) {
        maxBand = fft.getBand(i);
        maxIndex = i;
      }
    }
//    println(hist);
    
    cycle = 26 / fft.indexToFreq(maxIndex);
    
    if (cycle != value) {
      updated = true;
    } else {
      updated = false;
    }
    value = cycle;
    return updated;
  }
}
