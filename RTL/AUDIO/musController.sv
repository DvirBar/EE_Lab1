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
         // level 3  level 2  level 1 
	4'h0, // t = 0    t = 0    t = 0
	4'hC, // t = 1    XXXXX    XXXXX
	4'h7, // t = 2    t = 2    XXXXX
	4'h0, // t = 3    XXXXX    XXXXX
	4'h5, // t = 4    t = 4    t = 4
	4'h0, // t = 5    XXXXX    XXXXX
	4'h7, // t = 6    t = 6    XXXXX
	4'h8, // t = 7    XXXXX    XXXXX
	4'h3, // t = 8    t = 8    t = 8
	4'hC, // t = 9    XXXXX    XXXXX
	4'h7, // t = 10   t = 10   XXXXX
	4'h5, // t = 11   XXXXX    XXXXX
	4'hE, // t = 12   t = 12   t = 12
	4'h7, // t = 13   XXXXX    XXXXX
	4'hA, // t = 14   t = 14   XXXXX
	4'hC, // t = 15   XXXXX    XXXXX
	
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






















































