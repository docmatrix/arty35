PWM Sine Wave
===

Usage
---
* Use SW[1] to toggle between a square and sine wave.
* Use SW[3] to toggle a the amp on / off.

Overview
---
Compared to a square wave, a sine wave is a very pure tone and also a common
building block for interesting sounds. We're going to do that by using a lookup
table of sine values, broken up into 128 samples. We will iterate over those
samples and send it to the PWM module at the target frequency * 128
which should give us a nice clean sine tone.

Sine ROM
---
Let's set up our sine sample tables first:

```verilog
module sine_ROM(
	input clk,
	input [6:0] address,
	output reg [7:0] level
);

always @(posedge clk)
case(address)
    0: level <= 7'd64;
    1: level <= 7'd67;
    2: level <= 7'd70;
    3: level <= 7'd73;
    ...
    126: level <= 7'd57;
    127: level <= 7'd60;    
    default: level <= 8'd0;
endcase
endmodule
```

This will map the output `level` of the sinusoid that ranges from [0, 127] based
on the `address` that also happens to range from [0, 127]. We want to increment
`address` at 440Hz * 128 to generate a 440Hz sine tone.

Sine Wave Generator
---
Create an A4 by sending the samples to the PWM at a rate of 440Hz * 128.

```verilog
// Set up 440Hz sine wave signal
parameter sine_clkdivider = clkspeed / 440 / 128;
wire [6:0] sine_level;
reg [15:0] sine_counter = 0;
reg [6:0] sample_address = 0;
always @(posedge CLK100MHZ) if(sine_counter==0) sine_counter <= sine_clkdivider-1; else sine_counter <= sine_counter-1;
always @(posedge CLK100MHZ) if(sine_counter==0) sample_address <= sample_address+1;
sine_ROM sine(.clk(CLK100MHZ), .address(sample_address), .level(sine_level));
```

This is more or less the same as the music player a couple of tutorials ago. Each 128th
of the 440Hz tone, go to the next sample address to send to the PWM.

Now we can assign a switch to toggle between the level requested by the sine ROM, or
the one from the previous square wave generator:

```verilog
always @(posedge CLK100MHZ)
if(sw[1] == 0)
  level <= square_level;
else
  level <= sine_level;  
```

Try toggling between them. Notice how different they sound? This is due to the
harmonic content of the square wave compared to the sine wave. In a square wave,
there is a series of degrading 'odd' harmonics, whereas the sine wave consists
almost only of the primary frequency. We'll use this idea in a future tutorial.
