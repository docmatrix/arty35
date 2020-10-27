/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
reg [4:0] level; // Only using 5 of the 7 bits will lower the volume by 4x
PWM sPWM(.clk(CLK100MHZ), .PWM_in(level), .PWM_out(speaker));

// Create a 440HZ square wave signal
parameter clkdivider = clkspeed/440/2;
reg [16:0] counter;
always @(posedge CLK100MHZ) if(counter==0) counter <= clkdivider-1; else counter <= counter-1;
always @(posedge CLK100MHZ) if(counter==0) level <= ~level;

assign jd[0] = speaker; // Connect speaker wire to output
assign jd[1] = 1;       // Gain control. Set to 1 (low gain)
assign jd[3] = sw[3];   // Turn amp on / off

// LEDs to help with debugging
assign led[0] = speaker;   // Current wave form

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

assign PWM_out = (PWM_in > cnt);
endmodule
