#!/usr/bin/env bash
set -euo pipefail
ROOT="app/src/main/assets/voices"
TMP="/tmp/yasin-alphabet-audio"
mkdir -p "$ROOT" "$TMP"
FIFO="$TMP/persian-tts.fifo"
rm -f "$FIFO"
mkfifo "$FIFO"
python scripts/persian-tts-worker.py < "$FIFO" &
TTS_PID=$!
exec 3>"$FIFO"

make_mp3() {
  local voice="$1" text="$2" output="$3" wav err
  wav="$TMP/$(basename "$output" .mp3).wav"
  if [ "$voice" = "fa" ]; then
    # Reuse one loaded neural Persian model for all clips.
    err="$wav.error"
    rm -f "$wav" "$err"
    printf '%s\\t%s\\n' "$wav" "$text" >&3
    for _ in $(seq 1 600); do
      [ -s "$wav" ] && break
      if [ -f "$err" ]; then cat "$err" >&2; exit 1; fi
      sleep 0.1
    done
    [ -s "$wav" ] || { echo "Persian TTS timed out for: $text" >&2; exit 1; }
  else
    # English alphabet support remains local and bundled as audio.
    espeak-ng -v "$voice" -s 136 -p 54 -a 175 -w "$wav" "$text"
  fi
  ffmpeg -hide_banner -loglevel error -y -i "$wav" -ac 1 -ar 24000 -codec:a libmp3lame -b:a 64k "$output"
  rm -f "$wav" "$wav.error"
  test -s "$output"
}

# All alphabet tracks are generated at build time and bundled in the APK.
# No phone speech engine, network access, or runtime download is required.
while IFS='|' read -r number spoken; do
  [ -n "$number" ] || continue
  make_mp3 "fa" "$spoken" "$ROOT/fa-letter-$number.mp3"
done <<'FALETTERS'
01|آ
02|اَلِف
03|بِ
04|پِ
05|تِ
06|ثِ
07|جیم
08|چِ
09|حِ
10|خِ
11|دال
12|ذال
13|رِ
14|زِ
15|ژِ
16|سین
17|شین
18|صاد
19|ضاد
20|طا
21|ظا
22|عین
23|غین
24|فِ
25|قاف
26|کِ
27|گِ
28|لام
29|مِ
30|نِ
31|واو
32|هِ
33|یِ
FALETTERS

while IFS='|' read -r number letter; do
  [ -n "$number" ] || continue
  make_mp3 "en-us+f3" "$letter" "$ROOT/en-letter-$number.mp3"
done <<'ENLETTERS'
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
ENLETTERS

while IFS='|' read -r number w1 w2 w3; do
  [ -n "$number" ] || continue
  make_mp3 "fa" "$w1، $w2، $w3" "$ROOT/fa-words-$number.mp3"
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
  make_mp3 "en-us+f3" "$w1, $w2, $w3" "$ROOT/en-words-$number.mp3"
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
OFFLINE ALPHABET AUDIO

Persian alphabet names, example words, and Persian alphabet rhyme are generated during the build with Mana-Persian-Piper through persian-speech. English alphabet audio is generated with eSpeak NG.
Persian voice: Mana-Persian-Piper neural voice (generated with persian-speech)
English voice: en-us+f3 (eSpeak NG)
Project and licensing information: https://github.com/espeak-ng/espeak-ng

Audio is bundled into the APK. Alphabet lessons do not use the Android phone speech engine and do not need internet at runtime. Persian audio uses a neural voice trained on the CC0 Mana-TTS Persian speech dataset.
NOTICE

exec 3>&-\nwait "$TTS_PID"\nrm -f "$FIFO"\necho "Offline alphabet audio generated: $(find "$ROOT" -type f | wc -l) files"
