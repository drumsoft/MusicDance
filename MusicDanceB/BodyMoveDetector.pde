import SimpleOpenNI.*;

class BodyMoveDetector extends MoveDetector {
  float previousTime;
  PVector[] previousVector;
  MoveFilterLPF[] fLPFs;

  float th_confidence = 0.3;
  
  BodyMoveDetector(int uid, SimpleOpenNI c, MusicDanceB a_controller, float time) {
    super(uid, c, a_controller);
    previousTime = time;
  }
  
  void setMoveParts(int[][] parts) {
    super.setMoveParts(parts);
    previousVector = new PVector[moveParts.length];
    fLPFs = new MoveFilterLPF[moveParts.length];
    for (int i = 0; i < moveParts.length; i++) {
      fLPFs[i] = new MoveFilterLPF(3.8, 1, 28); // cutoff(hz), Q, samplingrate(hz)
    }
  }
  
  // 更新 - 最高の相対速度を全体の相対速度にする
  void updateWithTime(float time) {
    float maxSpeed = 0;
    float timeElapsed = time - previousTime;
    if (timeElapsed == 0) return;
    for (int i = 0; i < moveParts.length; i++) {
      float speed = fLPFs[i].input(movePartDistance2(i, moveParts[i][0], moveParts[i][1]) / timeElapsed, time);
      if (maxSpeed < speed) {
        maxSpeed = speed;
      }
    }
    resultValue = maxSpeed;
    previousTime = time;
  }
  
  // -----------------------------------------------------
  
  // パーツ元からパーツ先の、相対移動量
  float movePartDistance2(int i, int partA, int partB) {
    PVector pa = new PVector();
    PVector pb = new PVector();
    float confidenceA = context.getJointPositionSkeleton(userId, partA, pa);
    float confidenceB = context.getJointPositionSkeleton(userId, partB, pb);
    PVector currentVector = new PVector(pb.x - pa.x, pb.y - pa.y, pb.z - pa.z);
    if (confidenceA < th_confidence || confidenceB < th_confidence || null == previousVector[i]) {
      previousVector[i] = currentVector;
      return 0;
    }
    float dx = currentVector.x - previousVector[i].x;
    float dy = currentVector.y - previousVector[i].y;
    float dz = currentVector.z - previousVector[i].z;
    previousVector[i] = currentVector;
    return (float)Math.sqrt(dx*dx + dy*dy + dz*dz);
  }
}
