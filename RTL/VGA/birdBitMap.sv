// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2021
// (c) Technion IIT, Department of Electrical Engineering 2021 



module	birdBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic showBird,
					
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,  //rgb value from the bitmap 
					output   logic	[3:0] HitEdgeCode //one bit per edge 
 ) ;

// this is the devider used to acess the right pixel 
localparam  int OBJECT_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 
localparam  int OBJECT_NUMBER_OF_X_BITS = 6;  // 2^6 = 64 


localparam  int OBJECT_HEIGHT_Y = 1 <<  OBJECT_NUMBER_OF_Y_BITS ;
localparam  int OBJECT_WIDTH_X = 1 <<  OBJECT_NUMBER_OF_X_BITS;

// this is the devider used to acess the right pixel 
localparam  int OBJECT_HEIGHT_Y_DIVIDER = OBJECT_NUMBER_OF_Y_BITS - 3; // -2; how many pixel bits are in every collision pixel
localparam  int OBJECT_WIDTH_X_DIVIDER =  OBJECT_NUMBER_OF_X_BITS - 3; // -2

// generating a smiley bitmap

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 

logic [0:31] [0:31] [7:0] object_colors = {
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h8d,8'h8d,8'h91,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h65,8'ha0,8'he0,8'he0,8'ha0,8'hb6,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h24,8'he0,8'he0,8'he0,8'he0,8'hc0,8'h8d,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'ha5,8'ha5,8'ha5,8'h60,8'h60,8'he0,8'he0,8'he0,8'he0,8'he0,8'hb1,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hc0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h60,8'ha0,8'he0,8'he0,8'he0,8'hc0,8'hb6,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h6d,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'ha0,8'hc0,8'he0,8'he1,8'ha5,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'h6d,8'h20,8'h80,8'ha0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'h8d,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'h24,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'hc0,8'h60,8'hb6,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h20,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'he1,8'h80,8'h8d,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hba,8'h20,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'ha0,8'h6d,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hdf,8'h20,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'hc0,8'h8d,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h65,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'ha0,8'hb6,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h80,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h80,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hda,8'hff,8'hff,8'h64,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h60,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'h91,8'hff},
	{8'hff,8'hff,8'hb6,8'h00,8'hb6,8'hb6,8'h80,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h20,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h80,8'h60,8'h80,8'hdf},
	{8'hb6,8'h6d,8'hb6,8'h24,8'h00,8'h64,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h00,8'h00,8'h00,8'h00,8'ha0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'h20,8'h00,8'h00,8'h80,8'hb2},
	{8'h24,8'h00,8'h00,8'h24,8'h00,8'h60,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h20,8'h00,8'h00,8'h00,8'h20,8'ha0,8'hc0,8'h60,8'h00,8'h00,8'h00,8'h20,8'hc0,8'h85},
	{8'h91,8'h6d,8'h24,8'h00,8'h00,8'h80,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hd6,8'hff,8'hb6,8'h24,8'h00,8'h00,8'h00,8'h00,8'h24,8'h91,8'h64,8'he0,8'he0,8'h80},
	{8'hff,8'hff,8'h91,8'h24,8'h00,8'ha0,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'hff,8'hff,8'hda,8'h91,8'hff,8'h91,8'h24,8'h91,8'hff,8'hff,8'hb1,8'hc0,8'he0,8'h80},
	{8'hff,8'hff,8'h24,8'h91,8'h6d,8'hc0,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'he0,8'he0,8'ha0,8'hda,8'hff,8'hba,8'h91,8'hff,8'hda,8'h91,8'h92,8'hd6,8'had,8'h84,8'hc0,8'he0,8'h80},
	{8'hff,8'hff,8'hff,8'hff,8'h6d,8'hc0,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'he0,8'he0,8'hc0,8'h64,8'hb1,8'had,8'h8d,8'hb1,8'hd4,8'hd4,8'h8c,8'h80,8'hc0,8'hc0,8'hc0,8'he0,8'h80},
	{8'hff,8'hff,8'hff,8'hff,8'h6d,8'ha0,8'hc0,8'hc0,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'hc0,8'hc0,8'he0,8'he0,8'hc0,8'hc0,8'hc0,8'ha0,8'hac,8'hf8,8'hf8,8'hf8,8'hf8,8'hd0,8'h80,8'hc0,8'hc0,8'he0,8'h60},
	{8'hff,8'hff,8'hff,8'hff,8'h91,8'ha0,8'hc0,8'hc0,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'hc0,8'hc0,8'he0,8'he0,8'hc0,8'hc0,8'ha0,8'hd0,8'hfc,8'hf8,8'hf8,8'hf8,8'hf8,8'hfc,8'hd4,8'h80,8'he0,8'he0,8'h64},
	{8'hff,8'hff,8'hff,8'hff,8'hb6,8'h60,8'hc0,8'hc0,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he5,8'hed,8'hed,8'hcd,8'h64,8'hf8,8'hf8,8'hfc,8'hf8,8'hf8,8'hf8,8'hf8,8'hfc,8'hd4,8'ha0,8'hc0,8'h6d},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h20,8'hc0,8'hc0,8'hc0,8'hc0,8'hc0,8'he0,8'he0,8'hed,8'hf6,8'hfa,8'hfa,8'hfa,8'hd6,8'h91,8'hd6,8'hb1,8'h8c,8'hd0,8'hd4,8'hf4,8'hf8,8'hf8,8'hfc,8'ha4,8'h60,8'hb6},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h60,8'hc0,8'hc0,8'hc0,8'hc0,8'hed,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'h91,8'hb6,8'hb0,8'hd0,8'hf0,8'hf0,8'hd0,8'hac,8'h8c,8'hf4,8'h8c,8'h24,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h24,8'h80,8'hc0,8'hc0,8'hf1,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hd6,8'h8c,8'hf0,8'hf8,8'hf8,8'hf8,8'hf4,8'ha4,8'he0,8'ha0,8'h20,8'hb6,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'h24,8'h60,8'hf1,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hb1,8'hac,8'hd0,8'hac,8'hb1,8'hf1,8'he0,8'h20,8'h91,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h24,8'h24,8'hb1,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hd5,8'h91,8'hd5,8'hfa,8'hb1,8'h20,8'h91,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h24,8'h24,8'h8d,8'hd5,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hb1,8'h24,8'h24,8'hb6,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h2d,8'h00,8'h24,8'h64,8'h8d,8'h91,8'h91,8'h91,8'h8d,8'h6d,8'h24,8'h20,8'h24,8'h92,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h91,8'h6d,8'h24,8'h24,8'h24,8'h25,8'h6d,8'hb6,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
};


//////////--------------------------------------------------------------------------------------------------------------=
//hit bit map has one bit per edge:  hit_colors[3:0] =   {Left, Top, Right, Bottom}	
//there is one bit per edge, in the corner two bits are set  

//each picture row and column divided to 8 sections 


logic [0:7] [0:7] [3:0] hit_colors = 
		  {32'hC4444446,     
			32'h8C444462,    
			32'h88C44622,    
			32'h888C6222,    
			32'h88893222,    
			32'h88911322,    
			32'h89111132,    
			32'h91111113};
 

 
 
// pipeline (ff) to get the pixel color from the array 	 

//////////--------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		HitEdgeCode <= 4'h0;
	end

	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default  
		HitEdgeCode <= 4'h0;

		if (InsideRectangle == 1'b1 ) 
		begin // inside an external bracket
			//RGBout <= object_colors[offsetY][offsetX];
			RGBout <= object_colors[offsetY][offsetX];
			HitEdgeCode <= hit_colors[offsetY >> OBJECT_HEIGHT_Y_DIVIDER][offsetX >> OBJECT_WIDTH_X_DIVIDER];	//get hitting edge code from the colors table  
			
		end  	
	end
end

//////////--------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = ((RGBout != TRANSPARENT_ENCODING) && showBird && resetN) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule