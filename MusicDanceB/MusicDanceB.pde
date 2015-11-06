// Music Dance (Japan Party Party)
// based on SimpleOpenNI User3d Test http://code.google.com/p/simple-openni by Max Rheiner / Interaction Design / Zhdk / http://iad.zhdk.ch/ 12/12/2012

// processing-java --run --sketch=/Users/hrk/projects/MusicDance/git/MusicDanceB/ --output=../output --force

import SimpleOpenNI.*;
import java.util.*;
import java.util.Map.Entry;
import java.util.Timer;
import java.util.TimerTask;

static final int MODE_DEMO = 0;
static final int MODE_RECORD = 1;
static final int MODE_PLAYBACK = 2;
static final int MODE_PLAYBACK_STILL = 3;

static final int ZOOM_MODE_DEFAULT = 0; // fov angle 60 -> 45
static final int ZOOM_MODE_WIDTH = 1; // fit to width
static final int ZOOM_MODE_HEIGHT = 2; // fit to height
static final int ZOOM_MODE_NOZOOM = 3; // 1:1

static final String pathToStoreStill = "depthMap.json";
static final String pathToStoreMovie = "SkeletonRec.oni";

static final int graph_series = 5;
static final int[] graph_series_colors = {#7777FF,#dd7777,#FF00FF,#00FF00,#00FFFF,#FFFF00,#FFFFFF};

PApplet theApplet;
Preferences prefs;
SimpleOpenNI context;
SoundPlayer sound;
OscAgent osc;
ScreenSaver screenSaver;
Presentation presentation;

float        zoomF =0.5f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
                                   // the data from openni comes upside down
float        rotY = radians(0);

PVector      com = new PVector();
color[]     userClr = new color[]{ #85B4C6, #8E88AE, #F2D0AE, #366E81, #B25C88, #8CB284 };
color        whiteColor = color(255,255,255);

DepthMapVisualizer[] depthMapVisualizer = new DepthMapVisualizer[]{
  new DepthMapMeshedWires(),
  new DepthMapContours(),
  //new DepthMapCubes(),
  //new DepthMapPointCloud(),
  new DepthMapRandomWires(),
};
int visualizerIndex = 1;

float uiDisplayLeft, uiDisplayTop, uiDisplayWidth, uiDisplayHeight, uiDisplayZ;

Timer launchCheckTimer;
LaunchChecker launchChecker;
int frameCounter = 0;
float frameCountStart = 0;

void setup()
{
  theApplet = this;
  prefs = new Preferences();
  size(prefs.getInt("screenWidth"), prefs.getInt("screenHeight"), P3D);
  
  String oscSendHost = prefs.get("oscSendHost");
  int oscSendPort = prefs.getInt("oscSendPort");
  int oscRecvPort = prefs.getInt("oscRecvPort");
  int run_mode = prefs.getInt("run_mode");
  int kinectWidth = prefs.getInt("kinectWidth");
  int kinectHeight = prefs.getInt("kinectHeight");
  int zoom_mode = prefs.getInt("zoom_mode");
  
  switch (run_mode) {
    case MODE_DEMO:
    case MODE_RECORD:
      context = new SimpleOpenNI(this);
      break;
    case MODE_PLAYBACK:
      context = new SimpleOpenNI(this, pathToStoreMovie);
      break;
    case MODE_PLAYBACK_STILL:
      context = new DepthMapStore(this);
      ((DepthMapStore)context).load(pathToStoreStill);
      break;
  }
  if(context.isInit() == false) {
    println(" * * * Can't init SimpleOpenNI, maybe the camera is not connected! * * *");
    switch (run_mode) {
      case MODE_DEMO:
      case MODE_RECORD:
        shutdown();
      case MODE_PLAYBACK:
      case MODE_PLAYBACK_STILL:
    }
  }
  
  initMusicDanceSystem();

  // disable mirror
  context.setMirror(true);

  // enable depthMap generation
  //context.enableIR();
  context.enableDepth();

  // enable skeleton generation for all joints
  context.enableUser();

  switch (run_mode) {
    case MODE_RECORD:
      context.enableRecorder(pathToStoreMovie);
      context.addNodeToRecording(SimpleOpenNI.NODE_DEPTH,true);
      //context.addNodeToRecording(SimpleOpenNI.NODE_USER, true);
      //context.addNodeToRecording(SimpleOpenNI.NODE_IR, true);
      break;
  }
  
  float fov_angle;
  switch (zoom_mode) {
    case ZOOM_MODE_WIDTH:
      fov_angle = 2 * atan( tan(radians(60)/2) * kinectWidth / width );
      break;
    case ZOOM_MODE_HEIGHT:
      fov_angle = 2 * atan( tan(radians(60)/2) * kinectHeight / height );
      break;
    case ZOOM_MODE_NOZOOM:
      fov_angle = radians(60);
      break;
    default:
      fov_angle = radians(45);
      break;
  }
  
  stroke(255,255,255);
  smooth();
  perspective(fov_angle,
              float(width)/float(height),
              10,150000);
  
  float sizeRate = tan(fov_angle/2) / tan(radians(60)/2);
  uiDisplayLeft   = width * 0.5 * (1 - sizeRate);
  uiDisplayTop    = height * 0.5 * (1 - sizeRate);
  uiDisplayWidth  = width * sizeRate;
  uiDisplayHeight = height * sizeRate;
  
  for (int i = 0; i < depthMapVisualizer.length; i++) {
    depthMapVisualizer[i].initilize(this, context.depthWidth(), context.depthHeight());
  }
  
  osc = new OscAgent(oscRecvPort, oscSendHost, oscSendPort);
  
  sound = new SoundPlayer(this);
  sound.start();
  
  screenSaver = new ScreenSaver();
  
  float pHeight = uiDisplayHeight * 1.0;
  float pWidth = pHeight * 4 / 3;
  presentation = new Presentation(
    uiDisplayLeft + (uiDisplayWidth - pWidth) / 2, 
    uiDisplayTop + (uiDisplayHeight - pHeight) / 2, 
    pWidth, pHeight);
  
  noCursor();
  
  launchCheckTimer = new Timer();
  launchChecker = new LaunchChecker();
  launchCheckTimer.schedule(launchChecker, 1000);
}

void drawDepthImageMap() {
  pushMatrix();
  scale((float)1024/640);
  image(context.depthImage(),0,0);
  popMatrix();
}

float camera_t = 5;
float cameraZ = 1000;
float cameraX = 0, cameraY = 0, cameraRotX = 0, cameraRotY = 0;
float triWave(float phase) {
  float p = 4 * (phase % 1);
  return p > 2 ? 3 - p : p - 1 ;
}
void moveCamera() {
  float time = getTime();
  float phase = (time % camera_t) / camera_t;
  cameraX = 100 * triWave( phase );
  cameraY = 15 * sin(TWO_PI * phase);
  cameraRotY = (cameraX > 0 ? -1 : 1) * acos( cameraZ / sqrt(cameraX*cameraX + cameraZ*cameraZ) );
  cameraRotX = (cameraY > 0 ? -1 : 1) * acos( cameraZ / sqrt(cameraY*cameraY + cameraZ*cameraZ) );
}

void draw()
{
  updateTime();
  // update the cam
  context.update();
  
  background(0,0,0);
  //drawDepthImageMap();
  
  // set the scene pos
  moveCamera();
  translate(width/2 + cameraX, height/2 + cameraY, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  
  translate(0,0,-cameraZ);  // set the rotation center of the scene 1000 infront of the camera
  rotateX(cameraRotX);
  rotateY(cameraRotY);
  
  // draw user from Max (Body Jockey)
  osc.drawMaxUser();
  
  depthMapVisualizer[visualizerIndex].draw(context.depthMap(), context.depthMapRealWorld(), context.userMap());
  
  float movingScore = 0, handsUpScore = 0;
  float cycleSum = 0, weightSum = 0, maxWeight = 0;
  Dancer topDancer = null;
  
  // draw the skeleton if its available
  int[] userList = context.getUsers();
  for(int i=0;i<userList.length;i++) {
    int userId = userList[i];
    if(context.isTrackingSkeleton(userId)) {
      Dancer dancer = getDancer(userId);
      if (dancer == null || !dancer.active) {
        dancer = startBpmDetecting(userId);
      }
      stroke(lerpColor(#818181, #ff0000, dancer.getStrictness()));
      drawSkeleton(userId);
      
      dancer.update(getTime());
      dancer.updateVisual();
      
      float weight = dancer.getWeight();
      weightSum += weight;
      if (maxWeight < weight) {
        topDancer = dancer;
        maxWeight = weight;
      }
      
      cycleSum += dancer.getCycle() * weight;
      movingScore  += dancer.getBodyMove() * weight;
      handsUpScore += dancer.getHandsUp() * weight;
      
      dancer.drawHeart();
    }
    
    // draw the center of mass
    /*
    if(context.getCoM(userId,com))
    {
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com.x - 15,com.y,com.z);
        vertex(com.x + 15,com.y,com.z);
        
        vertex(com.x,com.y - 15,com.z);
        vertex(com.x,com.y + 15,com.z);

        vertex(com.x,com.y,com.z - 15);
        vertex(com.x,com.y,com.z + 15);
      endShape();
      
      if (context.isTrackingSkeleton(userId)) {
        pushMatrix();
        // text(Integer.toString(userId),com.x,com.y,com.z);
        translate(com.x, com.y, com.z);
        rotateX(rotX);
        textSize(96);
        fill(0,255,100);
        text(Integer.toString( (int)(getBodyMoveDetector(userId).getValue()) ), 0, 40, 0);
        popMatrix();
      }
    }
    */
  }
  
  sound.update(getTime());
  if (weightSum > 0) {
    sound.changeBPM(60 / (cycleSum / weightSum), topDancer.getPhase(), topDancer.getStrictness());
    if (movingScore  > 0) sound.setMoving(movingScore / weightSum);
    if (handsUpScore > 0) sound.setHandsUp(handsUpScore / weightSum);
  }
  
  // draw the kinect cam
  //context.drawCamFrustum();
  
  camera();
  hint(DISABLE_DEPTH_TEST);
  
  drawGraphs();
  
  screenSaver.draw();
  
  hint(ENABLE_DEPTH_TEST);
  
  presentation.draw();
  
  osc.send(context);
  
  frameCounter++;
  if (frameCounter == 100) {
    float currentTime = getTime();
    println("FPS: " + (new Float(frameCounter / (currentTime - frameCountStart))).toString());
    frameCountStart = currentTime;
    frameCounter = 0;
  }
}

// 軸は X(右) Y(上) Z(奥) が正方向, Z軸座標未指定時は z=1 の面に描画
// この時 x, y, は [-width * 0.18, width * 0.18] に
void drawDisplayTests() {
  stroke(255, 255, 0);
  strokeWeight(7);
  float zoom = 0.18;
  float l = -(float)width * zoom, r = (float)width * zoom, 
        t = -(float)height * zoom, b = (float)height * zoom, z = 1;
  line(l, t, z, r, t, z);
  line(r, t, z, r, b, z);
  line(r, b, z, l, b, z);
  line(l, b, z, l, t, z);
  strokeWeight(3);
  stroke(0, 255, 0);
  line(l, t, r, t);
  line(r, t, r, b);
  line(r, b, l, b);
  line(l, b, l, t);
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  strokeWeight(5);

  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  

  //drawBodyDirection(userId);

  strokeWeight(1);
}

void drawBodyDirection(int userId) {
  PVector bodyCenter = new PVector();
  PVector bodyDir = new PVector();
  getBodyDirection(userId,bodyCenter,bodyDir);
  
  bodyDir.mult(200);  // 200mm length
  bodyDir.add(bodyCenter);
  
  stroke(255,200,200);
  line(bodyCenter.x,bodyCenter.y,bodyCenter.z,
       bodyDir.x ,bodyDir.y,bodyDir.z);
}

void drawLimb(int userId,int jointType1,int jointType2)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float  confidence;
  
  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,jointType1,jointPos1);
  confidence = context.getJointPositionSkeleton(userId,jointType2,jointPos2);

  line(jointPos1.x,jointPos1.y,jointPos1.z,
       jointPos2.x,jointPos2.y,jointPos2.z);
  
  //drawJointOrientation(userId,jointType1,jointPos1,50);
}

void drawJointOrientation(int userId,int jointType,PVector pos,float length)
{
  // draw the joint orientation  
  PMatrix3D  orientation = new PMatrix3D();
  float confidence = context.getJointOrientationSkeleton(userId,jointType,orientation);
  if(confidence < 0.001f) 
    // nothing to draw, orientation data is useless
    return;
    
  pushMatrix();
    translate(pos.x,pos.y,pos.z);
    
    // set the local coordsys
    applyMatrix(orientation);
    
    // coordsys lines are 100mm long
    // x - r
    stroke(255,0,0,confidence * 200 + 55);
    line(0,0,0,
         length,0,0);
    // y - g
    stroke(0,255,0,confidence * 200 + 55);
    line(0,0,0,
         0,length,0);
    // z - b    
    stroke(0,0,255,confidence * 200 + 55);
    line(0,0,0,
         0,0,length);
  popMatrix();
}

// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(SimpleOpenNI curContext,int userId)
{
  println("onNewUser - userId: " + userId);
  context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext,int userId)
{
  println("onLostUser - userId: " + userId);
  stopBpmDetecting(userId);
}

void onVisibleUser(SimpleOpenNI curContext,int userId)
{
  //println("onVisibleUser - userId: " + userId);
}

void getBodyDirection(int userId,PVector centerPoint,PVector dir)
{
  PVector jointL = new PVector();
  PVector jointH = new PVector();
  PVector jointR = new PVector();
  float  confidence;
  
  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_SHOULDER,jointL);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_HEAD,jointH);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_SHOULDER,jointR);
  
  // take the neck as the center point
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,centerPoint);
  
  /*  // manually calc the centerPoint
  PVector shoulderDist = PVector.sub(jointL,jointR);
  centerPoint.set(PVector.mult(shoulderDist,.5));
  centerPoint.add(jointR);
  */
  
  PVector up = PVector.sub(jointH,centerPoint);
  PVector left = PVector.sub(jointR,centerPoint);
    
  dir.set(up.cross(left));
  dir.normalize();
}

