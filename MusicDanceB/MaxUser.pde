class MaxUser {
  float zoom = 2800.0;
  PVector origin = new PVector(0, -1000, 3000);
  int lifeMax = 100;
  
  String[] jointLabels = {
    "head",
    "l_elbow",
    "l_foot",
    "l_hand",
    "l_hip",
    "l_knee",
    "l_shoulder",
    "neck",
    "r_elbow",
    "r_foot",
    "r_hand",
    "r_hip",
    "r_knee",
    "r_shoulder",
    "torso",
    "c_shoulder",
    "l_ankle",
    "l_thumb",
    "l_wrist",
    "r_ankle",
    "r_thumb",
    "r_wrist",
    "waist",
    "l_hand_tip",
    "r_hand_tip"
  };
  
  String[] boneLabels = {
    "head", "neck",
    "neck", "c_shoulder",
    "c_shoulder", "torso",
    "torso", "waist",
    "c_shoulder", "l_shoulder",
    "c_shoulder", "r_shoulder",
    "l_shoulder", "l_elbow",
    "r_shoulder", "r_elbow",
    "l_elbow", "l_wrist",
    "r_elbow", "r_wrist",
    "l_wrist", "l_hand",
    "r_wrist", "r_hand",
    "l_hand", "l_hand_tip",
    "r_hand", "r_hand_tip",
    "l_hand", "l_thumb",
    "r_hand", "r_thumb"
  };
  
  Map<String, Integer> jointIndexFromLabel;
  int[][] boneIndexes;
  PVector[] joints;
  int userId;
  int life;
  
  MaxUser(int userId) {
    this.userId = userId;
    
    joints = new PVector[jointLabels.length];
    jointIndexFromLabel = new HashMap<String, Integer>();
    for (int i = 0; i < jointLabels.length; i++) {
      jointIndexFromLabel.put(jointLabels[i], new Integer(i));
      joints[i] = new PVector(0, 0, 0);
    }
    
    boneIndexes = new int[boneLabels.length / 2][];
    for (int i = 0; i < boneLabels.length; i += 2) {
      int[] bone = new int[2];
      bone[0] = jointIndexFromLabel.get(boneLabels[i+0]).intValue();
      bone[1] = jointIndexFromLabel.get(boneLabels[i+1]).intValue();
      boneIndexes[i / 2] = bone;
    }
    
    life = lifeMax;
  }
  
  void draw() {
    if (life <= 0) return;
    stroke(170, 170, 170, 255 * life / lifeMax);
    
    PVector w = joints[jointIndexFromLabel.get("waist").intValue()];
    float offsetX = - w.x + origin.x;
    float offsetY = - w.y + origin.y;
    float offsetZ = - w.z + origin.z;
    
    for (int i = 0; i < boneIndexes.length; i++) {
      PVector f = joints[boneIndexes[i][0]];
      PVector t = joints[boneIndexes[i][1]];
      line(f.x + offsetX, f.y + offsetY, f.z + offsetZ, 
           t.x + offsetX, t.y + offsetY, t.z + offsetZ);
    }
    life--;
  }
  
  void setSkel(String jointLabel, float x, float y, float z) {
    int jointIndex = jointIndexFromLabel.get(jointLabel).intValue();
    joints[jointIndex].x = zoom * x;
    joints[jointIndex].y = zoom * y;
    joints[jointIndex].z = zoom * z;
    life = lifeMax;
  }
  
  int life() {
    return life;
  }
}
