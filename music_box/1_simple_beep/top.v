module top(
    // ***(A)***
    input CLK100MHZ,
    output [3:0] jd,
    output [3:0] led,
    input [3:0] sw
    );

// ***(B)***
// first create an 18bit binary counter  
reg [17:0] counter;
always @(posedge CLK100MHZ) counter <= counter+1;

// and use the most significant bit (MSB) of the counter to drive the speaker
wire speaker_out = counter[17];


// ***(C)***
// EITHER 
// (1) you wish to annoy your neighbors, so send through the full speaker volume,  
//assign jd[0] = speaker_out
// OR 
// (2) just send through the 1/64th of the signal by only sending signal when last 6 bits of counter are zero 
assign jd[0] = speaker_out & (counter[6:0] == 0);

// ***(D)***
// Set switch 3 to toggle shutdown pin, turning amplifier on and off.
// If you have housemates/family at home, you almost certainly need this
assign jd[3] = sw[3];
   
// ***(E)***
// LEDs to help with debugging
assign led[0] = speaker_out;   // Current wave form
assign led[1] = jd[0];         // Attenuated signal sent to PMOD AMP
assign led[3] = sw[3];

endmodule

