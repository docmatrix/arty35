module top(
    input CLK100MHZ,
    output [3:0] jd,
    output [3:0] led,
    input [3:0] sw
    );

parameter clkspeed = 100000000;
reg speaker;

// Need 12 bits to fit the maximum divider of 1775 (100000000 / 512 / 110)
reg [11:0] clkdivider;
reg [11:0] counter_note;
reg [7:0] counter_octave;

reg [33:0] tone;
always @(posedge CLK100MHZ) tone <= tone+1;

wire [7:0] swnote;
wire [7:0] rudolphnote;
sw_ROM swROM(.clk(CLK100MHZ), .address(tone[29:23]), .note(swnote));
rudolph_ROM rudolphROM(.clk(CLK100MHZ), .address(tone[31:24]), .note(rudolphnote));

reg [7:0] fullnote;
always @(posedge CLK100MHZ)
  if(sw[1])
    fullnote <= swnote;
  else
    fullnote <= rudolphnote;

wire [2:0] octave;
wire [3:0] note;
divide_by12 divby12(.numer(fullnote[5:0]), .quotient(octave), .remain(note));

// The lowest A note we want is A2, which is 110hz.
// We know that the octave modifier will multiply the divider
// by 256 for the lowest note, so our note divider should
// take the form of 100MHz / 256 / target_freq / 2 OR
//                  100MHz / 512 / target_freq
always @(note)
case(note)
  0: clkdivider = clkspeed / 512 / 110 - 1; // A (second octave)
  1: clkdivider = clkspeed / 512 / 117 - 1; // A#/Bb
  2: clkdivider = clkspeed / 512 / 123 - 1; // B
  3: clkdivider = clkspeed / 512 / 131 - 1; // C
  4: clkdivider = clkspeed / 512 / 139 - 1; // C#/Db
  5: clkdivider = clkspeed / 512 / 147 - 1; // D
  6: clkdivider = clkspeed / 512 / 156 - 1; // D#/Eb
  7: clkdivider = clkspeed / 512 / 165 - 1; // E
  8: clkdivider = clkspeed / 512 / 175 - 1; // F
  9: clkdivider = clkspeed / 512 / 185 - 1; // F#/Gb
  10: clkdivider = clkspeed / 512 / 196 - 1; // G
  11: clkdivider = clkspeed / 512 / 208 - 1; // G#/Ab
	default: clkdivider = 8'd0; // should never happen
endcase

always @(posedge CLK100MHZ)
  if(counter_note==0)
    counter_note <= clkdivider;
  else
    counter_note <= counter_note-1;

always @(posedge CLK100MHZ)
if(counter_note==0)
  begin
    if(counter_octave==0)
      counter_octave <= (octave==0?255:octave==1?127:octave==2?63:octave==3?31:octave==4?15:7);
    else
      counter_octave <= counter_octave-1;
  end

always @(posedge CLK100MHZ) if(counter_note==0 && counter_octave==0 && fullnote != 0) speaker <= ~speaker;

// A 7 bit counter is 0 once every 128 cycles.
// At 100MHz, this is too fast to make a sonic difference,
// but will average out the analog signal to a much lower
// volume.
assign jd[0] = speaker & (tone[6:0] == 0);
// Set switch 0 to gain control. 1 is low gain, so lets make that default
assign jd[1] = ~sw[0];
// Set switch 3 to toggle shutdown pin, turning amplifier on and off.
assign jd[3] = sw[3];

// LEDs to help with debugging
assign led[0] = speaker;   // Current wave form
assign led[1] = jd[0];     // Attenuated signal sent to PMOD AMP
assign led[3] = sw[3];     // Sound on or off

endmodule

module divide_by12(numer, quotient, remain);
input [5:0] numer;
output [2:0] quotient;
output [3:0] remain;

reg [2:0] quotient;
reg [3:0] remain_bit3_bit2;

assign remain = {remain_bit3_bit2, numer[1:0]}; // the first 2 bits are copied through

