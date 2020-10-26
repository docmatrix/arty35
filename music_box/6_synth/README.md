PWM Keyboard
===

Usage
---
* Use SW[1] to toggle between a square and sine wave.
* Use BTN[0-3] to play notes C, D, E, F in the 4th octave.

Overview
---
A4 is an awesome note, but it can feel a bit lonely. Let's create a 4-key
keyboard and play with some other notes.

This is an incremental step from the previous tutorial. All we're doing here
is mapping the buttons to different frequencies.

Frequency Mapping
---
There at two clock dividers for the sine wave generator and the square wave.
Map the buttons to C4, D4, E4 and F4 respectively, and note that each button
will take precedence over the previous. In other words, this will only play
one note at a time.

If no button is pressed, then set the dividers at zero which will cause the
system to stop producing sound.

```verilog
// Map our buttons to C, D, E, F
always @(posedge CLK100MHZ)
if(btn[3] == 1)
  begin
    square_clkdivider <= clkspeed / 262 / 2;
    sine_clkdivider <= clkspeed / 262 / 128;
  end
else if (btn[2] == 1)
  begin
    square_clkdivider <= clkspeed / 294 / 2;
    sine_clkdivider <= clkspeed / 294 / 128;
  end
else if (btn[1] == 1)
  begin
    square_clkdivider <= clkspeed / 330 / 2;
    sine_clkdivider <= clkspeed / 330 / 128;
  end
else if (btn[0] == 1)
  begin
    square_clkdivider <= clkspeed / 349 / 2;
    sine_clkdivider <= clkspeed / 349 / 128;
  end
else
  begin
    square_clkdivider <= 0;
    sine_clkdivider <= 0;
  end
```

We can also use these values to determine whether the amp should be on or not.

```verilog
assign jd[3] = (square_clkdivider > 0 || sine_clkdivider > 0);
```

This frees up our switch, not that we have any use for it yet.

Other Changes
---
Everything else is more or less the same, with the exception of some logic to
pause our wave generators if a button isn't being pressed:

```verilog
always @(posedge CLK100MHZ)
  if(square_clkdivider > 0)
    if(square_counter==0)
      begin
        square_counter <= square_clkdivider-1;
        square_level <= ~square_level;
      end
    else square_counter <= square_counter-1;
  else
    square_counter <= 0;
```

If the button isn't pressed, the clkdivider for that wave generator will be zero,
so we just hold the counter at zero to ensure we don't get any strange runwaway
behaviour.
