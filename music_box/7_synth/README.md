Harmonic Organ (Additive Synthesizer)
===

Usage
---
* Use BTN[0-3] to play notes C, D, E, F in the 4th octave.
* Use SW[0-3] to add harmonics into the tone.

Overview
---
Remember a few tutorials ago we mentioned that square waves have a bunch of
odd harmonics that make them sound the way they do?

In this tutorial we're going to add extra harmonics to make our sine wave
sound a bit more interesting.

The basic idea is that you have your note frequency, say 262Hz for C4, and you
can add multiples of that frequency to it at a lower volume for a richer sound.

Sampler Module
---
Given we want to create multiple sine waves, we'll move the sine wave generator
into a module so we can create several of them easily:

```verilog

module SineSampler(
    input clk,
    input[15:0] divider,
    output [6:0] level
);

reg [15:0] sine_counter = 0;
reg [6:0] sample_address = 0;
sine_ROM sine(.clk(clk), .address(sample_address), .level(level));
always @(posedge clk)
  if(divider > 0)
    if(sine_counter==0)
      begin
        sine_counter <= divider-1;
        sample_address <= sample_address+1;
      end
    else sine_counter <= sine_counter-1;
  else
    begin
      sine_counter <= 0;
    end
endmodule
```

This is the same code as we were using before. It needs the clock, the divider for
the note we want to produce and it will give out the level that can be passed into
the PWM module.

Harmonic Instance
---
Now we can instantiate our module a few times for the various harmonics:

```verilog
reg [15:0] n1_clkdivider = 0;
wire [6:0] n1_level;
SineSampler primary(.clk(CLK100MHZ), .divider(n1_clkdivider), .level(n1_level));

reg [15:0] h1_clkdivider = 0;
wire [6:0] h1_level;
SineSampler harmonic1(.clk(CLK100MHZ), .divider(h1_clkdivider), .level(h1_level));

reg [15:0] h2_clkdivider = 0;
wire [6:0] h2_level;
SineSampler harmonic2(.clk(CLK100MHZ), .divider(h2_clkdivider), .level(h2_level));

reg [15:0] h3_clkdivider = 0;
wire [6:0] h3_level;
SineSampler harmonic3(.clk(CLK100MHZ), .divider(h3_clkdivider), .level(h3_level));

reg [15:0] h4_clkdivider = 0;
wire [6:0] h4_level;
SineSampler harmonic4(.clk(CLK100MHZ), .divider(h4_clkdivider), .level(h4_level));
```

So now we have the root note and four harmonics. Note that we're dropping the square
wave generator at this point too.

Next is figuring out the right clkdividers based on the requested note:

```verilog
// Map our buttons to C, D, E, F
always @(posedge CLK100MHZ)
if(btn[3] == 1)
  begin
    n1_clkdivider <= clkspeed / 262 / 128;
    h1_clkdivider <= clkspeed / (262 * 2) / 128;
    h2_clkdivider <= clkspeed / (262 * 3) / 128;
    h3_clkdivider <= clkspeed / (262 * 4) / 128;
    h4_clkdivider <= clkspeed / (262 * 5) / 128;
  end
...
else if (btn[0] == 1)
  begin
    n1_clkdivider <= clkspeed / 349 / 128;
    h1_clkdivider <= clkspeed / (349 * 2) / 128;
    h2_clkdivider <= clkspeed / (349 * 3) / 128;
    h3_clkdivider <= clkspeed / (349 * 4) / 128;
    h4_clkdivider <= clkspeed / (349 * 5) / 128;
  end
else
  begin
    n1_clkdivider <= 0;
    h1_clkdivider <= 0;
    h2_clkdivider <= 0;
    h3_clkdivider <= 0;
    h4_clkdivider <= 0;
  end

```

You can see how each harmonic is an extra multiple of the base frequency. Finally, we
can add these together as the input of the PWM:

```verilog
always @(posedge CLK100MHZ)
  if (n1_clkdivider)
    level <= n1_level +
             (sw[0] ? (h1_level >> 1) : 0) + 
             (sw[1] ? (h2_level >> 2) : 0) +
             (sw[2] ? (h3_level >> 3) : 0) +
             (sw[3] ? (h4_level >> 4) : 0); 
```

By shifting each of the harmonic levels, it's dividing the level each harmonic by
half of the power of the previous harmonic. This will give us a tone similar to what
you'd get from an old style electric organ. Try holding a note while flipping some of
the switches to see what it sounds like with different harmonics. This is a basic
example of what is known as an *additive synthesizer*.

Well, we were going for a more **organic** sound after all! :-D