always @(numer[5:2]) // and just do a divide by "3" on the remaining bits
case(numer[5:2])
   0: begin quotient=0; remain_bit3_bit2=0; end
   1: begin quotient=0; remain_bit3_bit2=1; end
   2: begin quotient=0; remain_bit3_bit2=2; end
   3: begin quotient=1; remain_bit3_bit2=0; end
   4: begin quotient=1; remain_bit3_bit2=1; end
   5: begin quotient=1; remain_bit3_bit2=2; end
   6: begin quotient=2; remain_bit3_bit2=0; end
   7: begin quotient=2; remain_bit3_bit2=1; end
   8: begin quotient=2; remain_bit3_bit2=2; end
   9: begin quotient=3; remain_bit3_bit2=0; end
 10: begin quotient=3; remain_bit3_bit2=1; end
 11: begin quotient=3; remain_bit3_bit2=2; end
 12: begin quotient=4; remain_bit3_bit2=0; end
 13: begin quotient=4; remain_bit3_bit2=1; end
 14: begin quotient=4; remain_bit3_bit2=2; end
 15: begin quotient=5; remain_bit3_bit2=0; end
endcase
endmodule


module sw_ROM(
	input clk,
	input [7:0] address,
	output reg [7:0] note
);

always @(posedge clk)
case(address)
	  0: note<= 8'd29;
	  1: note<= 8'd0;
	  2: note<= 8'd29;
	  3: note<= 8'd0;
	  4: note<= 8'd29;
	  5: note<= 8'd0;
	  6: note<= 8'd34;
	  7: note<= 8'd34;
	  8: note<= 8'd34;
	  9: note<= 8'd34;
	 10: note<= 8'd34;
	 11: note<= 8'd34;
	 12: note<= 8'd34;
	 13: note<= 8'd34;
	 14: note<= 8'd41;
	 15: note<= 8'd41;
	 16: note<= 8'd41;
	 17: note<= 8'd41;
	 18: note<= 8'd41;
	 19: note<= 8'd41;
	 20: note<= 8'd41;
	 21: note<= 8'd41;
	 22: note<= 8'd39;
	 23: note<= 8'd39;
	 24: note<= 8'd38;
	 25: note<= 8'd38;
	 26: note<= 8'd36;
	 27: note<= 8'd36;
	 28: note<= 8'd46;
	 29: note<= 8'd46;
	 30: note<= 8'd46;
	 31: note<= 8'd46;
	 32: note<= 8'd46;
	 33: note<= 8'd46;
	 34: note<= 8'd46;
	 35: note<= 8'd46;
	 36: note<= 8'd41;
	 37: note<= 8'd41;
	 38: note<= 8'd41;
	 39: note<= 8'd41;
	 40: note<= 8'd41;
	 41: note<= 8'd41;
	 42: note<= 8'd41;
	 43: note<= 8'd41;
	 44: note<= 8'd39;
	 45: note<= 8'd39;
	 46: note<= 8'd38;
	 47: note<= 8'd38;
	 48: note<= 8'd36;
	 49: note<= 8'd36;
	 50: note<= 8'd46;
	 51: note<= 8'd46;
	 52: note<= 8'd46;
	 53: note<= 8'd46;
	 54: note<= 8'd46;
	 55: note<= 8'd46;
	 56: note<= 8'd46;
	 57: note<= 8'd46;
	 58: note<= 8'd41;
	 59: note<= 8'd41;
	 60: note<= 8'd41;
	 61: note<= 8'd41;
	 62: note<= 8'd41;
	 63: note<= 8'd41;
	 64: note<= 8'd41;
	 65: note<= 8'd41;
	 66: note<= 8'd39;
	 67: note<= 8'd39;
	 68: note<= 8'd38;
	 69: note<= 8'd38;
	 70: note<= 8'd39;
	 71: note<= 8'd39;
	 72: note<= 8'd36;
	 73: note<= 8'd36;
	 74: note<= 8'd36;
	 75: note<= 8'd36;
	 76: note<= 8'd36;
	 77: note<= 8'd36;
	 78: note<= 8'd36;
	 79: note<= 8'd36;
	 80: note<= 8'd36;
	 81: note<= 8'd36;
	 82: note<= 8'd36;
	 83: note<= 8'd36;
	default: note <= 8'd0;
endcase
endmodule

module rudolph_ROM(
	input clk,
	input [7:0] address,
	output reg [7:0] note
);

