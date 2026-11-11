"""Original pentatonic score and game cues. Requires ffmpeg on PATH."""
import array
import math
import random
import subprocess
from pathlib import Path

RATE = 22050
TAU = math.tau
OUT = Path(__file__).resolve().parents[1] / "game/assets/audio"

# Tempo, root, pentatonic melody with rests, four-bar harmony, percussion.
THEMES = {
    "title": (79, 50, [7,None,12,14,None,12,9,None,7,4,None,7,9,None,2,None], [0,5,0,-3], False),
    "hall": (103, 50, [7,9,None,7,4,None,2,4,7,None,12,9,7,4,None,None], [0,5,-3,0], True),
    "village": (86, 52, [7,None,9,12,14,None,12,None,9,7,None,4,7,None,2,None], [0,5,7,0], False),
    "forge": (112, 45, [12,7,9,None,7,4,2,None,12,14,16,14,12,7,None,None], [0,7,5,-3], True),
    "pool": (91, 48, [2,None,7,9,None,7,4,None,2,None,4,7,None,2,None,None], [0,-3,5,-5], False),
    "palace": (108, 47, [9,7,None,12,9,None,7,4,2,None,7,9,4,2,None,None], [0,5,-3,7], True),
    "peak": (94, 50, [12,None,14,16,19,16,14,None,12,9,7,None,9,4,2,None], [0,5,7,-3], True),
    "battle": (142, 45, [7,9,12,9,7,4,7,9,12,14,16,14,12,9,7,None], [0,-3,5,7], True),
    "boss": (128, 42, [12,12,9,7,9,12,14,None,12,9,7,4,7,9,2,None], [0,5,-3,-5], True),
    "ending": (74, 50, [7,None,12,14,16,None,14,None,12,9,None,7,4,None,2,None], [0,5,-3,0], False),
    "inn": (72, 52, [7,None,9,12,14,None,12,None,9,7,None,4,7,None,2,None], [0,5,-3,0], False),
    "swordhall": (91, 50, [7,9,None,7,4,None,2,4,7,None,12,9,7,4,None,None], [0,7,5,0], False),
    "dawn": (80, 55, [7,None,9,12,14,None,12,None,9,7,None,4,7,9,12,None], [0,5,7,0], False),
    "blood": (62, 48, [7,None,9,12,None,14,12,None,9,7,None,4,2,None,0,None], [0,-3,5,-5], False),
    "peak_final": (133, 50, [7,9,12,14,16,14,12,9,7,9,12,16,19,16,14,12], [0,5,7,-3], True),
}

def pitch(midi):
    return 440 * 2 ** ((midi - 69) / 12)

def mix_note(buffer, start, duration, note, volume, instrument, pan):
    start_sample = int(start * RATE)
    f = pitch(note)
    for i in range(int(duration * RATE)):
        t = i / RATE
        phase = TAU * f * t
        release = min(1, (duration-t)*11)
        if instrument == "flute":
            attack = min(t*11, 1)
            sway = .25 * math.sin(TAU*4.7*t)
            sample = (.80 * math.sin(phase+sway) + .15 * math.sin(phase*2+sway)) * attack * release
        elif instrument == "pad":
            sample = (.7*math.sin(phase) + .2*math.sin(phase*1.005)) * min(t*4, 1) * release
        elif instrument == "drum":
            sample = math.sin(phase + 8*(1-math.exp(-t*31))) * math.exp(-t*18) * release
        else:
            sample = (.66 * math.sin(phase) + .22 * math.sin(phase*2.01) + .12*math.sin(phase*3.03))
            sample *= min(t*95,1) * math.exp(-t*4.8) * release
        j = (start_sample+i) % len(buffer[0])
        buffer[0][j] += sample * volume * (1-pan*.6)
        buffer[1][j] += sample * volume * (1+pan*.6)

def encode(name, left, right):
    pcm = array.array("h")
    for a,b in zip(left,right):
        pcm.extend((round(max(-.98,min(.98,a))*32767),round(max(-.98,min(.98,b))*32767)))
    cmd = ["ffmpeg","-hide_banner","-loglevel","error","-y","-f","s16le","-ar",str(RATE),
           "-ac","2","-i","-","-c:a","libvorbis","-q:a","4",str(OUT/(name+".ogg"))]
    subprocess.run(cmd,input=pcm.tobytes(),check=True)

def music(name, cfg):
    tempo, root, melody, harmony, drum = cfg
    beat=60/tempo
    length=round(RATE*beat*32)
    buffer=[array.array("f",[0])*length for _ in range(2)]
    for bar in range(8):
        offset=bar*beat*4
        chord=root+harmony[bar%4]
        for step in (0,7,12):
            mix_note(buffer,offset,beat*4.5,chord-12+step,.033,"pad",.15)
        for i,step in enumerate((0,7,12,7,4,7,12,7)):
            mix_note(buffer,offset+i*beat*.5,beat*.84,chord+step,.096 if i%2==0 else .054,"pluck",-.35)
        if drum:
            for i in (0,2.5):
                mix_note(buffer,offset+i*beat,.32,32,.14,"drum",0)
        for i in range(4):
            step=melody[(bar*4+i)%len(melody)]
            if step is not None:
                note=root+12+step+(2 if bar==6 else 0)
                mix_note(buffer,offset+i*beat,beat*.92,note,.082,"flute",.26)
                mix_note(buffer,offset+i*beat+beat*.75,beat*.7,note,.021,"pluck",.48)
    encode(name,*buffer)

def effects(only=None):
    cues={"select":[67,74],"confirm":[62,69,74],"clang":[45,52,71],"guard":[39,46],
          "heal":[62,66,69,74],"combo":[50,57,62,69,74,81],"win":[57,62,66,69,74],
          "lose":[55,51,45],"break":[67,61,53],"ferry":[43,55,62,67],
          "mechanism":[40,44,47,52],"signal":[69,76,79],
          "cast_wind":[72,79,84],"cast_cloud":[40,55,60],"cast_frost":[77,84,88],
          "cast_blade":[52,71,76],"cast_dark":[38,45,42]}
    for name,notes in cues.items():
        if only is not None and name not in only:
            continue
        buffer=[array.array("f",[0])*int(RATE*(.37+len(notes)*.058)) for _ in range(2)]
        for i,note in enumerate(notes):
            mix_note(buffer,i*.058,.32,note,.17,"pluck" if name not in ("clang","guard") else "drum",(-1)**i*.26)
        encode(name,*buffer)

if __name__=="__main__":
    OUT.mkdir(parents=True,exist_ok=True)
    for name,cfg in THEMES.items():
        music(name,cfg)
        print(name,flush=True)
    effects()

