// BASED ON:
// (c) Technion IIT, Department of Electrical Engineering 2021 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	sound_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
					
		   // hit sound
					input		logic	[3:0] hitNote, 
					input		logic	hitPlayRequest,
		  
		  ////////////////////////
		  // background music
					input		logic	[3:0] musicNote, 
					input		logic	musicPlayRequest,
			  
				   output	logic	[3:0] noteOut,
					output	logic soundEnable
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			noteOut	<= 4'b0;
			soundEnable	<= 1'b0;
	end
	
	else begin
		if (hitPlayRequest == 1'b1) begin  // hit sound has priority
			noteOut <= hitNote;
			soundEnable	<= 1'b1;
		end
			
		else if (musicPlayRequest == 1'b1 ) begin
			noteOut <= musicNote;
			soundEnable	<= 1'b1;
		end

//--------------------------------------------------------------------------------------------		

		else begin
			noteOut	<= 4'b0;
			soundEnable	<= 1'b0;
		end
	end
end

endmodule