always @(posedge clk)
case(address)
	  0: note<= 8'd25;
	  1: note<= 8'd27;
	  2: note<= 8'd27;
	  3: note<= 8'd25;
	  4: note<= 8'd22;
	  5: note<= 8'd22;
	  6: note<= 8'd30;
	  7: note<= 8'd30;
	  8: note<= 8'd27;
	  9: note<= 8'd27;
	 10: note<= 8'd25;
	 11: note<= 8'd25;
	 12: note<= 8'd25;
	 13: note<= 8'd25;
	 14: note<= 8'd25;
	 15: note<= 8'd25;
	 16: note<= 8'd25;
	 17: note<= 8'd27;
	 18: note<= 8'd25;
	 19: note<= 8'd27;
	 20: note<= 8'd25;
	 21: note<= 8'd25;
	 22: note<= 8'd30;
	 23: note<= 8'd30;
	 24: note<= 8'd29;
	 25: note<= 8'd29;
	 26: note<= 8'd29;
	 27: note<= 8'd29;
	 28: note<= 8'd29;
	 29: note<= 8'd29;
	 30: note<= 8'd29;
	 31: note<= 8'd29;
	 32: note<= 8'd23;
	 33: note<= 8'd25;
	 34: note<= 8'd25;
	 35: note<= 8'd23;
	 36: note<= 8'd20;
	 37: note<= 8'd20;
	 38: note<= 8'd29;
	 39: note<= 8'd29;
	 40: note<= 8'd27;
	 41: note<= 8'd27;
	 42: note<= 8'd25;
	 43: note<= 8'd25;
	 44: note<= 8'd25;
	 45: note<= 8'd25;
	 46: note<= 8'd25;
	 47: note<= 8'd25;
	 48: note<= 8'd25;
	 49: note<= 8'd27;
	 50: note<= 8'd25;
	 51: note<= 8'd27;
	 52: note<= 8'd25;
	 53: note<= 8'd25;
	 54: note<= 8'd27;
	 55: note<= 8'd27;
	 56: note<= 8'd22;
	 57: note<= 8'd22;
	 58: note<= 8'd22;
	 59: note<= 8'd22;
	 60: note<= 8'd22;
	 61: note<= 8'd22;
	 62: note<= 8'd22;
	 63: note<= 8'd22;
	 64: note<= 8'd25;
	 65: note<= 8'd27;
	 66: note<= 8'd27;
	 67: note<= 8'd25;
	 68: note<= 8'd22;
	 69: note<= 8'd22;
	 70: note<= 8'd30;
	 71: note<= 8'd30;
	 72: note<= 8'd27;
	 73: note<= 8'd27;
	 74: note<= 8'd25;
	 75: note<= 8'd25;
	 76: note<= 8'd25;
	 77: note<= 8'd25;
	 78: note<= 8'd25;
	 79: note<= 8'd25;
	 80: note<= 8'd25;
	 81: note<= 8'd27;
	 82: note<= 8'd25;
	 83: note<= 8'd27;
	 84: note<= 8'd25;
	 85: note<= 8'd25;
	 86: note<= 8'd30;
	 87: note<= 8'd30;
	 88: note<= 8'd29;
	 89: note<= 8'd29;
	 90: note<= 8'd29;
	 91: note<= 8'd29;
	 92: note<= 8'd29;
	 93: note<= 8'd29;
	 94: note<= 8'd29;
	 95: note<= 8'd29;
	 96: note<= 8'd23;
	 97: note<= 8'd25;
	 98: note<= 8'd25;
	 99: note<= 8'd23;
	100: note<= 8'd20;
	101: note<= 8'd20;
	102: note<= 8'd29;
	103: note<= 8'd29;
	104: note<= 8'd27;
	105: note<= 8'd27;
	106: note<= 8'd25;
	107: note<= 8'd25;
	108: note<= 8'd25;
	109: note<= 8'd25;
	110: note<= 8'd25;
	111: note<= 8'd25;
	112: note<= 8'd25;
	113: note<= 8'd27;
	114: note<= 8'd25;
	115: note<= 8'd27;
	116: note<= 8'd25;
	117: note<= 8'd25;
	118: note<= 8'd32;
	119: note<= 8'd32;
	120: note<= 8'd30;
	121: note<= 8'd30;
	122: note<= 8'd30;
	123: note<= 8'd30;
	124: note<= 8'd30;
	125: note<= 8'd30;
	126: note<= 8'd30;
	127: note<= 8'd30;
	128: note<= 8'd27;
	129: note<= 8'd27;
	130: note<= 8'd27;
	131: note<= 8'd27;
	132: note<= 8'd30;
	133: note<= 8'd30;
	134: note<= 8'd30;
	135: note<= 8'd27;
	136: note<= 8'd25;
	137: note<= 8'd25;
	138: note<= 8'd22;
	139: note<= 8'd22;
	140: note<= 8'd25;
	141: note<= 8'd25;
	142: note<= 8'd25;
	143: note<= 8'd25;
	144: note<= 8'd23;
	145: note<= 8'd23;
	146: note<= 8'd27;
	147: note<= 8'd27;
	148: note<= 8'd25;
	149: note<= 8'd25;
	150: note<= 8'd23;
	151: note<= 8'd23;
	152: note<= 8'd22;
	153: note<= 8'd22;
	154: note<= 8'd22;
	155: note<= 8'd22;
	156: note<= 8'd22;
	157: note<= 8'd22;
	158: note<= 8'd22;
	159: note<= 8'd22;
	160: note<= 8'd20;
	161: note<= 8'd20;
	162: note<= 8'd22;
	163: note<= 8'd22;
	164: note<= 8'd25;
	165: note<= 8'd25;
	166: note<= 8'd27;
	167: note<= 8'd27;
	168: note<= 8'd29;
	169: note<= 8'd29;
	170: note<= 8'd29;
	171: note<= 8'd29;
	172: note<= 8'd29;
	173: note<= 8'd29;
	174: note<= 8'd29;
	175: note<= 8'd29;
	176: note<= 8'd30;
	177: note<= 8'd30;
	178: note<= 8'd30;
	179: note<= 8'd30;
	180: note<= 8'd29;
	181: note<= 8'd29;
	182: note<= 8'd27;
	183: note<= 8'd27;
	184: note<= 8'd25;
	185: note<= 8'd25;
	186: note<= 8'd23;
	187: note<= 8'd20;
	188: note<= 8'd20;
	189: note<= 8'd20;
	190: note<= 8'd20;
	191: note<= 8'd20;
	192: note<= 8'd25;
	193: note<= 8'd27;
	194: note<= 8'd27;
	195: note<= 8'd25;
	196: note<= 8'd22;
	197: note<= 8'd22;
	198: note<= 8'd30;
	199: note<= 8'd30;
	200: note<= 8'd27;
	201: note<= 8'd27;
	202: note<= 8'd25;
	203: note<= 8'd25;
	204: note<= 8'd25;
	205: note<= 8'd25;
	206: note<= 8'd25;
	207: note<= 8'd25;
	208: note<= 8'd25;
	209: note<= 8'd27;
	210: note<= 8'd25;
	211: note<= 8'd27;
	212: note<= 8'd25;
	213: note<= 8'd25;
	214: note<= 8'd30;
	215: note<= 8'd30;
	216: note<= 8'd29;
	217: note<= 8'd29;
	218: note<= 8'd29;
	219: note<= 8'd29;
	220: note<= 8'd29;
	221: note<= 8'd29;
	222: note<= 8'd29;
	223: note<= 8'd29;
	224: note<= 8'd23;
	225: note<= 8'd25;
	226: note<= 8'd25;
	227: note<= 8'd23;
	228: note<= 8'd20;
	229: note<= 8'd20;
	230: note<= 8'd29;
	231: note<= 8'd29;
	232: note<= 8'd27;
	233: note<= 8'd27;
	234: note<= 8'd25;
	235: note<= 8'd25;
	236: note<= 8'd25;
	237: note<= 8'd25;
	238: note<= 8'd25;
	239: note<= 8'd25;
	240: note<= 8'd25;
	241: note<= 8'd0;
	242: note<= 8'd00;
	default: note <= 8'd0;
endcase
endmodule