// -----------------------------------------

HashMap<Integer, Dancer> dancers;
LinkedList<Dancer> dancersPool;
long systemStartedTime;
float systemCurrentTime;
int population = 0;

void updateTime() {
  systemCurrentTime = (float)(System.currentTimeMillis() - systemStartedTime) / 1000;
}

float getTime() {
  return systemCurrentTime;
}

void initMusicDanceSystem() {
  dancers = new HashMap<Integer, Dancer>();
  dancersPool = new LinkedList<Dancer>();
  systemStartedTime = System.currentTimeMillis();
  updateTime();
}

Dancer startBpmDetecting(int userId) {
  Dancer dancer = getDancer(userId);
  if (dancer == null) {
    PVector com = new PVector();
    context.getCoM(userId, com);
    dancer = fetchDancerFromPool(com);
    if (dancer != null) {
      dancers.put(new Integer(userId), dancer);
    } else {
      dancer = new Dancer(userId, context, this, getTime());
      dancers.put(new Integer(userId), dancer);
      dancer.initVisual(userClr[ (userId - 1) % userClr.length ]);
      setupGraph(userId, uiDisplayTop + uiDisplayHeight * (userId + 1) / 6);
    }
  }
  if (dancer.activate(userId)) {
    screenSaver.setPopulation(++population);
  }
  return dancer;
}

