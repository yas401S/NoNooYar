#!/usr/bin/env bash
set -euo pipefail

ROOT="app/src/main/assets/voices"
mkdir -p "$ROOT" /tmp/yasin-alphabet-audio

# Persian letter-name recordings from Wikimedia Commons (Roozitaa, CC BY-SA 4.0).
while IFS='|' read -r number source; do
  [ -n "$number" ] || continue
  curl -L --retry 3 --fail --silent --show-error \
    "https://commons.wikimedia.org/wiki/Special:Redirect/file/${source}" \
    -o "$ROOT/fa-letter-${number}.ogg"
  test -s "$ROOT/fa-letter-${number}.ogg"
done <<'FILES'
01|1-alef.ogg
02|2-be.ogg
03|3-pe.ogg
04|4-te.ogg
05|5-se.ogg
06|6-jim.ogg
07|7-che.ogg
08|8-he.ogg
09|9-khe.ogg
10|10-dal.ogg
11|11-zal.ogg
12|12-re.ogg
13|13-ze.ogg
14|14-zhe.ogg
15|15-sin.ogg
16|16-shin.ogg
17|17-sad.ogg
18|18-zad.ogg
19|19-ta.ogg
20|20-za.ogg
21|21-ein.ogg
22|22-ghin.ogg
23|23-fe.ogg
24|24-q%C4%81f.ogg
25|25-k%C4%81f.ogg
26|26-g%C4%81f.ogg
27|27-lam.ogg
28|28-m%C4%ABm.ogg
29|29-n%C5%ABn.ogg
30|30-v%C4%81v.ogg
31|31-he.ogg
32|32-ye.ogg
FILES

make_mp3() {
  local voice="$1" text="$2" output="$3" wav
  wav="/tmp/yasin-alphabet-audio/$(basename "$output" .mp3).wav"
  espeak-ng -v "$voice" -s 136 -p 54 -a 175 -w "$wav" "$text"
  ffmpeg -hide_banner -loglevel error -y -i "$wav" -ac 1 -ar 24000 -codec:a libmp3lame -b:a 48k "$output"
  rm -f "$wav"
  test -s "$output"
}

# Each lesson has a separate letter-name track and three independently playable example words.
while IFS='|' read -r number letter; do
  [ -n "$number" ] || continue
  make_mp3 "en-us+f3" "$letter" "$ROOT/en-letter-$number.mp3"
done <<'LETTERS'
01|A
02|B
03|C
04|D
05|E
06|F
07|G
08|H
09|I
10|J
11|K
12|L
13|M
14|N
15|O
16|P
17|Q
18|R
19|S
20|T
21|U
22|V
23|W
24|X
25|Y
26|Z
LETTERS

while IFS='|' read -r number w1 w2 w3; do
  [ -n "$number" ] || continue
  make_mp3 "fa" "$w1" "$ROOT/fa-word-$number-01.mp3"
  make_mp3 "fa" "$w2" "$ROOT/fa-word-$number-02.mp3"
  make_mp3 "fa" "$w3" "$ROOT/fa-word-$number-03.mp3"
done <<'FAWORDS'
01|آسمان|آهو|آتش
02|انار|اسب|ابر
03|بابا|باران|بادبادک
04|پروانه|پنیر|پرتقال
05|توپ|توت|تابستان
06|ثریا|ثانیه|مثلث
07|جوجه|جارو|جوراب
08|چتر|چای|چرخ
09|حوض|حوله|حلوا
10|خرگوش|خیار|خانه
11|درخت|دریا|دست
12|ذرت|ذره|لذت
13|رنگین‌کمان|روباه|رودخانه
14|زرافه|زنبور|زنگ
15|ژاکت|ژاله|مژه
16|سیب|ستاره|سنجاب
17|شیر|شمع|شکلات
18|صابون|صدف|صندوق
19|ضربان|مریض|حوض
20|طوطی|طلا|طبل
21|ظرف|ظهر|منظره
22|عسل|عروسک|عقاب
23|غاز|غنچه|غذا
24|فیل|فانوس|فرفره
25|قلم|قاشق|قایق
26|کتاب|کبوتر|کیک
27|گلابی|گربه|گلدان
28|لاله|لیوان|لانه
29|ماه|ماهی|مادر
30|نان|نهنگ|نارنگی
31|ورزش|وانت|وزغ
32|هوا|هویج|هندوانه
33|یاس|یخ|یوز
FAWORDS

