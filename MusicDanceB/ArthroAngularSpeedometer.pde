import SimpleOpenNI.*;
import java.util.LinkedList;
import java.util.ListIterator;

class ArthroAngularSpeedometer {
  int tap_queue_length = 16; // 貯めるタップ回数
  float th_confidence = 0.3; // 入力値を採用する最小の confidence
  float th_speed_lowest = 0.75; // 動きとして判断する最小の曲げ角速度/秒
  float speedAmplifer;
  
  int userId;
  SimpleOpenNI context;
  int jointP, jointA, jointB;
  
  float previousSpeed; // 各点の速度(前回のを保存)
  float previousValidSpeed; // 前回の有効な(大きさが th_speed_lowest を超えた)速度
  
  MoveFilterBase filter1; // ノイズのフィルタ
  MoveFilterBase filter2; // 
  
  float previousBeatTime; // 前回ビートとして判定した時刻
  LinkedList<Float> tap_queue; // タップ時刻の履歴 [前回, 前々回, ..]
  float tap_previous_time; // 前回タップされた時刻
  float tap_power; // タップされた強度
  
  ArthroAngularSpeedometer(int uid, SimpleOpenNI c, float jointSpeedAmp, int[] jointDirective, float currentTime, MoveFilterBase f1, MoveFilterBase f2) {
    filter1 = f1;
    filter2 = f2;
    
    userId = uid;
    context = c;
    speedAmplifer = jointSpeedAmp;
    jointP = jointDirective[0];
    jointA = jointDirective[1];
    jointB = jointDirective[2];
    
    previousSpeed = 0;
    
    tap_queue = new LinkedList<Float>();
    tap_previous_time = 0;
    tap_power = 0;
  }
  
  // 関節(PA,PB)の曲げ深さ(-1〜1.0 = cosAPB)を返す confidence が不足している場合等求められない場合はNaNを返す
  float getJointBendingDepth() {
    // 関節(PA,PB)の各点 P, A, B を取得
    PVector p = new PVector(), a = new PVector(), b = new PVector();
    float confP = context.getJointPositionSkeleton(userId, jointP, p);
    if (confP < th_confidence) return Float.NaN;
    float confA = context.getJointPositionSkeleton(userId, jointA, a);
    if (confA < th_confidence) return Float.NaN;
    float xPA = a.x - p.x, yPA = a.y - p.y, zPA = a.z - p.z;
    float lengthPA2 = xPA * xPA + yPA * yPA + zPA * zPA;
    if (lengthPA2 == 0) {
      return Float.NaN;
    }
    float confB = context.getJointPositionSkeleton(userId, jointB, b);
    if (confB < th_confidence) return Float.NaN;
    float xPB = b.x - p.x, yPB = b.y - p.y, zPB = b.z - p.z;
    float lengthPB2 = xPB * xPB + yPB * yPB + zPB * zPB;
    if (lengthPB2 == 0) {
      return Float.NaN;
    }
    // 内積と長さ(の2乗)から APB (radian) を計算
    float innerProduct = xPA * xPB + yPA * yPB + zPA * zPB;
    return (float)Math.acos( innerProduct / (Math.sqrt(lengthPA2) * Math.sqrt(lengthPB2)) );
  }
  
  boolean update(float currentTime) {
    boolean isTapped = false;
    float currentPosition = getJointBendingDepth();
    if (!Float.isNaN(currentPosition)) { // 曲げ深さが有効
      currentPosition = filter1.input(filter2.input(currentPosition, currentTime), currentTime);
//      if (jointP == SimpleOpenNI.SKEL_NECK) {
//        addDataToGraph(userId, 0, currentPosition * 2); // yellow
//      }
      float currentSpeed = speedAmplifer * currentPosition;
      if (Math.abs(currentSpeed) > th_speed_lowest) { // 速度が閾値を超えている
        if (currentSpeed < 0 && previousValidSpeed >= 0) { // 下のピークが来た。
          tapTheBeat(currentTime, -currentSpeed + previousValidSpeed);
          isTapped = true;
        }
        previousValidSpeed = currentSpeed; // 速度が閾値を超えた場合のみ更新する
        // if (currentSpeed > 0 && previousSpeed =< 0) { // 上のピークが来た。
        // }
      }
      previousSpeed = currentSpeed;
    }
    return isTapped;
  }
  
  // 部位内タップを登録 (時刻, タップ強度)
  void tapTheBeat(float time, float power) {
    tap_queue.addFirst(new Float(time - tap_previous_time));
    while (tap_queue.size() > tap_queue_length) {
      tap_queue.removeLast();
    }
    tap_previous_time = time;
    tap_power = power;
  }
  
  float speed() { return previousSpeed; }
  float power() { return tap_power; }
  LinkedList<Float> tapQueue() { return tap_queue; }
}
