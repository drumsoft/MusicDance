import SimpleOpenNI.*;

class DepthMapStore extends SimpleOpenNI {
  int width;
  int height;
  int[] dMap;
  int[] uMap;
  PVector[] drMap;
  
  DepthMapStore(processing.core.PApplet parent) {
    super(parent);
  }
  
  void save(String saveTo) {
    JSONObject json = new JSONObject();
    json.setInt("depthWidth", super.depthWidth());
    json.setInt("depthHeight", super.depthHeight());
    json.setJSONArray("depthMap", jsonArrayFromIntArray(super.depthMap()));
    json.setJSONArray("userMap", jsonArrayFromIntArray(super.userMap()));
    json.setJSONArray("depthMapRealWorld", jsonArrayFromPVectorArray(super.depthMapRealWorld()));
    saveJSONObject(json, _parent.dataPath(saveTo));
  }
  
  void load(String saveTo) {
    JSONObject json = loadJSONObject(_parent.dataPath(saveTo));
    width = json.getInt("depthWidth");
    height = json.getInt("depthHeight");
    dMap = intArrayFromJsonArray(json.getJSONArray("depthMap"));
    uMap = intArrayFromJsonArray(json.getJSONArray("userMap"));
    drMap = pVectorArrayFromJsonArray(json.getJSONArray("depthMapRealWorld"));
  }
  
  int depthWidth() { return width; }
  int depthHeight() { return height; }
  int[] depthMap() { return dMap; }
  int[] userMap() { return uMap; }
  PVector[] depthMapRealWorld() { return drMap; }
  
  //isInit()
  //mirror()
  //setMirror()
  //enableIR()
  //enableDepth()
  //enableUser()
  //depthImage()
  //update()
  //drawCamFrustum()
  
  //getUsers()
  //isTrackingSkeleton()
  //getCoM()
  //getJointPositionSkeleton()
  //getJointOrientationSkeleton()
  //startTrackingSkeleton()
  
  // ----------------------------------------------
  JSONArray jsonArrayFromIntArray(int[] array) {
    JSONArray json = new JSONArray();
    for (int i = 0; i < array.length; i++) {
      json.setInt(i, array[i]);
    }
    return json;
  }
  JSONArray jsonArrayFromPVectorArray(PVector[] array) {
    JSONArray json = new JSONArray();
    for (int i = 0; i < array.length; i++) {
      json.setFloat(i * 3 + 0, array[i].x);
      json.setFloat(i * 3 + 1, array[i].y);
      json.setFloat(i * 3 + 2, array[i].z);
    }
    return json;
  }
  int[] intArrayFromJsonArray(JSONArray json) {
    int[] array = new int[json.size()];
    for (int i = 0; i < array.length; i++) {
      array[i] = json.getInt(i);
    }
    return array;
  }
  PVector[] pVectorArrayFromJsonArray(JSONArray json) {
    PVector[] array = new PVector[json.size() / 3];
    for (int i = 0; i < array.length; i++) {
      array[i] = new PVector();
      array[i].x = json.getFloat(i * 3 + 0);
      array[i].y = json.getFloat(i * 3 + 1);
      array[i].z = json.getFloat(i * 3 + 2);
    }
    return array;
  }
}