while IFS='|' read -r number w1 w2 w3; do
  [ -n "$number" ] || continue
  make_mp3 "en-us+f3" "$w1" "$ROOT/en-word-$number-01.mp3"
  make_mp3 "en-us+f3" "$w2" "$ROOT/en-word-$number-02.mp3"
  make_mp3 "en-us+f3" "$w3" "$ROOT/en-word-$number-03.mp3"
done <<'ENWORDS'
01|Apple|Ant|Airplane
02|Ball|Bear|Banana
03|Cat|Car|Cake
04|Dog|Duck|Doll
05|Elephant|Egg|Eagle
06|Fish|Frog|Flower
07|Giraffe|Goat|Grapes
08|House|Horse|Hat
09|Ice cream|Igloo|Insect
10|Juice|Jam|Jellyfish
11|Kite|Key|Kangaroo
12|Lion|Lemon|Leaf
13|Moon|Monkey|Milk
14|Nest|Nose|Nurse
15|Orange|Owl|Octopus
16|Pencil|Panda|Pizza
17|Queen|Quilt|Quiz
18|Rabbit|Rainbow|Robot
19|Sun|Star|Snake
20|Tiger|Tree|Train
21|Umbrella|Unicorn|Up
22|Van|Violin|Volcano
23|Water|Whale|Window
24|Xylophone|X-ray|Xmas tree
25|Yo-yo|Yak|Yellow
26|Zebra|Zoo|Zero
ENWORDS

make_mp3 "fa" "آ مثل آسمان آبی، ا مثل انار دونه‌دونه؛ ب مثل بابای خوبم، پ مثل پروانه توی خونه؛ ت مثل توپ گرد و تند، ث مثل ثریا توی آسمون؛ ج مثل جوجه‌ی زرد، چ مثل چتر توی بارون؛ ح مثل حباب و خنده، خ مثل خرگوش بازیگوش؛ د مثل درخت سبز، ذ مثل ذرت خوشمزه؛ ر مثل رنگین‌کمان، ز مثل زنبور عسل؛ ژ مثل ژاکت گرم، س مثل سیب خوشگل؛ ش مثل شیر جنگل، ص مثل صابون و پاکی؛ ض مثل ضربان قلب، ط مثل طوطی رنگی؛ ظ مثل ظرف غذا، ع مثل عسل شیرین؛ غ مثل غنچه‌ی گل، ف مثل فیل نازنین؛ ق مثل قلم و کاغذ، ک مثل کتاب قصه؛ گ مثل گل توی باغچه، ل مثل لاله؛ م مثل ماه شب‌ها، ن مثل نان تازه؛ و مثل ورزش و شادی، ه مثل هوای تازه؛ ی مثل یاس خوش‌بو، الفبا شد تموم؛ دست بزن و شاد بخون، آفرین به تو گل من!" "$ROOT/fa-alphabet-poem.mp3"
make_mp3 "en-us+f3" "A is for Apple, red and sweet; B is for Ball, bounce to the beat! C is for Cat and D is for Dog; E is for Elephant, big as a log. F is for Fish and G is for Goat; H is for House and I is for Ice cream! J is for Juice and K is for Kite; L is for Lion, roaring with might. M is for Moon and N is for Nest; O is for Orange, juicy and fresh! P is for Pencil and Q is for Queen; R is for Rainbow, colorful and clean. S is for Sun and T is for Tree; U is Umbrella, come sing with me! V is for Van and W is for Whale; X is Xylophone, music we hail! Y is for Yo-yo and Z is for Zebra; now we know our ABC, hooray together!" "$ROOT/en-alphabet-poem.mp3"
cat > "$ROOT/ATTRIBUTION.txt" <<'NOTICE'
OFFLINE ALPHABET AUDIO CREDITS

Persian letter-name recordings:
Files fa-letter-01.ogg through fa-letter-32.ogg
Creator: Roozitaa
Source: Wikimedia Commons, Category:Audio files of Persian alphabet
https://commons.wikimedia.org/wiki/Category:Audio_files_of_Persian_alphabet
License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
https://creativecommons.org/licenses/by-sa/4.0/
The recordings are included unchanged. Please retain this attribution and license notice.

Persian and English example-word clips, and English letter-name clips:
Generated during the Android build with eSpeak NG voices (fa and en-us+f3).
eSpeak NG project: https://github.com/espeak-ng/espeak-ng
NOTICE

echo "Offline alphabet audio generated: $(find "$ROOT" -type f | wc -l) files"
