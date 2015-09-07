import oscP5.*;
import netP5.*;
import SimpleOpenNI.*;

class OscAgent {
  private static final int maxUsersSendTo = 6;
  private static final String OSCAddress_skel = "skel";
  private static final String OSCAddress_user = "user";
  private static final String OSCAddress_color = "color";
  private static final String OSCAddress_userlist = "list";
  private static final String OSCAddress_userstatus = "userstatus";
  private static final String OSCAddress_weight = "weight";
  
  String[] maxJoints = {
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
  int[] nativeJoints = {
    SimpleOpenNI.SKEL_HEAD,
    SimpleOpenNI.SKEL_LEFT_ELBOW,
    SimpleOpenNI.SKEL_LEFT_FOOT,
    SimpleOpenNI.SKEL_LEFT_HAND,
    SimpleOpenNI.SKEL_LEFT_HIP,
    SimpleOpenNI.SKEL_LEFT_KNEE,
    SimpleOpenNI.SKEL_LEFT_SHOULDER,
    SimpleOpenNI.SKEL_NECK,
    SimpleOpenNI.SKEL_RIGHT_ELBOW,
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
    PVector point = new PVector();
    float confidence;
    
    int[] userList = context.getUsers();
    // pickup first maxUsersSendTo users
    int[] userIds = new int[maxUsersSendTo];
    int userIdx = 0, userNumber = 0;
    for (int i = 0; i < userList.length; i++) {
      if(context.isTrackingSkeleton(userList[i])) {
        userIds[userIdx++] = userList[i];
        if (userIdx == maxUsersSendTo) break;
      }
    }
    userNumber = userIdx;
    while (userIdx < maxUsersSendTo) {
      userIds[userIdx++] = 0;
    }
    // userlist
    message.setAddrPattern(OSCAddress_userlist);
    message.add(userNumber);
    message.add(userIds);
    oscP5.send(message, sendAddress);
    message.clear();
    for (int i = 0; i < userNumber; i++) {
      userId = userIds[i];
      Dancer dancer = getDancer(userId);
      if (context.getCoM(userId, point)) {
        // user
        message.setAddrPattern(OSCAddress_user);
        message.add(userId);
        message.add(point.x);
        message.add(point.y);
        message.add(point.z);
        message.add(0);
        oscP5.send(message, sendAddress);
        message.clear();
      }
      // color
      color userColor = dancer.getUserColor();
      message.setAddrPattern(OSCAddress_color);
      message.add(userId);
      message.add(red(userColor) / 255);
      message.add(green(userColor) / 255);
      message.add(blue(userColor) / 255);
      oscP5.send(message, sendAddress);
      message.clear();
      // userstatus
      message.setAddrPattern(OSCAddress_userstatus);
      message.add(userId);
      message.add(dancer.getSmoothBPM());
      message.add(dancer.getStrictness());
      oscP5.send(message, sendAddress);
      message.clear();
      for (int j = 0; j < nativeJoints.length; j++) {
        // skel
        message.setAddrPattern(OSCAddress_skel);
        message.add(userId);
        message.add(maxJointFromNativeJoint[nativeJoints[j]]);
        confidence = context.getJointPositionSkeleton(userId, nativeJoints[j], point);
        message.add(point.x);
        message.add(point.y);
        message.add(point.z);
        message.add(confidence);
        oscP5.send(message, sendAddress);
        message.clear();
      }
    }
  }
  
  MaxUser maxUser = null;
  
  void oscEvent(OscMessage theOscMessage) {
    String addr = theOscMessage.addrPattern();
    if (addr.equals(OSCAddress_skel)) {
      // ['skel', 'i',USER_ID, 's','SKEL_PART', 'f','X', 'f','Y', 'f','Z', 'f','CONFIDENCE']
      int userId = theOscMessage.get(0).intValue();
      if (maxUser != null && maxUser.life() <= 0) {
          maxUser = null;
      }
      if (maxUser == null) {
        maxUser = new MaxUser(userId);
      }
      if (maxUser.userId == userId) {
        maxUser.setSkel(
          theOscMessage.get(1).stringValue(),
          theOscMessage.get(2).floatValue(),
          theOscMessage.get(3).floatValue(),
          theOscMessage.get(4).floatValue()
        );
      }
    } else if (addr.equals(OSCAddress_weight)) {
      int userId = theOscMessage.get(0).intValue();
      Dancer dancer = getDancer(userId);
      if (dancer != null) {
        dancer.setWeight(theOscMessage.get(1).floatValue());
      }
    }
  }
  
  void drawMaxUser() {
    if (maxUser != null) {
      maxUser.draw();
    }
  }
}
