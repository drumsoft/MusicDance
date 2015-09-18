import beads.*;

class SoundPlayer extends Bead {
  static final int SPEED_SLOW = 0;
  static final int SPEED_NORMAL = 1;
  static final int SPEED_FAST = 2;
  
  float originalBPM = 123;
  float bpmCapacityMax = 190;
  float bpmCapacityMin = 80;
  double originalLength = 15.610;
  double positionOffsetToFirstBeat = 166; // 最初のビート位置へのオフセット
  float beatsToFollowBpm = 2; // BPMを変動させるまでにかかる時間の目標値(ビート数) strictness = 0 の時
  float beatsToFollowBpmAdditionByStrictness = 6; // 同 strictness によって加算する値
  
  static final float fadeStartTimeAfterLastKick = 10.0;
  static final float fadeOutPerFrame = 1.0 / (4.0 * 30.0); // gain per frame
  static final float fadeInPerKick = 1.0 / (4.0 * 8.0); // gain per beat
  
  float currentBPM;
  float currentTime;
  float startTime, endTime, startBpm, endBpm;
  
  String ambientSoundFile = "m0-all.wav";
  String[] soundFiles = { // サウンドファイルの一覧
    "m1-A.wav", "m1-B.wav", "m1-C.wav", "m1-D.wav", "m1-E.wav", "m1-F.wav", //0 minimal
    "m2-A.wav", "m2-B.wav", "m2-C.wav", "m2-D.wav", "m2-E.wav", "m2-F.wav", //1 trance
    "m3-A.wav", "m3-B.wav", "m3-C.wav", "m3-D.wav", "m3-E.wav", "m3-F.wav", //2 house
    "m4-A.wav", "m4-B.wav", "m4-C.wav", "m4-D.wav", "m4-E.wav", "m4-F.wav", //3 DnB(fast)
    "m5-A.wav", "m5-B.wav", "m5-C.wav", "m5-D.wav", "m5-E.wav", "m5-F.wav", //4 dubstep
    "M8-A-02.wav", "M8-B-02.wav", "M8-C.wav", "M8-D.wav", "M8-E.wav", "M8-F.wav" //5 breakbeats(fast)
  };
  int numberOfSongs = 6;
  boolean[] isPlayed;
  int[][] soundMap = {
    { 0, 0, 3 },
    { 4, 1, 1 },
    { 2, 2, 5 },
    { 2, 2, 2 },
    { 4, 1, 3 },
    { 0, 0, 5 }
  };
  
  SamplePlayer ambientSoundPlayer;
  SamplePlayer playingSong;
  SamplePlayer[] players;
  Gain masterGain;
  Gain ambientGain;
  double ambientSoundLength;
  
  int currentSong = 0; // [0, 3] 現在の曲
  int currentPart = 0; // テンションによって変化 [0, 3] タップがなくなったら 4, 5, 次の曲
  
  int speedClass = SPEED_NORMAL;
  int tensionClass = 0;
  
  Static playbackSpeed;
  float tension, handsUpFactor;
  MoveFilterAverage tensionFilter;
  
  float lastKickedTime = 0;
  float kickedVolume = 0;
  boolean isFadeOuting = false;
  
  AudioContext ac;
  
  MusicDanceB main;
  
  SoundPlayer(MusicDanceB md) {
    main = md;
    currentBPM = originalBPM;
    startTime = 0;
    endTime = 0.01;
    startBpm = originalBPM;
    endBpm = originalBPM;
    
    ac = new AudioContext();
    
    masterGain = new Gain(ac, 1, 1.0);
    ac.out.addInput(masterGain);
    
    playbackSpeed = new Static(ac, 1.0);
    
    players = new SamplePlayer[soundFiles.length];
    for (int i = 0; i < soundFiles.length; i++) {
      players[i] = loadSound(soundFiles[i]);
    }
    
    ambientGain = new Gain(ac, 1, 1.0);
    ac.out.addInput(ambientGain);
    ambientSoundPlayer = loadSound(ambientSoundFile);
    ambientSoundPlayer.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
    ambientSoundPlayer.setLoopPointsFraction(0, 1);
    ambientGain.addInput(0, ambientSoundPlayer, 0);
    ambientSoundLength = ambientSoundPlayer.getSample().getLength();
    
    setGain();
    
    isPlayed = new boolean[numberOfSongs];
    resetPlayed();
    tensionFilter = new MoveFilterAverage(120, 0);
  }
  
  void start() {
    changeSong(true);
    ac.start();
  }
  
  void stop() {
    ac.stop();
  }
  
  void resetPlayed() {
    for (int i = 0; i < numberOfSongs; i++) {
      isPlayed[i] = false;
    }
    tensionClass = 0;
  }

  // (weighted averaged bpm, phase by topDancer, strictness by topDancer)
  void changeBPM(float bpm, float phase, float strictness) {
    if (currentBPM != bpm) {
      float targetTimeMinutes = (beatsToFollowBpm + beatsToFollowBpmAdditionByStrictness * strictness) * 2 / (currentBPM + bpm);
      // beatsToFollowBpm beats for averaged bpm
      float halfBpmDiff = (bpm - currentBPM) / 2;
      float phaseDiff = halfBpmDiff * targetTimeMinutes + (phase - getPhase());
      float phaseAdjust = Math.round(phaseDiff) - phaseDiff;
      endTime = currentTime + (targetTimeMinutes + phaseAdjust / halfBpmDiff) * 60;
      startTime = currentTime;
      startBpm = currentBPM;
      endBpm = bpm;
    }
  }
  
