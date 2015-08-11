import oscP5.*;
import netP5.*;
import SimpleOpenNI.*;

class OscAgent {
  private static final String boneOSCAddress = "/bone";
  private final int[] joints = { // Order of joints to serialize
    SimpleOpenNI.SKEL_HEAD,
    SimpleOpenNI.SKEL_NECK,
    SimpleOpenNI.SKEL_TORSO,
    SimpleOpenNI.SKEL_LEFT_SHOULDER,
    SimpleOpenNI.SKEL_LEFT_ELBOW,
    SimpleOpenNI.SKEL_LEFT_HAND,
    SimpleOpenNI.SKEL_LEFT_FINGERTIP,
    SimpleOpenNI.SKEL_RIGHT_SHOULDER,
    SimpleOpenNI.SKEL_RIGHT_ELBOW,
    SimpleOpenNI.SKEL_RIGHT_HAND,
    SimpleOpenNI.SKEL_RIGHT_FINGERTIP,
    SimpleOpenNI.SKEL_LEFT_HIP,
    SimpleOpenNI.SKEL_LEFT_KNEE,
    SimpleOpenNI.SKEL_LEFT_FOOT,
    SimpleOpenNI.SKEL_RIGHT_HIP,
    SimpleOpenNI.SKEL_RIGHT_KNEE,
    SimpleOpenNI.SKEL_RIGHT_FOOT
  };
  
  OscP5 oscP5;
  NetAddress sendAddress;
  
  OscAgent(int recievePort, String sendHost, int sendPort) {
    oscP5 = new OscP5(this, recievePort);
    sendAddress = new NetAddress(sendHost, sendPort);
  }
  
  void send(SimpleOpenNI context) {
    OscBundle bundle = new OscBundle();
    OscMessage boneMessage = new OscMessage(boneOSCAddress);
    
    int userId = 0;
    float[] bonePoints = new float[joints.length * 4];
    PVector point = new PVector();
    float confidence;
    
    int[] userList = context.getUsers();
    for (int i = 0; i < userList.length; i++) {
      userId = userList[i];
      if(context.isTrackingSkeleton(userId)) {
        for (int j = 0; j < joints.length; j++) {
          confidence = context.getJointPositionSkeleton(userId, joints[j], point);
          bonePoints[j * 4 + 0] = point.x;
          bonePoints[j * 4 + 1] = point.y;
          bonePoints[j * 4 + 2] = point.z;
          bonePoints[j * 4 + 3] = confidence;
        }
        boneMessage.setAddrPattern(boneOSCAddress);
        boneMessage.add(userId);
        boneMessage.add(bonePoints);
        bundle.add(boneMessage);
        boneMessage.clear();
      }
    }
    
    if (bundle.size() > 0) {
      oscP5.send(bundle, sendAddress);
    }
  }
  
  void oscEvent(OscMessage theOscMessage) {
    print("[osc] addrpattern: "+theOscMessage.addrPattern());
    println(" typetag: "+theOscMessage.get(0).intValue());
  }
}
