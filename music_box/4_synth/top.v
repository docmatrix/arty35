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
reg [16:0] level;
reg [6:0] volume_adjust;
always @(posedge CLK100MHZ) volume_adjust <= volume_adjust+1;
PWM sPWM(.clk(CLK100MHZ), .PWM_in(level), .PWM_out(speaker));

// Create a 440HZ square wave signal
parameter clkdivider = clkspeed/440/2;
reg [16:0] counter;
always @(posedge CLK100MHZ) if(counter==0) counter <= clkdivider-1; else counter <= counter-1;
always @(posedge CLK100MHZ) if(counter==0) level <= ~level;

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
    input [16:0] PWM_in,
    output PWM_out
);

// By having a counter that is one bit short of
// the input means that we can produce a full duty
// cycle with all 1's on the input.
reg [15:0] cnt;
always @(posedge clk) cnt <= cnt + 1'b1;

assign PWM_out = (PWM_in > cnt);  // comparator
endmodule

