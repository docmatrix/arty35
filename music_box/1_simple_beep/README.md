Simple Beep
===

This follows the tutorial from https://www.fpga4fun.com/MusicBox1.html.

The general goal here is to generate a 440hz tone from a square wave. What that
means is we need to drive a pin where for half of the 440hz cycle the pin is
high, and the other half is low.

If we were to simply use our 100MHz clock to toggle the pin high and low, then
that would give us a tone of 50MHz. If we did that every second clock cycle, we
would get 25MHz and so on. So what we want to do is divide that clock down until
we get 440Hz.

One way to do this is to figure out how many clock cycles it takes to count up
to half of the target frequency. That is: clock_speed / target_freq / 2.

So:

```verilog
reg [16:0] counter;
reg speaker;
parameter clkdivider = 100000000/440/2;  // This fits in 17 bits, hence the counter size
```

As described in the comment, the `counter` register needs to be wide enough to
fit the maximum value, so one way to do that is to calculate the clkdivider
(113637) and see what power of 2 we need to beat that (2^17).

Now, set our counter to the clkdivider value, count down once per clock cycle
from there and then reset the counter. This means that every 113637 cycles
we will get counter == 0, or exactly how often we need to toggle our speaker
pin to get a 440Hz tone.

```verilog
always @(posedge CLK100MHZ) if(counter==0) counter <= clkdivider-1; else counter <= counter-1;
always @(posedge CLK100MHZ) if(counter==0) speaker <= ~speaker;
```

That's it! Check out top.v for the full code, along with some extra bits like
reducing the time that the high signal is *actually* high to lower the volume,
as well as adding in some switches and LED indicators.
