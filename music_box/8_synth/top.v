module top(
    input CLK100MHZ,
    output [3:0] jd,
    output [3:0] led,
    input [3:0] sw,
    input [3:0] btn
    );

// Set up the signal path to link the speaker to the
// PWM generator.
wire speaker;
reg [3:0] note = 0;
reg [3:0] octave = 0;
reg [7:0] level = 0;
PWM sPWM(.clk(CLK100MHZ), .PWM_in(level), .PWM_out(speaker));

reg [29:0] romdivider = 0;
wire [7:0] romaddress = romdivider[29:23];
wire [3:0] romnote;
wire [3:0] romoctave;
always @(posedge CLK100MHZ) romdivider <= romdivider+1;
sw_ROM swROM(.clk(CLK100MHZ), .address(romaddress), .note(romnote), .octave(romoctave));

wire [6:0] n1_level;
SineSampler primary(.clk(CLK100MHZ), .note(note), .octave(octave), .level(n1_level));
wire [6:0] h1_level;
SineSampler harmonic1(.clk(CLK100MHZ), .note(note), .octave(octave + 1), .level(h1_level));
wire [6:0] h2_level;
SineSampler harmonic2(.clk(CLK100MHZ), .note(note), .octave(octave + 2), .level(h2_level));
wire [6:0] h3_level;
SineSampler harmonic3(.clk(CLK100MHZ), .note(note), .octave(octave + 3), .level(h3_level));

// Set the input to the PWM
always @(posedge CLK100MHZ)
  level <= n1_level +
           (sw[0] ? (h1_level >> 2) : 0) + 
           (sw[1] ? (h2_level >> 3) : 0) +
           (sw[2] ? (h3_level >> 4) : 0);

// Map our buttons to C, D, E, F
always @(posedge CLK100MHZ)
begin
  if(sw[3] == 0)
    begin
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

assign jd[0] = speaker; // Connect speaker wire to output
assign jd[1] = 1;       // Gain control. Set to 1 (low gain)
assign jd[3] = 1;       // Turn amp on

// LEDs to help with debugging
assign led[0] = speaker;   // Current wave form

endmodule

module SineSampler(
    input clk,
    input[3:0] note,
    input[3:0] octave,
    output [6:0] level
);

// We want to move through 128 samples as a
// cycle, so just divide that here.
parameter clkspeed = 100000000 / 128;
reg [15:0] clkdivider = 0;
reg [15:0] sine_counter = 0;
reg [6:0] sample_address = 0;
sine_ROM sine(.clk(clk), .address(sample_address), .level(level));

always @(posedge clk)
case(note)
  // Use the highest octave (8) frequencies so we don't 
  // magnify the rounding errors of using the lowest integer
  // frequencies.
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

always @(posedge clk)
  if(clkdivider > 0)
    if(sine_counter==0)
      begin
        sine_counter <= clkdivider-1;
        sample_address <= sample_address+1;
      end
    else sine_counter <= sine_counter-1;
  else
    begin
      sine_counter <= 0;
    end
endmodule

module PWM(
    input clk,
    input [7:0] PWM_in,
    output PWM_out
);

// Making the cnt register an extra bit wide will reduce
// the volume by 50%, as the maximum duty cycle will only
// be 50%.
reg [8:0] cnt = 0;
always @(posedge clk) cnt <= cnt + 1'b1;

assign PWM_out = (PWM_in > cnt);  // comparator
endmodule

module sine_ROM(
	input clk,
	input [6:0] address,
	output reg [7:0] level
);

