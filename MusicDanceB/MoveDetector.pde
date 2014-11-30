import SimpleOpenNI.*;

class MoveDetector {
  int userId;
  SimpleOpenNI context;
  MusicDanceB controller;
  int[][] moveParts;
  float resultValue;
  
  MoveDetector(int uid, SimpleOpenNI c, MusicDanceB a_controller) {
    userId = uid;
    context = c;
    controller = a_controller;
    
    resultValue = 0;
  }
  
  void setMoveParts(int[][] parts) {
    moveParts = parts;
  }
  
  void update() {
  }
  
  float getValue() {
    return resultValue;
  }
}
