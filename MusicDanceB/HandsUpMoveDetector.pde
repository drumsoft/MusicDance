import SimpleOpenNI.*;

class HandsUpMoveDetector extends MoveDetector {
  float result_max_variance = 0.03; // 1フレームに結果が変化できる最大の量
  
  HandsUpMoveDetector(int uid, SimpleOpenNI c, MusicDanceB a_controller) {
    super(uid, c, a_controller);
  }
  
  void setMoveParts(int[][] parts) {
    super.setMoveParts(parts);
  }
  
  // 更新 - 最小のハンズアップ度を全体のハンズアップ度にする
  void update() {
    float minHandsUp = 10000;
    for (int i = 0; i < moveParts.length; i++) {
      float handsUp = movePartsHandsUpFactor(moveParts[i][0], moveParts[i][1]);
      if (handsUp != 0 && minHandsUp > handsUp) {
        minHandsUp = handsUp;
      }
    }
    if ( minHandsUp != 10000 ) {
      resultValue = Math.max(Math.min(minHandsUp, resultValue + result_max_variance), resultValue - result_max_variance);;
    }
  }
  
  // -----------------------------------------------------
  
  // パーツ元からパーツ先のハンズアップ度(腕の向きの、y軸成分と長さの比)
  float movePartsHandsUpFactor(int partA, int partB) {
    PVector pa = new PVector();
    PVector pb = new PVector();
    float confidenceA, confidenceB;
    confidenceA = context.getJointPositionSkeleton(userId, partA, pa);
    confidenceB = context.getJointPositionSkeleton(userId, partB, pb);
    if (confidenceA < 0.3 || confidenceB < 0.3) {
      return 0;
    }
    float dx = pb.x - pa.x;
    float dy = pb.y - pa.y;
    float dz = pb.z - pa.z;
    return dy / (float)Math.sqrt(dx*dx + dy*dy + dz*dz);
  }
}
