# OSC tools

Net::OpenSoundControl が必要です。

## OSCをダンプ表示

    ./oscdump.pl 7771

(7771 は受信ポート番号)

## OSCを記録

    ./oscdump.pl 7771 > dump.log

## 記録した OSC を送信

    ./oscsend.pl 127.0.0.1:7772 < dump.log

127.0.0.1:7772 は 宛先IPアドレス:ポート番号