Dancer getDancer(int userId) {
  return dancers.get(new Integer(userId));
}

void stopBpmDetecting(int userId) {
  Dancer dancer = getDancer(userId);
  if (dancer != null) {
    dancers.remove(new Integer(userId));
    poolDancer(dancer);
    if (dancer.deactivate()) {
      screenSaver.setPopulation(--population);
    }
  }
}

void poolDancer(Dancer dancer) {
  dancersPool.push(dancer);
  println("Pool pushed:" + dancersPool.size());
}

Dancer fetchDancerFromPool(PVector com) {
  ListIterator<Dancer> itr = dancersPool.listIterator(0);
  if (!itr.hasNext()) return null;
  int    minIndex    = itr.nextIndex();
  Dancer minDancer   = itr.next();
  float  minDistance = com.dist(minDancer.com);
  while (itr.hasNext()) {
    int    index  = itr.nextIndex();
    Dancer dancer = itr.next();
    float distance = com.dist(dancer.com);
    if (minDistance > distance) {
      minDistance = distance;
      minDancer = dancer;
      minIndex = index;
    }
  }
  if (minDistance > 1000) {
    println("Pool found but too distanced:" + minIndex + " distance:" + minDistance + " rest:" + dancersPool.size());
    return null;
  }
  dancersPool.remove(minIndex);
  if (minDancer.timeDeactivated < getTime() - 30) {
    println("Pool found but expired:" + minIndex + " distance:" + minDistance + " rest:" + dancersPool.size());
    return null;
  } else {
    println("Pool fetched from:" + minIndex + " distance:" + minDistance + " rest:" + dancersPool.size());
    return minDancer;
  }
}

