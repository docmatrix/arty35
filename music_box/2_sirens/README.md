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
The tutorial gives a better description than I could regarding the mechanics
of the ramp bits. Let's just transpose everything a few bits to take into
account the 100MHz clock. Note that we're keeping the ambulance 440Hz divider
as well.

```verilog
parameter tone440 = 100000000/440/2;  // This fits in 17 bits, hence the counter size

reg [30:0] tone;
always @(posedge CLK100MHZ) tone <= tone+1;

wire [6:0] fastramp = (tone[25] ? tone[24:18] : ~tone[24:18]);
wire [6:0] slowramp = (tone[28] ? tone[27:21] : ~tone[27:21]);
wire [16:0] rampdivider = {2'b01, (tone[30] ? slowramp : fastramp), 8'b000000000};
```

Ok cool, so now we can divide our clock either by the tone440 value or by the
rampdivider. So why not tie that decision to a switch and then we can flip
between the fast / slow police siren and the ambulance tone:

```verilog
always @(posedge CLK100MHZ)
  if(counter==0)
    // Let's use switch 1 to toggle between ambulance and police
    if (sw[1])
      counter <= rampdivider;
    else
      counter <= (tone[25] ? tone440-1 : tone440/2-1);
  else
    counter <= counter-1;
```

There we go. A multi-siren generator!