always @(posedge clk)
case(address)
    0: level <= 7'd0;
    1: level <= 7'd0;
    2: level <= 7'd0;
    3: level <= 7'd0;
    4: level <= 7'd1;
    5: level <= 7'd1;
    6: level <= 7'd2;
    7: level <= 7'd3;
    8: level <= 7'd4;
    9: level <= 7'd6;
    10: level <= 7'd7;
    11: level <= 7'd9;
    12: level <= 7'd10;
    13: level <= 7'd12;
    14: level <= 7'd14;
    15: level <= 7'd16;
    16: level <= 7'd18;
    17: level <= 7'd21;
    18: level <= 7'd23;
    19: level <= 7'd25;
    20: level <= 7'd28;
    21: level <= 7'd31;
    22: level <= 7'd33;
    23: level <= 7'd36;
    24: level <= 7'd39;
    25: level <= 7'd42;
    26: level <= 7'd45;
    27: level <= 7'd48;
    28: level <= 7'd51;
    29: level <= 7'd54;
    30: level <= 7'd57;
    31: level <= 7'd60;
    32: level <= 7'd63;
    33: level <= 7'd67;
    34: level <= 7'd70;
    35: level <= 7'd73;
    36: level <= 7'd76;
    37: level <= 7'd79;
    38: level <= 7'd82;
    39: level <= 7'd85;
    40: level <= 7'd88;
    41: level <= 7'd91;
    42: level <= 7'd94;
    43: level <= 7'd96;
    44: level <= 7'd99;
    45: level <= 7'd102;
    46: level <= 7'd104;
    47: level <= 7'd106;
    48: level <= 7'd109;
    49: level <= 7'd111;
    50: level <= 7'd113;
    51: level <= 7'd115;
    52: level <= 7'd117;
    53: level <= 7'd118;
    54: level <= 7'd120;
    55: level <= 7'd121;
    56: level <= 7'd123;
    57: level <= 7'd124;
    58: level <= 7'd125;
    59: level <= 7'd126;
    60: level <= 7'd126;
    61: level <= 7'd127;
    62: level <= 7'd127;
    63: level <= 7'd127;
    64: level <= 7'd127;
    65: level <= 7'd127;
    66: level <= 7'd127;
    67: level <= 7'd127;
    68: level <= 7'd126;
    69: level <= 7'd126;
    70: level <= 7'd125;
    71: level <= 7'd124;
    72: level <= 7'd123;
    73: level <= 7'd121;
    74: level <= 7'd120;
    75: level <= 7'd118;
    76: level <= 7'd117;
    77: level <= 7'd115;
    78: level <= 7'd113;
    79: level <= 7'd111;
    80: level <= 7'd109;
    81: level <= 7'd106;
    82: level <= 7'd104;
    83: level <= 7'd102;
    84: level <= 7'd99;
    85: level <= 7'd96;
    86: level <= 7'd94;
    87: level <= 7'd91;
    88: level <= 7'd88;
    89: level <= 7'd85;
    90: level <= 7'd82;
    91: level <= 7'd79;
    92: level <= 7'd76;
    93: level <= 7'd73;
    94: level <= 7'd70;
    95: level <= 7'd67;
    96: level <= 7'd64;
    97: level <= 7'd60;
    98: level <= 7'd57;
    99: level <= 7'd54;
    100: level <= 7'd51;
    101: level <= 7'd48;
    102: level <= 7'd45;
    103: level <= 7'd42;
    104: level <= 7'd39;
    105: level <= 7'd36;
    106: level <= 7'd33;
    107: level <= 7'd31;
    108: level <= 7'd28;
    109: level <= 7'd25;
    110: level <= 7'd23;
    111: level <= 7'd21;
    112: level <= 7'd18;
    113: level <= 7'd16;
    114: level <= 7'd14;
    115: level <= 7'd12;
    116: level <= 7'd10;
    117: level <= 7'd9;
    118: level <= 7'd7;
    119: level <= 7'd6;
    120: level <= 7'd4;
    121: level <= 7'd3;
    122: level <= 7'd2;
    123: level <= 7'd1;
    124: level <= 7'd1;
    125: level <= 7'd0;
    126: level <= 7'd0;
    127: level <= 7'd0;
    default: level <= 8'd0;
endcase
endmodule

module sw_ROM(
	input clk,
	input [7:0] address,
	output reg [3:0] note,
	output reg [3:0] octave
);

