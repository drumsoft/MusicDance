class Preferences {
  private final String[] defaultMap = {
    "screenWidth", "1280",
    "screenHeight", "800",
    "oscSendHost", "127.0.0.1",
    "oscSendPort", "7771",
    "oscRecvPort", "7772",
    "run_mode", "0", // 0: demo, 2: playback
    "kinectWidth", "640",
    "kinectHeight", "480",
    "zoom_mode", "2" // 0: default, 1: width, 2: height, 3: nozoom
  };
  
  private final String[] nnpMap = {
    "screenWidth", "1280",
    "screenHeight", "800",
    "oscSendHost", "192.168.0.2",
    "oscSendPort", "7772",
    "oscRecvPort", "7771",
    "run_mode", "0", // 0: demo, 2: playback
    "zoom_mode", "2" // 0: default, 1: width, 2: height, 3: nozoom
  };
  
  private String defaultMapName = "default";
  
  private String envUser;
  private HashMap<String, HashMap<String, String>> preferences;
  
  Preferences() {
    envUser = System.getenv("USER");
    
    preferences = new HashMap<String, HashMap<String, String>>();
    preferences.put(defaultMapName, mapFromArray(defaultMap));
    preferences.put("nnp", mapFromArray(nnpMap));
  }
  
  private HashMap<String, String> mapFromArray(String[] array) {
    HashMap map = new HashMap<String, String>();
    for (int i = 0; i < array.length; i += 2) {
      map.put(array[i], array[i+1]);
    }
    return map;
  }
  
  public String get(String key) {
    if (preferences.containsKey(envUser) && preferences.get(envUser).containsKey(key)) {
      println("PREF:" + envUser + " " + key + " " + preferences.get(envUser).get(key));
      return preferences.get(envUser).get(key);
    } else if (preferences.get(defaultMapName).containsKey(key)) {
      println("PREF:" + defaultMapName + " " + key + " " + preferences.get(defaultMapName).get(key));
      return preferences.get(defaultMapName).get(key);
    } else {
      println("PREF: " + key + " null");
      return null;
    }
  }
  
  public int getInt(String key) {
    return Integer.parseInt(get(key));
  }
  
  public float getFloat(String key) {
    return Float.parseFloat(get(key));
  }
}
