/// (c) Technion IIT, Department of Electrical Engineering 2021 (based on)
//-- This module plays ingame music
module	musController	(	
					input logic clk, 
					input logic resetN, 
					input logic switchNote,
					input	logic [3:0] intensity, 
					
					output logic [3:0] note,
					output logic noteEnable
		);
		
logic[3:0] t = 4'h0;

logic [0:15] [3:0]	melody = { 

	4'h0, //do
	4'hC, //hi do
	4'h7, //sol
	4'h0, //do
	4'h5, //fa
	4'h0, //do
	4'h7, //sol
	4'h8, //solD
	4'h3, //reD
	4'hC, //hi do
	4'h7, //sol
	4'h5, //fa
	4'hE, //hi re
	4'h7, //sol
	4'hA, //laD
	4'hC, //hi do
	
};

//4'h0, //do
//4'h1, //doD
//4'h2, //re
//4'h3, //reD
//4'h4, //mi
//4'h5, //fa
//4'h6, //faD
//4'h7, //sol
//4'h8, //solD
//4'h9, //la
//4'hA, //laD
//4'hB, //si
//4'hC, //hi do
//4'hD, //hi doD
//4'hE, //hi re
//4'hF, //silence



always @(posedge clk or negedge resetN)
   begin
	   
   if ( !resetN ) begin // Asynchronic reset
			t <= 0;
			noteEnable <= 1'h1;
	end 
   
	else begin
		if (switchNote == 1'b1) begin
			t = t + 4'h1;
			if ((melody[t] == 4'hF)||(intensity==4'h0))
				noteEnable <= 1'b0;
			else begin
				noteEnable <= (t  %  (1<<(intensity-1)) == 0);  // Skips notes depending on game intensity
			end
		end //switch note
	end //else
		
end // always sync




assign 	note = melody[t] ; 

endmodule






















































