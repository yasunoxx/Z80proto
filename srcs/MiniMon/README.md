## MiniMon -- Mini Monitor for Z80proto w/Async. FIFO

# Usage

build ../ipl0.bin, 'zcc +embedded --no-crt ../ipl0.asm -o ../ipl0.bin'
and just type 'make' .

# ## Environment(動作環境)
Tool                    | Description
:-----------------------|:---------------------------------------------------
**target**              | Z80(Z80proto2), Z84C(SAKI80), and other Z80 compat. see also sch [Z80proto/sch](https://github.com/yasunoxx/Z80proto/sch) folder
**z88dk**               | v19766-9ffe2042c-20220723
**make**                | GNU Make 4.3, Built for x86_64-pc-linux-gnu

# Memory Map
    |                   |
----:-------------------:---------------------------------
ROM | 0 ~ 0FFh          | ipl0
ROM | 100h ~ 1FFFh      | MiniMon .text & .data area
RAM | 8000h ~ 0D7FFh    | (free)
RAM | 0D800h ~ 0E7FFh   | MiniMon .text & .data area
RAM | 0E800h ~ 0F800h   | (free)
RAM | 0F800h ~ 0FFFFh   | MiniMon work area
RAM | (0FC30h ~ 0FFFFh) | stack

## LICENSE(ライセンス)
使用しているデバイスについて、メーカーがデータシートなどで開示している技術情報は、各社に工業所有権があります。

xymodem.cは、Chuck Forsberg氏による10-14-88版ドキュメントより作成しました。

"Super AKI-80"、"スーパーAKI-80"は、株式会社秋月電子通商の商標です。

lcdlib.cは、Sakazume氏(http://219.117.208.26/~saka/ham/LCD2/)による実装です。

私(yasunoxx▼Julia)が書いたプログラムは、MITライセンスで開示しています。本プログラム[Z80proto2](https://github.com/yasunoxx/Z80proto2)を使用した/使用しない事による全ての結果について、上記権利者と私は何の保証も賠償も致しません。
