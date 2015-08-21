class MoveFilterLPF extends MoveFilterBase {
  float x, x1, x2, y1, y2;
  float k1, k2, k3, k4, k5, a0;
  
  MoveFilterLPF(float freq, float q, float sample_rate) {
    super();
    x = 0;
    x1 = 0;
    x2 = 0;
    value = 0;
    y1 = 0;
    y2 = 0;
    
    float freq_unit = TWO_PI / sample_rate;
    float w0 = freq * freq_unit;
    float alpha = sin(w0) / (2 * q);
    float cs = cos(w0);
    
    float b1 =   1 - cs;
    float b0 = b1 / 2;
    
    a0 = 1 + alpha; //a0;
    k1 = b0; //b0;
    k2 = b1; //b1;
    k3 = b0; //b2;
    k4 =-2 * cs ; //a1;
    k5 = 1 - alpha ; //a2;
  }
  
  float input(float current, float time) {
    x2 = x1;
    x1 = x;
    x = current;
    y2 = y1;
    y1 = value;
    value = (k1*x + k2*x1 + k3*x2 - k4*y1 - k5*y2) / a0;
    return value;
  }
}
