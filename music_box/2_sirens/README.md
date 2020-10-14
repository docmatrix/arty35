Sirens
===

This follows the tutorial from https://www.fpga4fun.com/MusicBox2.html.

So now we want to alternate the types of tones generated to create a variety
of sounds you might hear from emergency vehicles.

Ambulance
---

First up, create a tone that alternates in pitch back and forth. In this
example, we set up a much wider counter where we can use any of the bits
from that counter to get various speeds. For the Arty35's 100MHz, we'll
want 26 bits to get down to the recommended 1.5Hz. In fact, let's
have a quick look at the frequencies we can get from the `tone` register:

```verilog
reg [25:0] tone;
always @(posedge CLK100MHZ) tone <= tone+1;

// These values are rounded
// tone[25] = 100MHz / 2^26 = 1.5Hz
// tone[24] = 100MHz / 2^25 = 3.0Hz
// tone[23] = 100MHz / 2^24 = 6.0Hz
// ...
// tone[16] = 100MHz / 2^17 = 762Hz
// tone[15] = 100MHz / 2^16 = 1.5KHz
```

So that's neat. It might be interesting to use those frequencies as clocks,
which is what we're goin to do with the top bit.

```verilog
parameter clkdivider = 100000000/440/2;
always @(posedge CLK100MHZ)
  if(counter==0)
    counter <= (tone[25] ? clkdivider-1 : clkdivider/2-1);
  else
    counter <= counter-1;
always @(posedge CLK100MHZ) if(counter==0) speaker <= ~speaker;
```

So if our counter runs down to zero, we reset it either with our 440Hz divider
(clkdivider - 1), or with an 880Hz divider which is (clkdivider/2 - 1). Note that
you could change this to 550/1100 or 300/600 by changing the base frequency
in the clkdivider parameter. Wee-ooo-wee-ooo-wee-ooo!

Police Siren
---
