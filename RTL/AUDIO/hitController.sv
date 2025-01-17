/// (c) Technion IIT, Department of Electrical Engineering 2021 (based on)
//-- This module plays ingame music
module	hitController	(	
					input logic clk, 
					input logic resetN,
					input switch,
					input logic hit,
					
					output logic [3:0] hitSound,
					output logic hitEnable
		);

		
logic hitType;	

logic hitFlag;
		
logic [0:1] [3:0]	hitSounds = { 

	4'hC, //hi do
	4'h0  //do
	
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
		hitType <= 1'h0;
		hitEnable = 1'h0;
		hitFlag = 1'b0;
	end 
   
	else begin
		if (hit == 1'b1)
			hitFlag = 1'b1;
		
		if (switch ==  1'b1) begin
			if (hitFlag) begin
				hitType <= 1'h0;
				hitEnable = 1'h1;
				hitFlag = 1'b0;
			end
			else begin
				hitEnable = 1'h0;
			end
		end
	end //else
		
end // always sync




assign 	hitSound = hitSounds[hitType] ; 

endmodule






















































