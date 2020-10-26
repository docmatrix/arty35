PWM Square Wave
===

Usage
---
* Use SW[3] to toggle a 440Hz square wave tone on the PMod2 amp / speaker.

Overview
---
In the FPGA4Fun music box tutorials, we were able to generate notes and play a
tune, but everything was done with square waves.

Square waves are fine, but have a very distinct, retro / buzzing kind of sound.
In this series of extended tutorials, we extend the idea by utilizing
pulse-width-modulation to create some more organic sounding waveforms.

There are a many good descriptions of [PWM](https://en.wikipedia.org/wiki/Pulse-width_modulation),
so I won't try to rewrite those. In its simplest form, what we're going to do is
drive the speaker pin with a high frequency oscillator to emulate an average
signal voltage to the speaker. By varying the duty cycle of the oscillator
we can drive that voltage signal higher or lower. This should allow us to
generate any kind of audio signal we want to create.

So, first things first, how do we create a PWM output?

PWM Module
---
```verilog
module PWM(
    input clk,
    input [7:0] PWM_in,
    output PWM_out
);
```

**Credit to**: https://www.fpga4fun.com/PWM_DAC_1.html

So this will take in our main clock signal, and then an 8bit representation
of the voltage level we want to produce. 0xFF represents the highest voltage
and 0x00 the lowest. Using 8 bits we can represent 255 levels, which should
be plenty of granularity to generate clean audio.

The actual signal level, or duty cycle calculation, can be quite simple:

```verilog
reg [8:0] cnt = 0;
always @(posedge clk) cnt <= cnt + 1'b1;

assign PWM_out = (PWM_in > cnt);
```

All we do is compare our desired level to a counter. When the counter is lower
than `PWM_in`, the pin drives high and otherwise it drives low. Note that we
have made the `cnt` register an extra bit wider, which means it will always counter
at least twice as high as `PWM_in`, or only produce a maximum of a 50% duty cycle.
This is done simply to control the maximum volume level.

Square Wave Signal
---

Lets drive our PWM generator with a square wave which is quite simple to write:

```verilog
parameter clkdivider = clkspeed/440/2;
reg [16:0] counter;
reg [4:0] level; // Only using 5 of the 7 bits will lower the volume by 4x
always @(posedge CLK100MHZ) if(counter==0) counter <= clkdivider-1; else counter <= counter-1;
always @(posedge CLK100MHZ) if(counter==0) level <= ~level;
```

All we need to do is divide our clock down to twice the target frequency and flip the
desired level from max to zero. Note that we reduce the volume further by only asking
for a maximum level of 32, as with this little PMod amplifier, the maximum PWM duty cycle
is very loud.

Now we can set up the module and hook it to the speaker wire:

```verilog
wire speaker;
PWM sPWM(.clk(CLK100MHZ), .PWM_in(level), .PWM_out(speaker));
assign jd[0] = speaker; // Connect speaker wire to output
```

Great, now we're right back to where we started!