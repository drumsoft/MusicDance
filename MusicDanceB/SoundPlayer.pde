import beads.*;

class SoundPlayer extends Bead {
  
  float originalBPM = 123;
  float bpmCapacityMax = 190;
  float bpmCapacityMin = 80;
  double originalLength = 15.610;
  double positionOffsetToFirstBeat = 0; // 最初のビート位置へのオフセット
  float bpmAdjustingForBeatSlip = 5; // ビートとタップのずれ1に対して、補正をどれだけ(BPMで)かけるか
  float currentBPM;
  float previousTapEvent;
  String[] soundFiles = { // サウンドファイルの一覧
    "m1-A.wav",
    "m1-B.wav",
    "m1-C.wav",
    "m1-D.wav",
    "m1-E.wav",
    "m1-F.wav",
    "m2-A.wav",
    "m2-B.wav",
    "m2-C.wav",
    "m2-D.wav",
    "m2-E.wav",
    "m2-F.wav",
    "m3-A.wav",
    "m3-B.wav",
    "m3-C.wav",
    "m3-D.wav",
    "m3-E.wav",
    "m3-F.wav",
    "m4-A.wav",
    "m4-B.wav",
    "m4-C.wav",
    "m4-D.wav",
    "m4-E.wav",
    "m4-F.wav",
    "m5-A.wav",
    "m5-B.wav",
    "m5-C.wav",
    "m5-D.wav",
    "m5-E.wav",
    "m5-F.wav"
  };
  SamplePlayer playingSong;
  SamplePlayer[] players;
  int tapCount = 0;
  int currentSong = 0; // [0, 3] 現在の曲
  int currentPart = 0; // テンションによって変化 [0, 3] タップがなくなったら 4, 5, 次の曲
  int lowTensionPartLimit = 4; // ローテンションのパートが この回数続いたら曲を変更
  int nonTapLimit = 6; // タップなしの状態がこの秒数続いたら曲を変更
  
  Glide speedGlide;
  float tension, handsUpFactor;
  int lowTensionPartCount = 0;
  boolean songChangeBreakPlayed = false;
  
  AudioContext ac;
  
  
  SoundPlayer() {
    currentBPM = originalBPM;
    
    ac = new AudioContext();
    
    speedGlide = new Glide(ac, 1.0, 2000);
    
    players = new SamplePlayer[soundFiles.length];
    
    for (int i = 0; i < soundFiles.length; i++) {
      loadSound(i);
    }
  }
  
  void start() {
    changeSong(true);
    ac.start();
  }
  
  void stop() {
    ac.stop();
  }
  
  void tapBeat(float bpm) {
    if (bpm < bpmCapacityMin || bpmCapacityMax < bpm) {
      return;
    }
    currentBPM = bpm;
    speedGlide.setValue((currentBPM + (float)(beatSlipping() * bpmAdjustingForBeatSlip)) / originalBPM);
    previousTapEvent = getTime();
  }
  
  float getBPM() {
    return currentBPM;
  }
  
  void setMoving(float movingValue) {
    tension = movingValue;
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
    ac.out.removeAllConnections(sp);
    playingSong = null;
    changeSong(true);
  }
  
  // --------------------------------------------------------
  
  // 現在の再生タイミングが、ジャストなビート位置からいかほどずれているかを返す
  // 返却値は [-0.5,0.5) の範囲で 0 の時ジャスト、 -0.5 の時は半拍遅れている。
  double beatSlipping() {
    double position = 0;
    if (playingSong != null) {
      position = playingSong.getPosition();
    }
    double beat = originalBPM * (position - positionOffsetToFirstBeat) / 60000;
    return beat - Math.round(beat);
  }
  
  // サウンドをロードしてループ設定を行う
  void loadSound(int i) {
    Sample sample = SampleManager.sample(dataPath(soundFiles[i]));
    players[i] = new SamplePlayer(ac, sample);
    players[i].setKillOnEnd(false);
    //players[i].setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
    //players[i].setLoopPointsFraction(0, 1);
    players[i].setRate(speedGlide);
    //Gain g = new Gain(ac, 2, 0.2);
    //g.addInput(player);
    //ac.out.addInput(g);
  }
  
  // 曲を変更する
  void changeSong(boolean isEnded) {
    int nextSong = currentSong, nextPart = currentPart;
    
    if (currentBPM > 155 && currentSong < 3) { // DnBへ変更条件(同じパートへ)
      nextSong = (nextSong % 2) + 3;
    } else if (currentBPM < 150 && currentSong == 3) { // DnBから元に戻す条件
      nextSong = (nextSong % 3);
    } else if (currentPart == 5) { // パート 5 の後は曲変更
      if (nextSong < 3) {
        nextSong = (currentSong + 1) % 3; // 0,1,2
      } else {
        nextSong = (currentSong - 3 + 1) % 2 + 3; // 3,4
      }
      nextPart = 0;
    } else if (handsUpFactor > 0.5) { // 両手上げで最後のパートに(別の曲へつなぎたい)
      nextPart = 5;
    } else { // テンションで パート を切り替え
      nextPart = (int)Math.min(tension / 150, 3);
      
      // ローテンションパートの回数をカウント
      if (currentPart == 0 && nextPart == 0) {
        lowTensionPartCount++;
      }
      
      // ローテンションパートが続いたり、タップがない場合にブレイクにつなぐ
      if ((getTime() - previousTapEvent > nonTapLimit) || lowTensionPartCount >= lowTensionPartLimit) {
        if (songChangeBreakPlayed) {
          nextPart = 5;
        } else {
          nextPart = 4;
          songChangeBreakPlayed = true;
        }
      }
    }
    
    if (nextSong != currentSong) { // 曲変更時
      lowTensionPartCount = 0;
      songChangeBreakPlayed = false;
      currentSong = nextSong;
      currentPart = nextPart;
    } else if (nextPart != currentPart) { // パート変更時
      currentPart = nextPart;
      lowTensionPartCount = 0;
    }
    
    playingSong = players[currentSong * 6 + currentPart];
    playingSong.reset();
    ac.out.addInput(playingSong);
    playingSong.setEndListener(this);
    println("Song:" + currentSong + " Part:" + currentPart + " BPM:" + currentBPM + " tension:" + tension + " hand:" + handsUpFactor);
  }
}
