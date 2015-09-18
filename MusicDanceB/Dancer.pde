import SimpleOpenNI.*;
import java.util.LinkedList;
import java.util.ListIterator;

class Dancer {
  static final int strictScoreMax = 64;
  static final int strictScoreMin = 0;
  static final int givenWeightTTL = 150;
  
  int pickupPosition = SimpleOpenNI.SKEL_NECK;
  /*
    頭    SKEL_HEAD -> 首
    首    SKEL_NECK -> 頭,両肩
    肩    SKEL_LEFT_SHOULDER    SKEL_RIGHT_SHOULDER -> 首,腰,肘
    肘    SKEL_LEFT_ELBOW    SKEL_RIGHT_ELBOW -> 肩,手首
    手首  SKEL_LEFT_HAND    SKEL_RIGHT_HAND -> 肘,指先
    腰    SKEL_TORSO -> 両肩,両尻
    尻    SKEL_LEFT_HIP    SKEL_RIGHT_HIP -> 腰,膝
    膝    SKEL_LEFT_KNEE    SKEL_RIGHT_KNEE -> 尻,足
    足    SKEL_LEFT_FOOT    SKEL_RIGHT_FOOT -> 膝
  */
  
  SimpleOpenNI context;
  MusicDanceB controller;
  int userId;
  float cycle;
  float previousBeatTime;
  float phase;
  float strictness, givenWeight, givenWeightLife;
  PVector center;
  
  static final int heartOffsets = 9;
  float[] heartRadians = new float[heartOffsets];
  float[] heartRadius = new float[heartOffsets];
  float[] heartZ = new float[heartOffsets];
  float[] heartSize = new float[heartOffsets];
  
  Dancer(int userId, SimpleOpenNI context, MusicDanceB controller, float currentTime) {
    this.userId = userId;
    this.context = context;
    this.controller = controller;
    
    cycle = 0.5;
    strictness = 0;
    givenWeight = 0;
    givenWeightLife = 0;
    float currentCycle = 60 / sound.currentBPM;
    center = new PVector();
    
    fSpeed = new MoveFilterSpeed(currentTime); // startValue, currentTime
    fLPF = new MoveFilterLPF(3.8, 1, 28); // cutoff(hz), Q, samplingrate(hz)
    cf = new CycleFounderThreshold(25, -36, currentTime); // upperTh(speed), lowerTh, currentTime
    fRng = new MoveFilterRange(currentCycle, 60.0/190.0, 60.0/60.0); // startValue(cycle), min, max
    fMC = new MoveFilterMultipleCorrect(currentCycle, 1.5, 10); // startValue, threshold(current/previous), limit(samples)
    fAvg = new MoveFilterAverage(15, currentCycle); // samplesNumber, startValue
    sc = new StrictnessCounter(strictScoreMin, strictScoreMax);
    
    for (int i = 0; i < heartOffsets; i++) {
      heartRadians[i] = 2.0 * (float)Math.PI * ((float)Math.random() - 0.5) / 10;
      heartRadius[i]  = 30 * ((float)(Math.random() + Math.random()) / 2 - 1);
      heartZ[i] = (float)(2.0 * Math.PI * Math.random());
      heartSize[i] = 12 + 90 * (float)Math.random();
    }
  }
  
  MoveFilterSpeed fSpeed;
  MoveFilterLPF fLPF;
  CycleFounder cf;
  MoveFilterRange fRng;
  MoveFilterMultipleCorrect fMC;
  MoveFilterAverage fAvg;
  StrictnessCounter sc;
  
  void update(float currentTime) {
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, center);
    
    PVector p = new PVector();
    context.getJointPositionSkeleton(userId, pickupPosition, p);
    float speed = -fLPF.input(fSpeed.input(p.y, currentTime), currentTime);
    boolean isUpdated = cf.input(speed, currentTime);
    cycle = fMC.input(fRng.input(cf.value(), currentTime), currentTime);
    fAvg.input(cycle, currentTime);
    
    fMC.feedback(fAvg.value);
    
    addDataToGraph(userId, 0, 0.1 * speed); // speed
    addDataToGraph(userId, 1, cf.value() * 200); // raw cycle
    //addDataToGraph(userId, 2, fRng.value() * 200); // ranged
    addDataToGraph(userId, 2, fMC.value() * 200); // corrected
    //addDataToGraph(userId, 4, fAvg.value() * 200); // averaged
    addDataToGraph(userId, 3, strictness * 200); // strictness
    addDataToGraph(userId, 4, 200 * 60 / sound.currentBPM);
    
    if (isUpdated) {
      previousBeatTime = currentTime;
      phase = 0;
      
      sc.input(fRng.isValid());
      sc.input(fMC.isValid());
      strictness = sc.update();
      
      sound.kick();
      
    } else {
      phase = ((getTime() - previousBeatTime) / cycle) % 1;
    }
    
    if (givenWeightLife > 0) givenWeightLife--;
  }
  
  // -----------------------------------------------------
  
  // cycle(seconds/beat)
  float getCycle() {
    return cycle;
  }
  
  float getPhase() {
    return phase;
  }
  
  float getWeight() {
    return givenWeightLife > 0 ? (givenWeight + strictness) : strictness;
  }
  
  float getStrictness() {
    return strictness;
  }
  
  void setWeight(float weight) {
    givenWeight = weight;
    givenWeightLife = givenWeightTTL;
  }
  
  // bpm with smoothing
  float getSmoothBPM() {
    return 60 / fAvg.value();
  }
  
  // -----------------------------------------------------
  
  void drawHeart() {
    if (givenWeightLife > 0 && givenWeight >= 0.5) {
      int count = (int)Math.floor(2 * givenWeight);
      float phase = 2.0 * (float)Math.PI * 0.25 * givenWeightLife / (28 * cycle);
      float radius = 150 + givenWeight * 20;
      pushMatrix();
      noStroke();
      fill(#ed008c);
      for (int i = 0; i < count; i++) {
        float phase_ = phase + 2.0 * (float)Math.PI * ((float)i / count) + heartRadians[i % heartOffsets];
        float radius_ = radius + heartRadius[i % heartOffsets];
        float x = center.x + radius_ * (float)Math.cos(phase_);
        float y = center.y + 30 * (float)Math.sin(phase_ + heartZ[i % heartOffsets]);
        float z = center.z + radius_ * (float)Math.sin(phase_);
        float r = heartSize[i % heartOffsets];
        pushMatrix();
        translate(x, y, z);
        ellipse(0, 0, r, r);
        popMatrix();
      }
      popMatrix();
    }
  }
  
  // -----------------------------------------------------
  DebugGraph graph;
  
  PVector centerVector;
  float zoom;
  color originalUserColor, currentUserColor;
  
  void initVisual(color userColor) {
    centerVector = new PVector();
    originalUserColor = userColor;
  }
  
  void updateVisual() {
    float elapsedTime = getTime() - previousBeatTime;
    zoom = 1.1 - elapsedTime;
    if (elapsedTime < 0.1) {
      currentUserColor = lerpColor(whiteColor, originalUserColor, elapsedTime * 2.5);
    } else {
      currentUserColor = originalUserColor;
    }
    context.getCoM(userId, centerVector);
  }
  
  color getUserColor() {
    return currentUserColor;
  }
  
  PVector movePoint(PVector in) {
    if (zoom > 1.0) {
      return new PVector(
        zoom * (in.x - centerVector.x) + centerVector.x,
        zoom * (in.y - centerVector.y) + centerVector.y,
        zoom * (in.z - centerVector.z) + centerVector.z
      );
    } else {
      return in;
    }
  }
}
