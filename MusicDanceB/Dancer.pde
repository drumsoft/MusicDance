import SimpleOpenNI.*;
import java.util.LinkedList;
import java.util.ListIterator;

class Dancer {
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
  float weight;
  float previousBeatTime;
  float phase;
  
  Dancer(int userId, SimpleOpenNI context, MusicDanceB controller, float currentTime) {
    this.userId = userId;
    this.context = context;
    this.controller = controller;
    
    cycle = 0.5;
    weight = 0;
    
    fSpeed = new MoveFilterSpeed(getTime());
    fLPF = new MoveFilterLPF(3.8, 1, 28);;
    cf = new CycleFounderThreshold(25, -36, getTime());
    fRng = new MoveFilterRange(60/120, 60/190, 60/60);
    fMC = new MoveFilterMultipleCorrect(0.5, 1.5, 10);
    fAvg = new MoveFilterAverage(15, 0.5);
  }
  
  MoveFilterSpeed fSpeed;
  MoveFilterLPF fLPF;
  CycleFounder cf;
  MoveFilterRange fRng;
  MoveFilterMultipleCorrect fMC;
  MoveFilterAverage fAvg;
  
  void update(float currentTime) {
    PVector p = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, p);
    float speed = -fLPF.input(fSpeed.input(p.y, currentTime), currentTime);
    boolean isUpdated = cf.input(speed, currentTime);
    cycle = fMC.input(fRng.input(cf.value(), currentTime), currentTime);
    fAvg.input(cycle, currentTime);
    
    fMC.feedback(60 / sound.currentBPM);
    
    addDataToGraph(userId, 0, 0.5 * speed); // blue
    addDataToGraph(userId, 1, cf.value() * 300); // red
    addDataToGraph(userId, 2, fRng.value() * 300);
    addDataToGraph(userId, 3, fMC.value() * 300);
    addDataToGraph(userId, 4, fAvg.value() * 300);
    addDataToGraph(userId, 5, 300 * 60 / sound.currentBPM);
    
    if (isUpdated) {
      previousBeatTime = currentTime;
      weight += 0.1;
      if (weight > 1.0) weight = 1.0;
      phase = 0;
    } else {
      phase = ((getTime() - previousBeatTime) / cycle) % 1;
    }
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
    return weight;
  }
  
  void setWeight(float weight) {
    this.weight = weight;
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
