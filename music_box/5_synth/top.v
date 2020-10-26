module top(
    input CLK100MHZ,
    output [3:0] jd,
    output [3:0] led,
    input [3:0] sw
    );

// Set up the signal path to link the speaker to the
// PWM generator.
parameter clkspeed = 100000000;
wire speaker;
reg [6:0] level = 0;
PWM sPWM(.clk(CLK100MHZ), .PWM_in(level), .PWM_out(speaker));

// Create a 440Hz square wave signal
parameter square_clkdivider = clkspeed / 440 / 2;
reg [4:0] square_level = 0; // Gives a max level of 32 to help control volume.
reg [20:0] square_counter = 0;
always @(posedge CLK100MHZ) if(square_counter==0) square_counter <= square_clkdivider-1; else square_counter <= square_counter-1;
always @(posedge CLK100MHZ) if(square_counter==0) square_level <= ~square_level;

// Set up 440Hz sine wave signal
parameter sine_clkdivider = clkspeed / 440 / 128;
wire [6:0] sine_level;
reg [15:0] sine_counter = 0;
reg [6:0] sample_address = 0;
always @(posedge CLK100MHZ) if(sine_counter==0) sine_counter <= sine_clkdivider-1; else sine_counter <= sine_counter-1;
always @(posedge CLK100MHZ) if(sine_counter==0) sample_address <= sample_address+1;
sine_ROM sine(.clk(CLK100MHZ), .address(sample_address), .level(sine_level));

// Set the input level for the PWM
always @(posedge CLK100MHZ)
if(sw[1] == 0)
  level <= square_level;
else
  level <= sine_level;  

assign jd[0] = speaker; // Connect speaker wire to output,
assign jd[1] = ~sw[0];  // Switch 0 to gain control. Default to 1 (low gain)
assign jd[3] = sw[3];   // Switch 3 to shutdown pin, turning amplifier on and off.

// LEDs to help with debugging
assign led[0] = speaker;   // Current wave form
assign led[1] = jd[0];     // Attenuated signal sent to PMOD AMP
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
    0: level <= 7'd64;
    1: level <= 7'd67;
    2: level <= 7'd70;
    3: level <= 7'd73;
    4: level <= 7'd76;
    5: level <= 7'd79;
    6: level <= 7'd82;
    7: level <= 7'd85;
    8: level <= 7'd88;
    9: level <= 7'd91;
    10: level <= 7'd94;
    11: level <= 7'd96;
    12: level <= 7'd99;
    13: level <= 7'd102;
    14: level <= 7'd104;
    15: level <= 7'd106;
    16: level <= 7'd109;
    17: level <= 7'd111;
    18: level <= 7'd113;
    19: level <= 7'd115;
    20: level <= 7'd117;
    21: level <= 7'd118;
    22: level <= 7'd120;
    23: level <= 7'd121;
    24: level <= 7'd123;
    25: level <= 7'd124;
    26: level <= 7'd125;
    27: level <= 7'd126;
    28: level <= 7'd126;
    29: level <= 7'd127;
    30: level <= 7'd127;
    31: level <= 7'd127;
    32: level <= 7'd127;
    33: level <= 7'd127;
    34: level <= 7'd127;
    35: level <= 7'd127;
    36: level <= 7'd126;
    37: level <= 7'd126;
    38: level <= 7'd125;
    39: level <= 7'd124;
    40: level <= 7'd123;
    41: level <= 7'd121;
    42: level <= 7'd120;
    43: level <= 7'd118;
    44: level <= 7'd117;
    45: level <= 7'd115;
    46: level <= 7'd113;
    47: level <= 7'd111;
    48: level <= 7'd109;
    49: level <= 7'd106;
    50: level <= 7'd104;
    51: level <= 7'd102;
    52: level <= 7'd99;
    53: level <= 7'd96;
    54: level <= 7'd94;
    55: level <= 7'd91;
    56: level <= 7'd88;
    57: level <= 7'd85;
    58: level <= 7'd82;
    59: level <= 7'd79;
    60: level <= 7'd76;
    61: level <= 7'd73;
    62: level <= 7'd70;
    63: level <= 7'd67;
    64: level <= 7'd64;
    65: level <= 7'd60;
    66: level <= 7'd57;
    67: level <= 7'd54;
    68: level <= 7'd51;
    69: level <= 7'd48;
    70: level <= 7'd45;
    71: level <= 7'd42;
    72: level <= 7'd39;
    73: level <= 7'd36;
    74: level <= 7'd33;
    75: level <= 7'd31;
    76: level <= 7'd28;
    77: level <= 7'd25;
    78: level <= 7'd23;
    79: level <= 7'd21;
    80: level <= 7'd18;
    81: level <= 7'd16;
    82: level <= 7'd14;
    83: level <= 7'd12;
    84: level <= 7'd10;
    85: level <= 7'd9;
    86: level <= 7'd7;
    87: level <= 7'd6;
    88: level <= 7'd4;
    89: level <= 7'd3;
    90: level <= 7'd2;
    91: level <= 7'd1;
    92: level <= 7'd1;
    93: level <= 7'd0;
    94: level <= 7'd0;
    95: level <= 7'd0;
    96: level <= 7'd0;
    97: level <= 7'd0;
    98: level <= 7'd0;
    99: level <= 7'd0;
    100: level <= 7'd1;
    101: level <= 7'd1;
    102: level <= 7'd2;
    103: level <= 7'd3;
    104: level <= 7'd4;
    105: level <= 7'd6;
    106: level <= 7'd7;
    107: level <= 7'd9;
    108: level <= 7'd10;
    109: level <= 7'd12;
    110: level <= 7'd14;
    111: level <= 7'd16;
    112: level <= 7'd18;
    113: level <= 7'd21;
    114: level <= 7'd23;
    115: level <= 7'd25;
    116: level <= 7'd28;
    117: level <= 7'd31;
    118: level <= 7'd33;
    119: level <= 7'd36;
    120: level <= 7'd39;
    121: level <= 7'd42;
    122: level <= 7'd45;
    123: level <= 7'd48;
    124: level <= 7'd51;
    125: level <= 7'd54;
    126: level <= 7'd57;
    127: level <= 7'd60;    
    default: level <= 8'd0;
endcase
endmodule