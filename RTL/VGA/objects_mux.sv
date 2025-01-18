
// (c) Technion IIT, Department of Electrical Engineering 2021 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
		   // airplane
					input		logic	airplaneDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] airplaneRGB, 
					     
		  // bird 
					input		logic birdDrawingRequest,
					input		logic [7:0] birdRGB,
					
			// pig
					input		logic pigDrawingRequest,
					input		logic [7:0] pigRGB,
		  
		  
		  // fortress
					input		logic fortressDrawingRequest,
					input		logic [7:0] fortressRGB,
					
		  
		  ////////////////////////
		  // background   
					input		logic	[7:0] backGroundRGB, 
					input		logic	BGDrawingRequest, 
					input		logic	[7:0] RGB_MIF, 
			  
				   output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		if (birdDrawingRequest == 1'b1 )   
			RGBOut <= birdRGB;  
			
		else if (airplaneDrawingRequest == 1'b1 )   
			RGBOut <= airplaneRGB; 
			
		else if (pigDrawingRequest == 1'b1 )   
			RGBOut <= pigRGB; 
			
		else if (fortressDrawingRequest == 1'b1 )   
			RGBOut <= fortressRGB;  
//--------------------------------------------------------------------------------------------		


		else if (BGDrawingRequest == 1'b1)
				RGBOut <= backGroundRGB ;
		//else RGBOut <= RGB_MIF ;// last priority 
		else RGBOut <= 8'hFE;
		end ; 
	end

endmodule


