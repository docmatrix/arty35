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

reg [16:0] counter;
reg speaker;
parameter clkdivider = 100000000/440/2;  // This fits in 17 bits, hence the counter size

always @(posedge CLK100MHZ) if(counter==0) counter <= clkdivider-1; else counter <= counter-1;
always @(posedge CLK100MHZ) if(counter==0) speaker <= ~speaker;

// A 7 bit counter is 0 once every 128 cycles.
// At 100MHz, this is too fast to make a sonic difference,
// but will average out the analog signal to a much lower
// volume.
assign jd[0] = speaker & (counter[6:0] == 0);
// Set switch 0 to gain control. 1 is low gain, so lets make that default
assign jd[1] = ~sw[0];
// Set switch 3 to toggle shutdown pin, turning amplifier on and off.
assign jd[3] = sw[3];

// LEDs to help with debugging
assign led[0] = speaker;   // Current wave form
assign led[1] = jd[0];     // Attenuated signal sent to PMOD AMP
assign led[3] = sw[3];     // Sound on or off

endmodule
