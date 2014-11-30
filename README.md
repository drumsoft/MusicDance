# ミュージックダンス（仮）

## 概要(SMUA資料より)

* チーム名
  * 日本パーティー党
* 概要
  * ダンスに合わせて、音楽が流れる。
  * Kinectを使ってダンスのリズムを測定、リズムに近い楽曲を自動的に流す。
* 利用技術・プラットフォーム・API
  * gracenote / kinect / TSUTAYA
* メンバー構成
  * 片岡 ハルカ
  * 岩坂丈洋
  * アッチュ
  * 渡部高士

## TODO

* BeatDetector - ビートの検出器 - 膝の上下でなく、曲げる動き等を試したい。
* SoundPlayer - 音楽データの再生 - 曲を変える条件は再考の余地が。エフェクト等も入れたい。
* MoveDetector (体の動きの大きさなどの検出)
  * BodyMoveDetector - 上半身の動き - できた
  * GroovyMoveDetector - 体のひねり - 未実装
  * HandsUpMoveDetector - ハンズアップ - できた

## 環境

* Processing
* SimpleOpenNI (Processing の機能で追加)
* beads (Processing の機能で追加)
