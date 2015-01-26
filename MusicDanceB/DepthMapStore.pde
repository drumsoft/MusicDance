import SimpleOpenNI.*;

class DepthMapStore extends ContextWrapper {
  String filePath;
  int width;
  int height;
  int[] dMap;
  int[] uMap;
  PVector[] drMap;
  
  DepthMapStore(String saveTo) {
    super();
    filePath = saveTo;
  }
  
  void save(SimpleOpenNI context) {
    JSONObject json = new JSONObject();
    json.setInt("depthWidth", context.depthWidth());
    json.setInt("depthHeight", context.depthHeight());
    json.setJSONArray("depthMap", jsonArrayFromIntArray(context.depthMap()));
    json.setJSONArray("userMap", jsonArrayFromIntArray(context.userMap()));
    json.setJSONArray("depthMapRealWorld", jsonArrayFromPVectorArray(context.depthMapRealWorld()));
    saveJSONObject(json, filePath);
  }
  
  void load() {
    JSONObject json = loadJSONObject(filePath);
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
