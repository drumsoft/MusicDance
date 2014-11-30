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

* BeatDetector - ビートの検出器 - 検出がまだまだ
* SoundPlayer - 音楽データの再生 - ビートに合わせる部分ができた
* MoveDetector (体の動きの大きさなどの検出)
  * BodyMoveDetector - 上半身の動き
  * GroovyMoveDetector - 体のひねり
  * HandsUpMoveDetector - ハンズアップ

## 環境

* Processing
* SimpleOpenNI (Processing Sketch -> Import Library -> Add Library で追加)

