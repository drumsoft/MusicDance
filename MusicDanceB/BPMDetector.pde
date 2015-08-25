import SimpleOpenNI.*;
import java.util.LinkedList;
import java.util.ListIterator;

class BPMDetector {
  int movingAverageWidth = 3; // 位置の移動平均値
  float[] jointsSpeedAmp = { // 関節のスピードを amplify して量を揃える
    -1.0,
    -1.0,
//    3.0,
//    5.0,
//    5.0,
    5.0,
    5.0
  };
  int[][] jointsToReadBPM = { // BPMの読み込みに使うSkelton上の関節設定
    { SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_HAND }, // 左肘
//    { SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_HAND }, // 右肘
    { SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_TORSO }, // 頭(ヘドバン)
//    { SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_FOOT}, // 左膝
//    { SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_FOOT}, // 右膝
    { SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_SHOULDER}, // 左膝
    { SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_SHOULDER}, // 右膝
  };
  /*
    頭    SKEL_HEAD -> 首
    首    SKEL_NECK -> 頭,両肩
    肩    SKEL_LEFT_SHOULDER    SKEL_RIGHT_SHOULDER -> 首,腰,肘
    肘    SKEL_LEFT_ELBOW    SKEL_RIGHT_ELBOW -> 肩,手首
    手首  SKEL_LEFT_HAND    SKEL_RIGHT_HAND -> 肘,指先
    指先  SKEL_LEFT_FINGERTIP    SKEL_RIGHT_FINGERTIP -> 手首
    腰    SKEL_TORSO -> 両肩,両尻
    尻    SKEL_LEFT_HIP    SKEL_RIGHT_HIP -> 腰,膝
    膝    SKEL_LEFT_KNEE    SKEL_RIGHT_KNEE -> 尻,足
    足    SKEL_LEFT_FOOT    SKEL_RIGHT_FOOT -> 膝
  */
  float th_SPB_variant_max = 1.2; // これ以上に早くなる場合は無視する
  float th_SPB_variant_min = 0.833; // これ以下に遅くなる場合は無視する
  
  SimpleOpenNI context;
  MusicDanceB controller;
  int userId;
  ArthroAngularSpeedometer[] speedometers;
  
  float previousBeatTime; // 前回ビートとして判定した時刻
  float result_secondsPerBeat = 0.5; // 現在検出しているビート(秒/ビート)
  float result_power; // 現在のパワー
  
  BPMDetector(int uid, SimpleOpenNI c, MusicDanceB a_controller, float currentTime) {
    int i;
    userId = uid;
    context = c;
    controller = a_controller;
    
    speedometers = new ArthroAngularSpeedometer[jointsToReadBPM.length];
    for (i = 0; i < jointsToReadBPM.length; i++) {
      //MoveFilterBase f1 = new MoveFilterAverage(movingAverageWidth);
      MoveFilterBase f1 = new MoveFilterLPF(5, 1, 27);
      //MoveFilterBase f2 = new MoveFilterSpeed(currentTime);
      MoveFilterBase f2 = new MoveFilterSpeed(currentTime);
      speedometers[i] = new ArthroAngularSpeedometer(userId, context, jointsSpeedAmp[i],  jointsToReadBPM[i], currentTime, f1, f2);
    }
  }
  
  MoveFilterBase t1f = new MoveFilterLPF(5, 1, 27);
  MoveFilterBase t1s = new MoveFilterSpeed(0);
  CycleFounder cf1 = new CycleFounderShift(8, 30, 60);
  CycleFounder cf2 = new CycleFounderFFT(64, 26);
  float clipping = 1.0;
  
  void fetchPositionData(float currentTime) {
    
    PVector p = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, p);
    float speed = t1f.input(t1s.input(p.y, currentTime), currentTime);
    addDataToGraph(userId, 0, speed / 25); // yello
    addDataToGraph(userId, 1, cf2.input(speed)); // cyan
    if (speed > clipping) {
      speed = clipping;
    } else if (speed < -clipping) {
      speed = -clipping;
    }
    //addDataToGraph(userId, 1, speed); // purple
    float cycle = cf1.input(speed);
    addDataToGraph(userId, 2, cycle); // cyan
    //println("BPM: " + String.valueOf(60 * 29 / cycle));
    
    boolean isTapped = false;
    for (int i = 0; i < speedometers.length; i++) {
      if (speedometers[i].update(currentTime)) {
        isTapped = true;
      }
    }
    if (isTapped) {
      updateBeats(currentTime);
    }
  }
  
  // タップ履歴を検証して、有効なタップならビートを更新し、タップ検出コールバックを行う
  void updateBeats(float time) {
    float powerMax = 0;
    int i, index = 0;
    // 最もタップパワーの大きい部位を検索
    for (i = 0; i < speedometers.length; i++) {
      float power = speedometers[i].power();
      if (powerMax < power) {
        result_power = powerMax = power;
        index = i;
      }
    }
    
    // 最もタップパワーの大きい部位 = 更新されたタップ履歴 だった場合ビートを計算
    if (powerMax > 0) {
      float sumSeconds = 0;
      int summedSecondsNumber = 0;
      boolean lastTapIsTesting = true;
      boolean lastTapIsValid = false;
      
      ListIterator<Float> itr = speedometers[index].tapQueue().listIterator(0);
      while (itr.hasNext()) {
        // 現在のビートから変化量が極端なタップは無視して集計を行う
        float tap_SPB = itr.next().floatValue();
        float SPBvariant = tap_SPB / (60 / sound.getBPM());
        if (th_SPB_variant_max >= SPBvariant && SPBvariant >= th_SPB_variant_min) {
          sumSeconds += tap_SPB;
          summedSecondsNumber++;
          if (lastTapIsTesting) { lastTapIsValid = true; }
        }
        lastTapIsTesting = false;
      }
      if (summedSecondsNumber > 0) {
        result_secondsPerBeat = sumSeconds / (float)summedSecondsNumber;
        if (lastTapIsValid) {
          previousBeatTime = time;
          controller.tapped(userId, this);
        }
      }
    }
  }
  
  // -----------------------------------------------------
  
  // ビート(secondsPerBeat)を取得
  float getBeats() {
    return result_secondsPerBeat;
  }
  
  // パワーを取得
  float getPower() {
    return result_power;
  }
  
  // -----------------------------------------------------
  DebugGraph graph;
  
  PVector centerVector;
  float pointsZoom;
  color originalUserColor, currentUserColor;
  
  void initVisual(color userColor) {
    centerVector = new PVector();
    originalUserColor = userColor;
  }
  
  void updateVisual() {
    float elapsedTime = getTime() - previousBeatTime;
    pointsZoom = 0.1 - elapsedTime;
    if (elapsedTime < 0.1) {
      currentUserColor = lerpColor(whiteColor, originalUserColor, elapsedTime / 0.4);
    } else {
      currentUserColor = originalUserColor;
    }
    context.getCoM(userId, centerVector);
  }
  
  color getUserColor() {
    return currentUserColor;
  }
  
  PVector movePoint(PVector in) {
    if (pointsZoom > 0) {
      float zoom = pointsZoom + 1.0;
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
