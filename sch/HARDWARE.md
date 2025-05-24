# Z80proto2 hardware -- I/O processor, implementation for Z80

## What is this?(コレは何？)
ev68020などで使うつもりの、I/OプロセッサのZ80実装です。

ここでは、ハードウェアの概要を説明します。


## Environment(動作環境)
Tool                    | Description
:-----------------------|:---------------------------------------------------
**target**              | Z80(Z80proto2), Z84C(SAKI80), and other Z80 compat.
**Boot ROM**            | 2716/2816 for minimum config., 2764/2864 for Serial Download config.
**CAD**                 | KiCad Version (6.0.11), release build


## Directory(ディレクトリ構成)
Directory           | Description
:-------------------|:--------------------------------------------------
**FDC**             |MZ-80FI's diagram trace (C)1981 Sharp Corporation
**MZ80K_framebuf**  |MZ-80K's diagram trace (C)1979-81 Sharp Corporation
**Z80proto1**       |Z80proto IM1 model(project suspend)
**Z80proto2**       |Z80proto IM2 model
**Z80proto2-SAKI80**|Z80proto IM2 model w/Super AKI-80


## Status(進捗) -- 2025年4月現在
Z80proto2基板 -> 設計完了, FDC&DMAモジュールの試作中

Z80proto2 SAKI80(AKA Super AKI-80)サポート基板 -> 設計完了, 試作回路のデバッグ中


## Overview(概要)
・全体的には、ごく普通のZ80回路です。クロック4MHzで150nsecのメモリがノーウェイト動作しています。SAKI80の場合は1ウェイト入れておくべきでしょう。

・本設計の最大の特徴はROMKICK回路です。コレは、ROM領域をI/O操作によりRAMに切り替え可能としたもので、他のプロジェクトでも動作の実績があります。下記メモリマップを参照して下さい。

・本プロジェクト(Z80proto)開始時に、東京秋葉原で容易に入手可能なRAMは容量が大きなモノばかりだったので、628128相当のM68AF127を採用しました。Z80のメモリ空間64kBytesの2倍なので、リセット後には領域の前半分64kBytesを使い、RAMKICK回路により切り替え可能としています。

・ROMKICK/RAMKICKについて。プログラム誤動作などによる切り替え動作を防ぐため、2ステップの手順が必要です。

・その他、ソフトウェアによるSPI実装(ソレに対応するI/Oピン)、7seg LED表示機能(オプション)があります。

・ROMKICK/RAMICK, SPI機能を使用しない場合は、回路を実装しなくても構いません。ROMのアドレスデコードは忘れずに。


## Memory Map(メモリマップ)
・Power or RESET*　on Z80proto2
Address    |
:----------|:--------------------------------
0000h~1FFFh| ROM
2000h~FFFFh| RAM前半 or 後半(RAMKICKで切り替え)

・ROMKICK操作後
Address    |
:----------|:--------------------------------
0000h~FFFFh| RAM前半 or 後半(RAMKICKで切り替え)

※ROMKICK後、フルRAM状態でRAMKICKする際には、当然ながら工夫が必要です。


## TODO(今後修正・追加すべきモノゴトと細かい話)
1. 回路構成の説明書作成 -> この文書。書き足していきます
2. TC6367コンパチビリティ廃止によるUW2の削除 -> FIXしたつもりだけれども慎重に確認が必要 -> Proto2基板によりロングランテストで確認中
5. 回路修正により、SPI_SELD_DEVは必要なくなった -> 7seg回路をオプションとしたため、そこに含まれていたSPICS*をシステムレジスタ(UW5)に移した -> ソレをU17で読み取り可能としたので、RAM上に保持する必要がなくなった
6. システムレジスタ(UW5)を74HC259などに変更する -> 現状74HC574には出力リセットが付いていないため(動作環境によっては問題になりうる)


## Known Problem(既知の問題)
2. SAKI80サポート基板において、現在の設計では使用部品の個体差(ゲート遅延など)によってRead/Writeが間に合わない場合があります。WAIT回路の追加を慎重に検討しています。現状では、アクセス時間の短いROM/RAMを選択する(55nsecでギリギリ？)、ゲート遅延の短いバッファを使用する(HCよりもVHCやABTがオススメ)などを検討してください。


## Cautions(注意事項)
・28C64を使用する場合、2764との差異により1番ピンの処置が必要になります。


## LICENSE(ライセンス)
FDC回路の設計参考として、MZ-80KとMZ-80FIの回路図を参照させて頂きました。(C)1979-81 Sharp Corporation

使用しているデバイスについて、メーカーがデータシートなどで開示している技術情報は、各社に工業所有権があります。

"Super AKI-80"、"スーパーAKI-80"は、株式会社秋月電子通商の商標です。

私(yasunoxx▼Julia)が書いたプログラムは、MITライセンスで開示しています。本プログラム[Z80proto2](https://github.com/yasunoxx/Z80proto2)を使用した/使用しない事による全ての結果について、上記権利者と私は何の保証も賠償も致しません。
