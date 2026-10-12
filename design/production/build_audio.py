"""Original PCM music and game sound effects. No samples or network calls."""
import array
import json
import math
from pathlib import Path
import random
import wave

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/game/audio"
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
spec = {"sampleRate": RATE, "assets": []}


def save(name, channels, loop=False):
    size = len(channels[0])
    peak = max(max(abs(value) for value in channel) for channel in channels)
    # Keep quiet ambiences quiet; avoid clipping without boosting every file.
    gain = min(1.0, 0.75 / max(peak, 0.0001))
    pcm = array.array("h")
    for frame in range(size):
        for channel in channels:
            pcm.append(round(max(-1, min(1, channel[frame] * gain)) * 32767))
    with wave.open(str(OUT / f"{name}.wav"), "wb") as target:
        target.setnchannels(len(channels))
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(pcm.tobytes())
    spec["assets"].append({"name": name, "seconds": size / RATE,
                           "channels": len(channels), "sampleRate": RATE,
                           "loop": loop, "peak": round(peak * gain, 5)})


def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def note(buffer, start, duration, midi, amplitude, voice="keys", pan=0):
    begin = round(start * RATE)
    length = round(duration * RATE)
    hz = frequency(midi)
    for i in range(length):
        t = i / RATE
        attack = min(1, t / 0.012)
        release = min(1, (duration - t) / 0.08)
        decay = math.exp(-t * (4.5 if voice == "pluck" else 2.2))
        if voice == "bass":
            sample = math.sin(math.tau * hz * t) + .14 * math.sin(math.tau * hz * 2 * t)
        else:
            sample = (math.sin(math.tau * hz * t)
                      + .23 * math.sin(math.tau * hz * 2 * t)
                      + .08 * math.sin(math.tau * hz * 3 * t))
        value = sample * attack * release * decay * amplitude
        index = (begin + i) % len(buffer[0])  # Sustain across the loop seam.
        buffer[0][index] += value * (1 - pan) / 2
        buffer[1][index] += value * (1 + pan) / 2


# Eight bars at 96 BPM, with an original two-bar motif and bossa-style syncopation.
beat = 60 / 96
duration = beat * 32
chords = [[60, 64, 67, 71], [57, 60, 64, 67], [62, 65, 69, 72], [55, 59, 62, 69],
          [60, 64, 67, 69], [57, 61, 64, 67], [62, 65, 69, 72], [55, 59, 62, 65]]
for stage in range(3):
    stereo = [[0.0] * round(duration * RATE) for _ in range(2)]
    for bar, chord in enumerate(chords):
        for offset in [0, 1.5, 2.5]:
            for pitch in chord:
                note(stereo, (bar * 4 + offset) * beat, .65, pitch, .045, pan=-.15)
        for offset, pitch in [(0, chord[0] - 24), (2.5, chord[2] - 24)]:
            note(stereo, (bar * 4 + offset) * beat, .8, pitch, .1, voice="bass")
        if stage >= 1:
            for offset, pitch in zip([.5, 1.5, 3, 3.5], [chord[2] + 12, chord[1] + 12, chord[3] + 12, chord[2] + 12]):
                note(stereo, (bar * 4 + offset) * beat, .35, pitch, .04, voice="pluck", pan=.25)
        if stage >= 2:
            rng = random.Random(700 + bar)
            for tick in range(8):
                begin = round((bar * 4 + tick * .5) * beat * RATE)
                for i in range(round(.045 * RATE)):
                    sample = rng.uniform(-1, 1) * math.exp(-i / (RATE * .009)) * .012
                    index = (begin + i) % len(stereo[0])
                    stereo[0][index] += sample
                    stereo[1][index] += sample * .7
    save(["music-small-district", "music-growing-district", "music-busy-district"][stage], stereo, loop=True)


def tones(name, seconds, events):
    buffer = [[0.0] * round(seconds * RATE) for _ in range(2)]
    for start, duration, midi, volume in events:
        note(buffer, start, duration, midi, volume, voice="pluck")
    save(name, buffer)


tones("lift-ding", 1.2, [(0, .8, 88, .23), (.07, .9, 95, .08)])
tones("financial-closing", .9, [(0, .24, 76, .18), (.11, .26, 81, .18), (.24, .55, 88, .23)])
tones("ui-confirm", .35, [(0, .17, 72, .16), (.09, .2, 79, .16)])
tones("ui-error", .4, [(0, .2, 55, .12), (.12, .24, 52, .12)])

rng = random.Random(1741)
hammer = [0.0] * round(1.4 * RATE)
for start in [.03, .38, .73, 1.08]:
    begin = round(start * RATE)
    for i in range(round(.2 * RATE)):
        t = i / RATE
        hammer[begin + i] += (rng.uniform(-1, 1) * .2 + math.sin(math.tau * 180 * t) * .12) * math.exp(-t * 40)
save("construction-hammer", [hammer])

drill = []
for i in range(round(1.5 * RATE)):
    t = i / RATE
    env = min(1, t / .12, (1.5 - t) / .16)
    drill.append((math.sin(math.tau * 145 * t + .8 * math.sin(math.tau * 31 * t))
                  + .2 * rng.uniform(-1, 1)) * .11 * env)
save("construction-drill", [drill])

ambient, low = [], 0.0
for i in range(round(12 * RATE)):
    t = i / RATE
    low = low * .94 + rng.uniform(-1, 1) * .06
    # Distant traffic and unintelligible crowd-like harmonic beds; no recorded speech.
    hum = .012 * (math.sin(math.tau * 103 * t) + .4 * math.sin(math.tau * 167 * t))
    fade = min(1, t / .5, (12 - t) / .5)
    ambient.append((low * .08 + hum * (.65 + .35 * math.sin(math.tau * t / 4))) * fade)
save("city-ambience", [ambient], loop=True)

(ROOT / "design/production/audio-spec.json").write_text(json.dumps(spec, indent=2) + "\n", encoding="utf-8")
print(f"Created {len(spec['assets'])} original WAV files.")