  void update(float time) {
    currentTime = time;
    if (currentTime < endTime) {
      float elapsedRate = (currentTime - startTime) / (endTime - startTime);
      currentBPM = startBpm * (1 - elapsedRate) + endBpm * elapsedRate;
      playbackSpeed.setValue(currentBPM / originalBPM);
    } else if (currentBPM != endBpm) {
      currentBPM = endBpm;
      playbackSpeed.setValue(currentBPM / originalBPM);
    }
    
    if (isFadeOuting) { // Gain fadeout.
      if (kickedVolume > 0) {
        kickedVolume -= fadeOutPerFrame;
        if (kickedVolume < 0) {
          kickedVolume = 0;
          isFadeOuting = false;
          resetPlayed();
        }
        setGain();
      }
    } else { // check fadeout should be started.
      if (currentTime - lastKickedTime > fadeStartTimeAfterLastKick) {
        isFadeOuting = true;
      }
    }
  }
  
  void kick() { // up the Gain
    lastKickedTime = getTime();
    isFadeOuting = false;
    kickedVolume += fadeInPerKick;
    if (kickedVolume > 1.0) kickedVolume = 1.0;
    setGain();
  }
  
  void setGain() {
    masterGain.setGain(gainFromVolume(kickedVolume));
    ambientGain.setGain(gainFromVolume(1 - kickedVolume));
    //println("Gain:" + Float.toString(kickedVolume));
  }
  
  float gainFromVolume(float volume) {
    return (float)Math.pow(10, (volume - 1)) - 0.1;
  }
  
  float getBPM() {
    return currentBPM;
  }
  
  void setMoving(float movingValue) {
    tension = tensionFilter.input(movingValue, 0);
  }
  
  void setTwisting(float twistingValue) {
  }
  
  void setHandsUp(float handsUp) {
    handsUpFactor = handsUp;
  }
  
  // -------------------------------------------------------- Bead Event
  
  protected void messageReceived(Bead message) {
    SamplePlayer sp = (SamplePlayer) message;
    sp.setEndListener(null);
    changeSong(true);
  }
  
  // --------------------------------------------------------
  
  // phase = [0〜1) (mod 1) ビートの開始ポイントを 0 とする
  float getPhase() {
    double position = playingSong != null ? playingSong.getPosition() : 0;
    return (float)(originalBPM * (position - positionOffsetToFirstBeat) / 60000) % 1;
  }
  
  // サウンドをロードしてループ設定を行う
  SamplePlayer loadSound(String fileName) {
    Sample sample = SampleManager.sample(dataPath(fileName));
    SamplePlayer player = new SamplePlayer(ac, sample);
    player.setKillOnEnd(false);
    //player.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
    //player.setLoopPointsFraction(0, 1);
    player.setRate(playbackSpeed);
    return player;
  }
  
  // 曲を変更する
  void changeSong(boolean isEnded) {
    switch (speedClass) {
      case SPEED_SLOW:
        if (currentBPM > 122) speedClass = SPEED_NORMAL;
        break;
      case SPEED_NORMAL:
        if (currentBPM > 163) speedClass = SPEED_FAST;
        if (currentBPM < 100) speedClass = SPEED_SLOW;
        break;
      case SPEED_FAST:
        if (currentBPM < 138) speedClass = SPEED_NORMAL;
        break;
    }
    
    if (tension + (currentPart * 400) > (1500 + 5 * 400)) { // 3500, 3100, 2700, 2300, 1900, 1500
      tensionClass++;
      if (tensionClass >= soundMap.length) tensionClass = 0;
    } else if (tension < 100) {
      if (tensionClass > 0) tensionClass--;
    }
    
    int nextSong = soundMap[tensionClass][speedClass];
    
    if (nextSong != currentSong) { // 曲変更時
      currentSong = nextSong;
      if (!isPlayed[currentSong]) { // 未演奏の曲は頭から
        currentPart = 0;
        isPlayed[currentSong] = true;
      }
      main.songChanged();
    } else { // 曲変更なし
      currentPart++;
      if (currentPart >= 6) {
        currentPart = 0;
      }
    }
    
    SamplePlayer previousSong = playingSong;
    playingSong = players[currentSong * 6 + currentPart];
    playingSong.reset();
    if (previousSong != playingSong) {
      masterGain.addInput(0, playingSong, 0);
      if (previousSong != null) {
        masterGain.removeConnection(0, previousSong, 0);
      }
    }
    playingSong.setEndListener(this);
    println("Song:" + currentSong + " Part:" + currentPart + " BPM:" + currentBPM + " tension:" + tension + " speedClass:" + speedClass + " tensionClass:" + tensionClass);
    
    ambientSoundPlayer.setPosition(ambientSoundLength * (currentPart % 6) / 6);
  }
}