reg [7:0] fullnote = 0;

// fullnote == 1 is C4, and this tune only spans
// two octaves, so we can use a simple translation of
// fullnote -> note, octave.
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

always @(posedge clk)
case(address)
	  0: fullnote<= 8'd3;
	  1: fullnote<= 8'd0;
	  2: fullnote<= 8'd3;
	  3: fullnote<= 8'd0;
	  4: fullnote<= 8'd3;
	  5: fullnote<= 8'd0;
	  6: fullnote<= 8'd8;
	  7: fullnote<= 8'd8;
	  8: fullnote<= 8'd8;
	  9: fullnote<= 8'd8;
	 10: fullnote<= 8'd8;
	 11: fullnote<= 8'd8;
	 12: fullnote<= 8'd8;
	 13: fullnote<= 8'd8;
	 14: fullnote<= 8'd15;
	 15: fullnote<= 8'd15;
	 16: fullnote<= 8'd15;
	 17: fullnote<= 8'd15;
	 18: fullnote<= 8'd15;
	 19: fullnote<= 8'd15;
	 20: fullnote<= 8'd15;
	 21: fullnote<= 8'd15;
	 22: fullnote<= 8'd13;
	 23: fullnote<= 8'd13;
	 24: fullnote<= 8'd12;
	 25: fullnote<= 8'd12;
	 26: fullnote<= 8'd10;
	 27: fullnote<= 8'd10;
	 28: fullnote<= 8'd20;
	 29: fullnote<= 8'd20;
	 30: fullnote<= 8'd20;
	 31: fullnote<= 8'd20;
	 32: fullnote<= 8'd20;
	 33: fullnote<= 8'd20;
	 34: fullnote<= 8'd20;
	 35: fullnote<= 8'd20;
	 36: fullnote<= 8'd15;
	 37: fullnote<= 8'd15;
	 38: fullnote<= 8'd15;
	 39: fullnote<= 8'd15;
	 40: fullnote<= 8'd15;
	 41: fullnote<= 8'd15;
	 42: fullnote<= 8'd15;
	 43: fullnote<= 8'd15;
	 44: fullnote<= 8'd13;
	 45: fullnote<= 8'd13;
	 46: fullnote<= 8'd12;
	 47: fullnote<= 8'd12;
	 48: fullnote<= 8'd10;
	 49: fullnote<= 8'd10;
	 50: fullnote<= 8'd20;
	 51: fullnote<= 8'd20;
	 52: fullnote<= 8'd20;
	 53: fullnote<= 8'd20;
	 54: fullnote<= 8'd20;
	 55: fullnote<= 8'd20;
	 56: fullnote<= 8'd20;
	 57: fullnote<= 8'd20;
	 58: fullnote<= 8'd15;
	 59: fullnote<= 8'd15;
	 60: fullnote<= 8'd15;
	 61: fullnote<= 8'd15;
	 62: fullnote<= 8'd15;
	 63: fullnote<= 8'd15;
	 64: fullnote<= 8'd15;
	 65: fullnote<= 8'd15;
	 66: fullnote<= 8'd13;
	 67: fullnote<= 8'd13;
	 68: fullnote<= 8'd12;
	 69: fullnote<= 8'd12;
	 70: fullnote<= 8'd13;
	 71: fullnote<= 8'd13;
	 72: fullnote<= 8'd10;
	 73: fullnote<= 8'd10;
	 74: fullnote<= 8'd10;
	 75: fullnote<= 8'd10;
	 76: fullnote<= 8'd10;
	 77: fullnote<= 8'd10;
	 78: fullnote<= 8'd10;
	 79: fullnote<= 8'd10;
	 80: fullnote<= 8'd10;
	 81: fullnote<= 8'd10;
	 82: fullnote<= 8'd10;
	 83: fullnote<= 8'd10;
	default: fullnote <= 8'd0;
endcase
endmodule