// キー入力のハンドラ(ユーティリティ的な)
void keyPressed() {
  if (keyEvent.isControlDown()) {
    switch(keyCode) {
      case LEFT:
        rotY += 0.1f;
        break;
      case RIGHT:
        rotY -= 0.1f;
        break;
      case UP:
        if(keyEvent.isShiftDown())
          zoomF += 0.01f;
        else
          rotX += 0.1f;
        break;
      case DOWN:
        if(keyEvent.isShiftDown()) {
          zoomF -= 0.01f;
          if(zoomF < 0.01) { zoomF = 0.01; }
        } else {
          rotX -= 0.1f;
        }
        break;
    }
  } else {
    switch(keyCode) {
      case LEFT:
        presentation.prev();
        break;
      case RIGHT:
        presentation.next();
        break;
    }
  }
}
void keyTyped() {
  switch (key) {
    case 's':
      ((DepthMapStore)context).save(pathToStoreStill);
      println("save context");
      break;
    case 'm':
      context.setMirror(!context.mirror());
      println("mirror");
      break;
    case 'p':
      presentation.toggle();
      break;
    default:
      println("key " + int(key) + " pushed");
      break;
  }
}

void songChanged() {
  visualizerIndex = (visualizerIndex + 1) % depthMapVisualizer.length;
}

