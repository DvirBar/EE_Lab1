
// Returns a random location from a given set of locations
module	locationRandomizer	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] random,

					output	logic	[10:0] randX,
					output   logic	[10:0] randY
 );
 

 logic [2:0][1:0][10:0] random_locations = {{{11'h300, 11'h300}, {11'h400, 11'h400}, {11'h500, 11'h500}}};
 

//////////--------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		randX <= random_locations[random%$size(random_locations)][2'h0];
		randY <= random_locations[random%$size(random_locations)][2'h1];
	end
end

endmodule