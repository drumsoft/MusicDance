import oscP5.*;
import netP5.*;
import SimpleOpenNI.*;

class OscAgent {
  private static final String OSCAddress_skel = "skel";
  private static final String OSCAddress_new_user = "new_user";
  private static final String OSCAddress_calib_success = "calib_success";
  private static final String OSCAddress_lost_user = "lost_user";
  
  String[] maxJoints = {
    "head",
    "l_elbow",
    "l_hand_tip",
    "l_foot",
    "l_hand",
    "l_hip",
    "l_knee",
    "l_shoulder",
    "neck",
    "r_elbow",
    "r_hand_tip",
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
    "waist"
  };
  int[] nativeJoints = {
    SimpleOpenNI.SKEL_HEAD,
    SimpleOpenNI.SKEL_LEFT_ELBOW,
    SimpleOpenNI.SKEL_LEFT_FINGERTIP,
    SimpleOpenNI.SKEL_LEFT_FOOT,
    SimpleOpenNI.SKEL_LEFT_HAND,
    SimpleOpenNI.SKEL_LEFT_HIP,
    SimpleOpenNI.SKEL_LEFT_KNEE,
    SimpleOpenNI.SKEL_LEFT_SHOULDER,
    SimpleOpenNI.SKEL_NECK,
    SimpleOpenNI.SKEL_RIGHT_ELBOW,
    SimpleOpenNI.SKEL_RIGHT_FINGERTIP,
    SimpleOpenNI.SKEL_RIGHT_FOOT,
    SimpleOpenNI.SKEL_RIGHT_HAND,
    SimpleOpenNI.SKEL_RIGHT_HIP,
    SimpleOpenNI.SKEL_RIGHT_KNEE,
    SimpleOpenNI.SKEL_RIGHT_SHOULDER,
    SimpleOpenNI.SKEL_TORSO
  };
  
  Map<String, Integer> nativeJointFromMaxJoint;
  String[] maxJointFromNativeJoint;
  
  OscP5 oscP5;
  NetAddress sendAddress;
  
  OscAgent(int recievePort, String sendHost, int sendPort) {
    oscP5 = new OscP5(this, recievePort);
    sendAddress = new NetAddress(sendHost, sendPort);
    
    int maxOfNativeJoints = 0;
    for (int i = 0; i < nativeJoints.length; i++) {
      maxOfNativeJoints = Math.max(maxOfNativeJoints, nativeJoints[i]);
    }
    maxJointFromNativeJoint = new String[maxOfNativeJoints + 1];
    for (int i = 0; i < maxOfNativeJoints + 1; i++) {
      maxJointFromNativeJoint[i] = null;
    }
    for (int i = 0; i < nativeJoints.length; i++) {
      maxJointFromNativeJoint[nativeJoints[i]] = maxJoints[i];
    }
    
    nativeJointFromMaxJoint = new HashMap<String, Integer>();
    for (int i = 0; i < maxJoints.length; i++) {
      if (i < nativeJoints.length) {
        nativeJointFromMaxJoint.put(maxJoints[i], new Integer(nativeJoints[i]));
      } else {
        nativeJointFromMaxJoint.put(maxJoints[i], null);
      }
    }
  }
  
  void send(SimpleOpenNI context) {
    OscMessage message = new OscMessage(OSCAddress_skel);
    int userId = 0;
    float[] bonePoints = new float[4];
    PVector point = new PVector();
    float confidence;
    
    int[] userList = context.getUsers();
    for (int i = 0; i < userList.length; i++) {
      userId = userList[i];
      if(context.isTrackingSkeleton(userId)) {
        for (int j = 0; j < nativeJoints.length; j++) {
          message.setAddrPattern(OSCAddress_skel);
          message.add(userId);
          message.add(maxJointFromNativeJoint[nativeJoints[j]]);
          confidence = context.getJointPositionSkeleton(userId, nativeJoints[j], point);
          bonePoints[0] = point.x;
          bonePoints[1] = point.y;
          bonePoints[2] = point.z;
          bonePoints[3] = confidence;
          message.add(bonePoints);
          oscP5.send(message, sendAddress);
          message.clear();
        }
      }
    }
  }
  
  void sendNewUser(int userId) {
    OscMessage message = new OscMessage(OSCAddress_new_user);
    message.add(userId);
    oscP5.send(message, sendAddress);
    message.clear();
    message.setAddrPattern(OSCAddress_calib_success);
    message.add(userId);
    oscP5.send(message, sendAddress);
  }
  
  void sendLostUser(int userId) {
    OscMessage message = new OscMessage(OSCAddress_lost_user);
    message.add(userId);
    oscP5.send(message, sendAddress);
  }
  
  void oscEvent(OscMessage theOscMessage) {
    print("[osc] addrpattern: "+theOscMessage.addrPattern());
    println(" typetag: "+theOscMessage.get(0).intValue());
  }
}
