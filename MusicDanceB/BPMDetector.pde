import SimpleOpenNI.*;
import java.util.LinkedList;
import java.util.ListIterator;

class BPMDetector {
  int tap_queue_length = 16; // 貯めるタップ回数
  float th_confidence = 0.3; // 入力値を採用する最小の confidence
  float th_speed_lowest = 100; // 動きとして判断する最小のピクセル数/秒
  int[] pointsToReadBPM = { // BPMの読み込みに使うSkelton上のポイント設定
    SimpleOpenNI.SKEL_LEFT_HIP, 
    SimpleOpenNI.SKEL_LEFT_KNEE,
    //SimpleOpenNI.SKEL_LEFT_FOOT,
    SimpleOpenNI.SKEL_RIGHT_HIP,
    SimpleOpenNI.SKEL_RIGHT_KNEE
    //SimpleOpenNI.SKEL_RIGHT_FOOT
  };
  float th_SPB_variant_max = 1.2; // これ以上に早くなる場合は無視する
  float th_SPB_variant_min = 0.8; // これ以下に遅くなる場合は無視する
  
  SimpleOpenNI context;
  MusicDanceB controller;
  int userId;
  float[] pointsPreviousSpeed; // 各点の速度(前回のを保存)
  float[] pointsPreviousPosition; // 各点の位置(前回のを保存)
  float[] previousTime; // 前回の判定時刻
  LinkedList<Float>[] tap_queue; // 部位ごとの配列: タップ時刻の履歴 [前回, 前々回, ..]
  float[] tap_previous_time; // 部位ごとの前回タップされた時刻
  float[] tap_power; // 部位ごとのタップされた強度
  float result_secondsPerBeat; // 現在検出しているビート(秒/ビート)
  float summed_power; // これまでのパワー積算
  float result_power; // 現在のパワー
  
  BPMDetector(int uid, SimpleOpenNI c, MusicDanceB a_controller, float time) {
    userId = uid;
    context = c;
    controller = a_controller;
    previousTime = new float[pointsToReadBPM.length];
    for (int i = 0; i < previousTime.length; i++) {
      previousTime[i] = time;
    }
    pointsPreviousSpeed = new float[pointsToReadBPM.length];
    pointsPreviousPosition = new float[pointsToReadBPM.length];
    
    tap_queue = new LinkedList[pointsToReadBPM.length];
    for (int i = 0; i < pointsToReadBPM.length; i++) {
      tap_queue[i] = new LinkedList<Float>();
    }
    tap_previous_time = new float[pointsToReadBPM.length];
    tap_power = new float[pointsToReadBPM.length];
  }
  
  void fetchPositionData(float currentTime) {
    for (int i = 0; i < pointsToReadBPM.length; i++) {
      PVector jointPos1 = new PVector();
      float confidence; // 0.0〜1.0
      confidence = context.getJointPositionSkeleton(userId, pointsToReadBPM[i], jointPos1);
      
      float currentPosition = jointPos1.y;
      if (confidence > th_confidence) { // confidence が閾値を超えている
        float currentSpeed = (currentPosition - pointsPreviousPosition[i]) / (currentTime - previousTime[i]);
        if (Math.abs(currentSpeed) > th_speed_lowest) { // 速度が閾値を超えている
          if (currentSpeed < 0 && pointsPreviousSpeed[i] >= 0) { // 下のピークが来た。
            tapTheBeat(i, currentTime, -currentSpeed + pointsPreviousSpeed[i]);
            updateBeats(i, currentTime);
          }
          // if (currentSpeed > 0 && pointsPreviousSpeed[i] =< 0) { // 上のピークが来た。
          // }
          pointsPreviousSpeed[i] = currentSpeed;
        }
        pointsPreviousPosition[i] = currentPosition;
      }
      previousTime[i] = currentTime;
    }
  }
  
  // タップする (index, 時刻, タップ強度)
  void tapTheBeat(int index, float time, float power) {
    tap_queue[index].addFirst(new Float(time - tap_previous_time[index]));
    while (tap_queue[index].size() > tap_queue_length) {
      tap_queue[index].removeLast();
    }
    tap_previous_time[index] = time;
    tap_power[index] = power;
  }
  
  // タップ履歴を検証して、有効なタップならビートを更新し、タップ検出コールバックを行う
  void updateBeats(int updatedIndex, float time) {
    float powerMax = 0;
    int i, index = 0;
print("updateBeats: ");
for (i = 0; i < tap_power.length; i++) {
  print("  " + Float.toString(tap_power[i]));
}
println("");
    // 最もタップパワーの大きい部位を検索
    for (i = 0; i < pointsToReadBPM.length; i++) {
ListIterator<Float> _itr = tap_queue[index].listIterator(0);
print("   Tapped: " + i);
while (_itr.hasNext()) {
  print("  " + Float.toString(_itr.next().floatValue()));
}
println("");
      if (powerMax <= tap_power[i]) {
        result_power = powerMax = tap_power[i];
        index = i;
        break;
      }
    }
    
    // 最もタップパワーの大きい部位 = 更新されたタップ履歴 だった場合ビートを計算
    if (updatedIndex == index) {
      float sumSeconds = 0;
      int summedSecondsNumber = 0;
      
      ListIterator<Float> itr = tap_queue[index].listIterator(0);
      while (itr.hasNext()) {
        // 現在のビートから変化量が極端なタップは無視して集計を行う
        float tap_SPB = itr.next().floatValue();
        float SPBvariant = tap_SPB / result_secondsPerBeat;
        if (th_SPB_variant_max >= SPBvariant && SPBvariant >= th_SPB_variant_min) {
          sumSeconds += tap_SPB;
          summedSecondsNumber++;
        }
      }
      if (summedSecondsNumber > 0) {
        result_secondsPerBeat = sumSeconds / summedSecondsNumber;
      }
      controller.tapped(userId, this);
    }
  }
  
  // ビート(secondsPerBeat)を取得
  float getBeats() {
    return result_secondsPerBeat;
  }
  
  // パワーを取得
  float getPower() {
    return result_power;
  }
}
