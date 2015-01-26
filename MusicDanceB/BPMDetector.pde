import SimpleOpenNI.*;
import java.util.LinkedList;
import java.util.ListIterator;

class BPMDetector {
  int movingAverageWidth = 5; // 位置の移動平均値
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
    { SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_HAND }, // 右肘
//    { SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_TORSO }, // 頭(ヘドバン)
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
      speedometers[i] = new ArthroAngularSpeedometer(userId, context, jointsSpeedAmp[i],  jointsToReadBPM[i], movingAverageWidth, currentTime);
    }
  }
  
  void fetchPositionData(float currentTime) {
    boolean isTapped = false;
    for (int i = 0; i < speedometers.length; i++) {
      if (speedometers[i].update(currentTime)) {
        isTapped = true;
      }
    }
    if (isTapped) {
      updateBeats(currentTime);
    }
    
    for (int i = 0; i < speedometers.length; i++) {
      print("  " + Float.toString(speedometers[i].speed()));
    }
    println("");
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
  
  float base_y, pointsZoom;
  int color_b;
  LinkedList<Float>[] yList; // 部位ごとの速度の配列
  
  void setY(float y) {
    base_y = y;
    color_b = (int)Math.min(Math.abs(y), 255);
    yList = new LinkedList[jointsToReadBPM.length];
    for (int i = 0; i < jointsToReadBPM.length; i++) {
      yList[i] = new LinkedList<Float>();
    }
    centerVector = new PVector();
  }
  
  void drawSpeed() {
    pushMatrix();
    stroke(255, 255, 255);
    line(uiDisplayLeft, base_y, 0, uiDisplayLeft+uiDisplayWidth, base_y, 0);
    stroke(200, 200, 200);
    float th_y = 1 / 10.0;
    line(uiDisplayLeft, base_y+th_y, 0, uiDisplayLeft+uiDisplayWidth, base_y+th_y, 0);
    line(uiDisplayLeft, base_y-th_y, 0, uiDisplayLeft+uiDisplayWidth, base_y-th_y, 0);
    
    for (int i = 0; i < yList.length; i++) {
      yList[i].addFirst(speedometers[i].speed() * 10.0 + base_y);
      while (yList[i].size() > 90) {
        yList[i].removeLast();
      }
      
      int color_r = Math.min(255, (int)(speedometers[i].power() / 4.0) + 100);
      stroke(color_r, 255, color_b);
      
      float px = width, py = yList[i].getFirst();
      int number, xIndex;
      number = xIndex = yList[i].size() - 1;
      if (number > 0) {
        ListIterator<Float> itr = yList[i].listIterator(0);
        while (itr.hasNext()) {
          float x = uiDisplayLeft + (uiDisplayWidth * xIndex / number);
          float y = itr.next().intValue();
          line(px,py,0, x,y,0);
          px = x; py = y;
          xIndex--;
        }
      }
    }
    popMatrix();
    updateUserColor(getTime());
    context.getCoM(userId, centerVector);
  }
  
  color originalUserColor, currentUserColor;
  PVector centerVector;
  
  void setUserColor(color c) {
    originalUserColor = c;
  }
  
  void updateUserColor(float currentTime) {
    float elapsedTime = currentTime - previousBeatTime;
    pointsZoom = 0.1 - elapsedTime;
    if (elapsedTime < 0.1) {
      currentUserColor = lerpColor(whiteColor, originalUserColor, elapsedTime / 0.4);
    } else {
      currentUserColor = originalUserColor;
    }
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