// ---------------------- graph

void setupGraph(int userId, float y) {
  getDancer(userId).graph = new DebugGraph(y, graph_series, graph_series_colors);
}

void addDataToGraph(int userId, int series, float y) {
  getDancer(userId).graph.addValue(series, y);
}
void drawGraphs() {
  int[] userList = context.getUsers();
  for(int i=0;i<userList.length;i++) {
    if(context.isTrackingSkeleton(userList[i])) {
      getDancer(userList[i]).graph.draw();
    }
  }
}

// ---- Movie

void movieEvent(Movie m) {
  m.read();
}

// ----------------------

// display float values and labels
// discloseValues(new String[]{"", ..}, new float[]{0.1,..});
void discloseValues(String[] labels, float[] values) {
  for (int i = 0; i < values.length; i++) {
    if (labels != null && i < labels.length) {
      print(labels[i] + ":");
    }
    print(String.valueOf(values[i]));
    if (i < values.length - 1) {
      print(", ");
    }
  }
  println();
}

// ----------------------

void shutdown() {
  exit();
  Runtime.getRuntime().halt(-1);
}

class LaunchChecker extends TimerTask {
    public LaunchChecker() {
    }
    public void run() {
        if (frameCounter == 0 && frameCountStart == 0) {
          println("LaunchCheck failed (no draw() completed).");
          shutdown();
        } else {
          println("LaunchCheck passed.");
        }
    }
}
