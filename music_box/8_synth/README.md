Self Playing Organ
===

Usage
---
* Use SW[0-2] to add harmonics into the tone.
* Use SW[3] to switch between keyboard mode and a little tune.
* Use BTN[0-3] to play notes C, D, E, F in the 4th octave.

Overview
---
We only have 4 buttons to play with, so why not combine the last tutorial in
the music box series where it would play by itself alongside our mini-organ?

Refactor the Sampler
---
Having to figure out the clock dividers outside of the sampler is a bit of a
pain, so let's bring that into the sampler itself:

```verilog
module SineSampler(
    input clk,
    input[3:0] note,
    input[3:0] octave,
    output [6:0] level
);
```

Now we can simply define which `note` and `octave` to play and let the sampler
do the divider calculation:

```verilog
always @(posedge clk)
case(note)
  1: clkdivider = ((clkspeed / 4186) << (8 - octave)) - 1; // C
  2: clkdivider = ((clkspeed / 4434) << (8 - octave)) - 1; // C#
  3: clkdivider = ((clkspeed / 4698) << (8 - octave)) - 1; // D
  4: clkdivider = ((clkspeed / 4978) << (8 - octave)) - 1; // D#
  5: clkdivider = ((clkspeed / 5274) << (8 - octave)) - 1; // E
  6: clkdivider = ((clkspeed / 5587) << (8 - octave)) - 1; // F
  7: clkdivider = ((clkspeed / 5919) << (8 - octave)) - 1; // F#
  8: clkdivider = ((clkspeed / 6271) << (8 - octave)) - 1; // G
  9: clkdivider = ((clkspeed / 6644) << (8 - octave)) - 1; // G#
  10: clkdivider = ((clkspeed / 7040) << (8 - octave)) - 1; // A
  11: clkdivider = ((clkspeed / 7458) << (8 - octave)) - 1; // A#
  12: clkdivider = ((clkspeed / 7902) << (8 - octave)) - 1; // B
  default: clkdivider = 8'd0; // Silence
endcase
```

Instead of using the 4th octave frequencies here, we're using the 8th
octave. This is to reduce the amount of rounding errors that get introduced
by truncating the decimal part of the frequency. Since each lower octave is
just half the frequency of the higher octave, we can simply double the divider
by left shifting down by the number of octaves from the 8th. So for the 5th
octave, we left shift by 3 (8 - 5 = 3), or double the value three times.

This simplifies the setup of our harmonic wave generators:

```verilog
reg [3:0] note = 0;
reg [3:0] octave = 0;

wire [6:0] n1_level;
SineSampler primary(.clk(CLK100MHZ), .note(note), .octave(octave), .level(n1_level));
wire [6:0] h1_level;
SineSampler harmonic1(.clk(CLK100MHZ), .note(note), .octave(octave + 1), .level(h1_level));
wire [6:0] h2_level;
SineSampler harmonic2(.clk(CLK100MHZ), .note(note), .octave(octave + 2), .level(h2_level));
wire [6:0] h3_level;
SineSampler harmonic3(.clk(CLK100MHZ), .note(note), .octave(octave + 3), .level(h3_level));
```

Play it again Sam
---
Ok so let's grab one of those music rom's from the last of the music box tutorials. There's
a few changes in here to illustrate.

The first is the interface:

```verilog
module sw_ROM(
	input clk,
	input [7:0] address,
	output reg [3:0] note,
	output reg [3:0] octave
);
```

Instead of providing a single register that the caller has to decode into note and octave,
we're getting the ROM to do that for us.

We also change the range of the notes, where 1 is C4:

```verilog
reg [7:0] fullnote = 0;
always @(posedge clk)
case(address)
	  0: fullnote<= 8'd3;
	  1: fullnote<= 8'd0;
	  2: fullnote<= 8'd3;
     ...
	 83: fullnote<= 8'd10;
	default: fullnote <= 8'd0;
endcase
```

And to decode this into a note and octave, we just use a simple set of if conditions since
we know that this tune only requires two octaves:

```verilog
always @(fullnote)
begin
  if (fullnote > 12)
    begin
      octave <= 5;
      note <= (fullnote - 12);
    end
  else if (fullnote > 0)
    begin
      octave <= 4;
      note <= fullnote;
    end
  else
    begin
      octave <= 0;
      note <= 0;
    end
end
```

Then we can hook up the ROM player into `note` and `octave` registers:

```verilog
reg [29:0] romdivider = 0;
wire [7:0] romaddress = romdivider[29:23];
wire [3:0] romnote;
wire [3:0] romoctave;
always @(posedge CLK100MHZ) romdivider <= romdivider+1;
sw_ROM swROM(.clk(CLK100MHZ), .address(romaddress), .note(romnote), .octave(romoctave));
```

`romaddress` is just the upper bits of the `romdivider` counter, in the same way as we did it
in the music box tutorials.

Finally, let's hook up SW[3] to toggle between playing tunes and letting the user tap at their
4-note organ. The other switches will do the same additive harmonics as in the previous tutorial,
both for the tune and for the buttons.

```verilog
always @(posedge CLK100MHZ)
begin
  if(sw[3] == 0)
    begin
      // Map our buttons to C, D, E, F
      octave = 4;
      if(btn[3] == 1) note = 1;
      else if (btn[2] == 1) note = 3;
      else if (btn[1] == 1) note = 5;
      else if (btn[0] == 1) note = 6;
      else note = 0; // Zero is silence.
    end
  else
    begin
      note = romnote;
      octave = romoctave;
    end
end
```

Finale
---

And that's it! I hope you found this interesting and that it gave you some more
opportunity to stretch your FPGA and verilog skills, and maybe even learn a thing
or two about sound and synthesizers.

There's a whole world of things you can do past this, such as using the in-built
Digital Signal Processing IP blocks, adding in modulation to the tone generation,
different waveform shapes and so on. All it takes is a little exploration, some
imagination and a bunch of time :)

Good luck!
