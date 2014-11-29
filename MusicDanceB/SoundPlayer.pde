import beads.*;

class SoundPlayer {
  
  float originalBPM = 123;
  float bpmCapacityMax = 190;
  float bpmCapacityMin = 80;
  double originalLength = 15.610;
  double positionOffsetToFirstBeat = 0; // 最初のビート位置へのオフセット
  float bpmAdjustingForBeatSlip = 5; // ビートとタップのずれ1に対して、補正をどれだけ(BPMで)かけるか
  float currentBPM;
  String[] soundFiles = { // サウンドファイルの一覧
    "m1-A.wav",
    "m1-B.wav",
    "m1-C.wav",
    "m1-D.wav",
    "m1-E.wav",
    "m1-F.wav"
  };
  boolean[] isPlaying;
  SamplePlayer[] players;
  int tapCount = 0;
  
  Glide speedGlideUGen;
  
  AudioContext ac;
  
  
  SoundPlayer() {
    currentBPM = originalBPM;
    
    ac = new AudioContext();
    
    speedGlideUGen = new Glide(ac, 1.0, 2000);
    
    isPlaying = getPlayingStatusDefault();
    players = new SamplePlayer[soundFiles.length];
    
    for (int i = 0; i < soundFiles.length; i++) {
      loadSound(i);
    }
  }
  
  void start() {
    boolean[] toPlay = getPlayingStatusDefault();
    toPlay[0] = true;
    setPlayingStatus(toPlay);
    ac.start();
  }
  
  void stop() {
    ac.stop();
  }
  
  void tapBeat(float bpm) {
    println("beat tapped: " + bpm);
    if (bpm < bpmCapacityMin || bpmCapacityMax < bpm) {
      return;
    }
    currentBPM = bpm;
    speedGlideUGen.setValue((currentBPM + (float)(beatSlipping() * bpmAdjustingForBeatSlip)) / originalBPM);
    
    if (tapCount++ % 32 == 0) {
      boolean[] toPlay = getPlayingStatusDefault();
      toPlay[(int)Math.floor(tapCount / 32) % soundFiles.length] = true;
      setPlayingStatus(toPlay);
    }
  }
  
  float getBPM() {
    return currentBPM;
  }
  
  void setMoving(float movingValue) {
  }
  
  void setTwisting(float twistingValue) {
  }
  
  void startHandsUp() {
  }
  
  void endHandsUp() {
  }
  
  // --------------------------------------------------------
  
  // 現在の再生タイミングが、ジャストなビート位置からいかほどずれているかを返す
  // 返却値は [-0.5,0.5) の範囲で 0 の時ジャスト、 -0.5 の時は半拍遅れている。
  double beatSlipping() {
    double position = 0;
    for (int i = 0; i < soundFiles.length; i++) {
      if (isPlaying[i]) {
        position = players[i].getPosition();
        break;
      }
    }
    double beat = originalBPM * (position - positionOffsetToFirstBeat) / 60000;
    return beat - Math.round(beat);
  }
  
  boolean[] getPlayingStatusDefault() {
    boolean [] stat = new boolean[soundFiles.length];
    for (int i = 0; i < soundFiles.length; i++) {
      stat[i] = false;
    }
    return stat;
  }
  
  // トラックの再生状況を変更
  void setPlayingStatus(boolean[] toPlay) {
    double position = 0;
    for (int i = 0; i < soundFiles.length; i++) {
      if (isPlaying[i]) {
        position = players[i].getPosition();
        if (!toPlay[i]) { // to OFF
          ac.out.removeAllConnections(players[i]);
          isPlaying[i] = false;
        }
      }
    }
    for (int i = 0; i < soundFiles.length; i++) {
      if (!isPlaying[i] && toPlay[i]) { // to ON
        players[i].setPosition(position);
        ac.out.addInput(players[i]);
        isPlaying[i] = true;
      }
    }
  }
  
  // サウンドをロードしてループ設定を行う
  void loadSound(int i) {
    Sample sample = SampleManager.sample(dataPath(soundFiles[i]));
    players[i] = new SamplePlayer(ac, sample);
    players[i].setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
    players[i].setLoopPointsFraction(0, 1);
    players[i].setRate(speedGlideUGen);
    //Gain g = new Gain(ac, 2, 0.2);
    //g.addInput(player);
    //ac.out.addInput(g);
  }
  
}
