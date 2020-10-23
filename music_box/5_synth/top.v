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
reg [15:0] level;
reg [6:0] volume_adjust;
always @(posedge CLK100MHZ) volume_adjust <= volume_adjust+1;
PWM sPWM(.clk(CLK100MHZ), .PWM_in(level), .PWM_out(speaker));

// Create a 440Hz square wave signal
parameter square_clkdivider = clkspeed / 440 / 2;
reg [15:0] square_level;
reg [20:0] square_counter;
always @(posedge CLK100MHZ) if(square_counter==0) square_counter <= square_clkdivider-1; else square_counter <= square_counter-1;
always @(posedge CLK100MHZ) if(square_counter==0) square_level <= ~square_level;

// Set up 440Hz sine wave signal
parameter sine_clkdivider = clkspeed / 440 / 128;
wire [15:0] sine_level;
reg [15:0] sine_counter;
reg [6:0] sample_address;
always @(posedge CLK100MHZ) if(sine_counter==0) sine_counter <= sine_clkdivider-1; else sine_counter <= sine_counter-1;
always @(posedge CLK100MHZ) if(sine_counter==0) sample_address <= sample_address+1;
sine_ROM sine(.clk(CLK100MHZ), .address(sample_address), .level(sine_level));

// Set the input to the PWM
always @(posedge CLK100MHZ)
if(sw[1] == 0)
  level <= square_level;
else
  level <= sine_level;  

// Connect speaker wire to output, lowering the volume with our
// 7 bit counter. Divides the signal level by 128 times.
assign jd[0] = speaker & (volume_adjust == 0);
// Set switch 0 to gain control. 1 is low gain, so lets make that default
assign jd[1] = ~sw[0];
// Set switch 3 to toggle shutdown pin, turning amplifier on and off.
assign jd[3] = sw[3];

// LEDs to help with debugging
assign led[0] = speaker;   // Current wave form
assign led[1] = jd[0];     // Attenuated signal sent to PMOD AMP
assign led[3] = sw[3];     // Sound on or off

endmodule

module PWM(
    input clk,
    input [15:0] PWM_in,
    output PWM_out
);

reg [15:0] cnt;
always @(posedge clk) cnt <= cnt + 1'b1;

assign PWM_out = (PWM_in > cnt);  // comparator
endmodule

module sine_ROM(
	input clk,
	input [6:0] address,
	output reg [15:0] level
);

always @(posedge clk)
case(address)
    0: level <= 16'd32768;
    1: level <= 16'd34375;
    2: level <= 16'd35979;
    3: level <= 16'd37576;
    4: level <= 16'd39160;
    5: level <= 16'd40729;
    6: level <= 16'd42280;
    7: level <= 16'd43807;
    8: level <= 16'd45307;
    9: level <= 16'd46778;
    10: level <= 16'd48214;
    11: level <= 16'd49614;
    12: level <= 16'd50972;
    13: level <= 16'd52287;
    14: level <= 16'd53555;
    15: level <= 16'd54773;
    16: level <= 16'd55938;
    17: level <= 16'd57047;
    18: level <= 16'd58098;
    19: level <= 16'd59087;
    20: level <= 16'd60013;
    21: level <= 16'd60874;
    22: level <= 16'd61666;
    23: level <= 16'd62389;
    24: level <= 16'd63041;
    25: level <= 16'd63620;
    26: level <= 16'd64125;
    27: level <= 16'd64553;
    28: level <= 16'd64906;
    29: level <= 16'd65181;
    30: level <= 16'd65378;
    31: level <= 16'd65496;
    32: level <= 16'd65535;
    33: level <= 16'd65496;
    34: level <= 16'd65378;
    35: level <= 16'd65181;
    36: level <= 16'd64906;
    37: level <= 16'd64553;
    38: level <= 16'd64125;
    39: level <= 16'd63620;
    40: level <= 16'd63041;
    41: level <= 16'd62389;
    42: level <= 16'd61666;
    43: level <= 16'd60874;
    44: level <= 16'd60013;
    45: level <= 16'd59087;
    46: level <= 16'd58098;
    47: level <= 16'd57047;
    48: level <= 16'd55938;
    49: level <= 16'd54773;
    50: level <= 16'd53555;
    51: level <= 16'd52287;
    52: level <= 16'd50972;
    53: level <= 16'd49614;
    54: level <= 16'd48214;
    55: level <= 16'd46778;
    56: level <= 16'd45307;
    57: level <= 16'd43807;
    58: level <= 16'd42280;
    59: level <= 16'd40729;
    60: level <= 16'd39160;
    61: level <= 16'd37576;
    62: level <= 16'd35979;
    63: level <= 16'd34375;
    64: level <= 16'd32768;
    65: level <= 16'd31160;
    66: level <= 16'd29556;
    67: level <= 16'd27959;
    68: level <= 16'd26375;
    69: level <= 16'd24806;
    70: level <= 16'd23255;
    71: level <= 16'd21728;
    72: level <= 16'd20228;
    73: level <= 16'd18757;
    74: level <= 16'd17321;
    75: level <= 16'd15921;
    76: level <= 16'd14563;
    77: level <= 16'd13248;
    78: level <= 16'd11980;
    79: level <= 16'd10762;
    80: level <= 16'd9597;
    81: level <= 16'd8488;
    82: level <= 16'd7437;
    83: level <= 16'd6448;
    84: level <= 16'd5522;
    85: level <= 16'd4661;
    86: level <= 16'd3869;
    87: level <= 16'd3146;
    88: level <= 16'd2494;
    89: level <= 16'd1915;
    90: level <= 16'd1410;
    91: level <= 16'd982;
    92: level <= 16'd629;
    93: level <= 16'd354;
    94: level <= 16'd157;
    95: level <= 16'd39;
    96: level <= 16'd0;
    97: level <= 16'd39;
    98: level <= 16'd157;
    99: level <= 16'd354;
    100: level <= 16'd629;
    101: level <= 16'd982;
    102: level <= 16'd1410;
    103: level <= 16'd1915;
    104: level <= 16'd2494;
    105: level <= 16'd3146;
    106: level <= 16'd3869;
    107: level <= 16'd4661;
    108: level <= 16'd5522;
    109: level <= 16'd6448;
    110: level <= 16'd7437;
    111: level <= 16'd8488;
    112: level <= 16'd9597;
    113: level <= 16'd10762;
    114: level <= 16'd11980;
    115: level <= 16'd13248;
    116: level <= 16'd14563;
    117: level <= 16'd15921;
    118: level <= 16'd17321;
    119: level <= 16'd18757;
    120: level <= 16'd20228;
    121: level <= 16'd21728;
    122: level <= 16'd23255;
    123: level <= 16'd24806;
    124: level <= 16'd26375;
    125: level <= 16'd27959;
    126: level <= 16'd29556;
    127: level <= 16'd31160;
    default: level <= 8'd0;
endcase
endmodule
