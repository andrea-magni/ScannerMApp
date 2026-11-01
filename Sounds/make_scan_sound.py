"""Writes scan.wav: the sound of a code read, a soft two-note chime (C6, G6), 0.22 s.
Plain sine waves with a short attack and an exponential decay: no clicks, nothing harsh."""
import math, struct, wave

RATE = 44100
NOTES = [(1046.50, 0.00, 0.16), (1567.98, 0.06, 0.16)]  # frequency, start, length (s)
LENGTH = 0.22
PEAK = 0.55  # of full scale: loud enough at full media volume, never clipping

samples = [0.0] * int(RATE * LENGTH)
for freq, start, length in NOTES:
    s0 = int(RATE * start)
    for i in range(int(RATE * length)):
        t = i / RATE
        env = min(1.0, t / 0.004) * math.exp(-t / 0.045)  # 4 ms attack, quick decay
        v = math.sin(2 * math.pi * freq * t) + 0.15 * math.sin(4 * math.pi * freq * t)
        if s0 + i < len(samples):
            samples[s0 + i] += env * v
top = max(abs(v) for v in samples)
with wave.open('scan.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
    w.writeframes(b''.join(struct.pack('<h', int(v / top * PEAK * 32767)) for v in samples))
assert abs(max(samples, key=abs)) / top <= 1.0  # normalized, no clipping
print('scan.wav', len(samples), 'samples')
