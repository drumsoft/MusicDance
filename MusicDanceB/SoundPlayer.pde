import beads.*;

class SoundPlayer extends Bead {
  
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
  float previousTapEvent;
  
  String ambientSoundFile = "m0-all.wav";
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
  SamplePlayer ambientSoundPlayer;
  SamplePlayer playingSong;
  SamplePlayer[] players;
  Gain masterGain;
  Gain ambientGain;
  double ambientSoundLength;
  
  int tapCount = 0;
  int currentSong = 0; // [0, 3] 現在の曲
  int currentPart = 0; // テンションによって変化 [0, 3] タップがなくなったら 4, 5, 次の曲
  int lowTensionPartLimit = 4; // ローテンションのパートが この回数続いたら曲を変更
  int nonTapLimit = 6; // タップなしの状態がこの秒数続いたら曲を変更
  
  Static playbackSpeed;
  float tension, handsUpFactor;
  int lowTensionPartCount = 0;
  boolean songChangeBreakPlayed = false;
  float fadeInVolume = -1.0;
  
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
  }
  
  void start() {
    changeSong(true);
    ac.start();
  }
  
  void stop() {
    ac.stop();
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
        if (kickedVolume < 0) kickedVolume = 0;
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
    int nextSong = currentSong, nextPart = currentPart;
    
    if (currentBPM > 160 && currentSong < 3) { // DnBへ変更条件(同じパートへ)
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
      if (nextPart <= currentPart) { nextPart++; } //デモ用 短時間でパートを進める
      /*
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
      */
    }
    
    if (nextSong != currentSong) { // 曲変更時
      lowTensionPartCount = 0;
      songChangeBreakPlayed = false;
      currentSong = nextSong;
      currentPart = nextPart;
      main.songChanged();
    } else if (nextPart != currentPart) { // パート変更時
      currentPart = nextPart;
      lowTensionPartCount = 0;
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
    println("Song:" + currentSong + " Part:" + currentPart + " BPM:" + currentBPM + " tension:" + tension + " hand:" + handsUpFactor);
    
    ambientSoundPlayer.setPosition(ambientSoundLength * (currentPart % 6) / 6);
  }
}
