#!/bin/bash
# 도레미파솔라시도 음계별 WAV 파일 생성 (ffmpeg pitch-shift)
# 기준: chime.wav (C4 = 도)

SRC="assets/audio/chime.wav"
OUT_DIR="assets/audio"

# 각 음계의 semitone 수 (C4 기준)
declare -A NOTES
NOTES["note_c4"]=0    # 도
NOTES["note_d4"]=2    # 레  (+2 반음)
NOTES["note_e4"]=4    # 미  (+4 반음)
NOTES["note_f4"]=5    # 파  (+5 반음)
NOTES["note_g4"]=7    # 솔  (+7 반음)
NOTES["note_a4"]=9    # 라  (+9 반음)
NOTES["note_b4"]=11   # 시  (+11 반음)
NOTES["note_c5"]=12   # 도  (+12 반음, 한 옥타브 위)

for NOTE in "${!NOTES[@]}"; do
  SEMITONES="${NOTES[$NOTE]}"
  OUTPUT="$OUT_DIR/${NOTE}.wav"
  
  if [ "$SEMITONES" -eq 0 ]; then
    # 원본 복사
    cp "$SRC" "$OUTPUT"
    echo "Copied: $OUTPUT (no pitch shift)"
  else
    # asetrate + atempo 로 pitch shift
    # 공식: new_rate = original_rate * 2^(semitones/12)
    RATE=$(python3 -c "import math; print(int(44100 * (2 ** ($SEMITONES/12))))")
    ffmpeg -y -i "$SRC" -af "asetrate=$RATE,aresample=44100" "$OUTPUT" 2>/dev/null
    echo "Generated: $OUTPUT ($SEMITONES semitones up)"
  fi
done

echo "Done! All note files generated."
