module top(
    input CLK100MHZ,
    output [3:0] jd,
    output [3:0] led,
    input [3:0] sw,
    input [3:0] btn
    );

// Set up the signal path to link the speaker to the
// PWM generator.
parameter clkspeed = 100000000;
wire speaker;
reg [6:0] level = 0;
PWM sPWM(.clk(CLK100MHZ), .PWM_in(level), .PWM_out(speaker));

// Create square wave signal
reg [4:0] square_level = 0; // Gives a max level of 32 to help control volume.
reg [20:0] square_clkdivider = 0;
reg [20:0] square_counter = 0;
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

// Create sine wave signal (sampled)
wire [6:0] sine_level;
reg [15:0] sine_clkdivider = 0;
reg [15:0] sine_counter = 0;
reg [6:0] sample_address = 0;
sine_ROM sine(.clk(CLK100MHZ), .address(sample_address), .level(sine_level));
always @(posedge CLK100MHZ)
  if(sine_clkdivider > 0)
    if(sine_counter==0)
      begin
        sine_counter <= sine_clkdivider-1;
        sample_address <= sample_address+1;
      end
    else sine_counter <= sine_counter-1;
  else
    begin
      sine_counter <= 0;
    end

// Set the input to the PWM
always @(posedge CLK100MHZ)
  if (sine_clkdivider > 0 || square_clkdivider > 0)
    if(sw[1] == 0)
      level <= square_level;
    else
      level <= sine_level;
    
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
  

assign jd[0] = speaker; // Connect speaker wire to output,
assign jd[1] = 1;       // Gain control. Set to 1 (low gain)
assign jd[3] = sw[3];   // Switch 3 to shutdown pin, turning amplifier on and off.

// LEDs to help with debugging
assign led[0] = speaker;   // Current wave form
assign led[3] = sw[3];     // Sound on or off

endmodule

module PWM(
    input clk,
    input [6:0] PWM_in,
    output PWM_out
);

// Making the cnt register an extra bit wide will reduce
// the volume by 50%, as the maximum duty cycle will only
// be 50%.
reg [7:0] cnt = 0;
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