Music Player
===

This follows the tutorial from https://www.fpga4fun.com/MusicBox3.html and
https://www.fpga4fun.com/MusicBox4.html.

Ok now that we can generate tones, let's play some tunes.

There was a lot of great stuff to learn in this tutorial, but some sections
were glossed over quickly and took a bit of unpacking to understand. I'm
not going to repeat what the tutorial covers, but try to dive into a couple
of the concepts. I also set up the system that calculates the clock divider
for the notes differently.

The note and octave counters
---

The basic idea here is that we are dividing our master clock (100MHz) down
to twice the frequency of the note we want to play. So for A2 (110Hz), we
need to toggle the speaker at a speed of 100MHz / (110 * 2).

The 100MHz clock is divided effectively by a nested loop of reducing
`counter_note` to zero for `counter_octave` iterations:

```
for i in range(counter_octave):
  for j in range(counter_note):
    clock
```

For each increase in octave we want to double the frequency, or halve the
divider. The way this is done is by halving the outer loop through using
the following table of values for `counter_octave` (The -1 is done since
the zero value counts as an iteration):

```
counter_octave = 256-1 when octave == 0
counter_octave = 128-1 when octave == 1
counter_octave = 64-1  when octave == 2
counter_octave = 32-1  when octave == 3
counter_octave = 16-1  when octave == 4
counter_octave = 8-1   when octave == 5
```

So our clock divider becomes:

  100MHz / (max(`counter_note`) * max(`counter_octave`) * 2)

Which is equivalent to:

  100MHz / max(`counter_note`) / max(`counter_octave`) / 2

Hopefully you can see that as the octave value goes up, it is halving
the value of max(`counter_octave`) which has the effect of halving the
clock divider itself.

It would be nice if max(`counter_note`) was calculated from the frequency
of the note in the lowest octave. So A2, or `octave` == 0 and thus
max(`counter_octave`) == 255:

```
  A2Divider = 100MHz / 110 / 256 / 2 - 1
  A2Divider = 100MHz / 110 / 512 - 1
```

So now we can create a slightly more intuitive note table where the changing
number is simply the frequency value of that note in the lowest (second)
octave:

```verilog
always @(note)
case(note)
  0: clkdivider = clkspeed / 512 / 110 - 1; // A (second octave)
  1: clkdivider = clkspeed / 512 / 117 - 1; // A#/Bb
  2: clkdivider = clkspeed / 512 / 123 - 1; // B
  3: clkdivider = clkspeed / 512 / 131 - 1; // C
  4: clkdivider = clkspeed / 512 / 139 - 1; // C#/Db
  5: clkdivider = clkspeed / 512 / 147 - 1; // D
  6: clkdivider = clkspeed / 512 / 156 - 1; // D#/Eb
  7: clkdivider = clkspeed / 512 / 165 - 1; // E
  8: clkdivider = clkspeed / 512 / 175 - 1; // F
  9: clkdivider = clkspeed / 512 / 185 - 1; // F#/Gb
  10: clkdivider = clkspeed / 512 / 196 - 1; // G
  11: clkdivider = clkspeed / 512 / 208 - 1; // G#/Ab
	default: clkdivider = 8'd0; // should never happen
endcase
```

An Extra Tune
---
The supplied tune was nice, but it would be fun to add another one and
tie it to a switch so that we can have more than one playable tune.

One thing that wasn't clear in the tutorial was that the music_ROM module
is defined in the supplied verilog file. In this case, the two ROMs are
included in the `top.v` file in this directory.

```verilog
wire [7:0] swnote;
wire [7:0] rudolphnote;
sw_ROM swROM(.clk(CLK100MHZ), .address(tone[29:23]), .note(swnote));
rudolph_ROM rudolphROM(.clk(CLK100MHZ), .address(tone[31:24]), .note(rudolphnote));

reg [7:0] fullnote;
always @(posedge CLK100MHZ)
  if(sw[1])
    fullnote <= swnote;
  else
    fullnote <= rudolphnote;
```

So it is running both ROM's into their respective notes, and simply applying
one of them to the fullnote value based on the SW1 position. I also removed
the long pause at the end of the song by dropping the `tone[30]==0` condition
within the speaker toggle:

```verilog
always @(posedge CLK100MHZ) if(counter_note==0 && counter_octave==0 && fullnote != 0) speaker <= ~speaker;
```