
module	ActionMonitor
		(	
					input		logic	clk,
					input		logic	resetN,
					input		logic birdPigCollision,
					input    logic birdFortCollision,
					input    logic oneSec,
					output	logic [3:0]	intensity  // how much action is happening? 
			);

int actionCounter;
logic fortHitFlag;



always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
	  actionCounter <= 0;
	  intensity <= 4'h3;
	  fortHitFlag <= 1'b1;
	end
			
	else begin
		if (birdPigCollision)
			actionCounter <= actionCounter+8;
		if (birdFortCollision && fortHitFlag) begin
			fortHitFlag <= 1'b0;
			actionCounter <= actionCounter+2;
		end
		if (oneSec && actionCounter>0) begin
			fortHitFlag <= 1'b1;
			actionCounter <= actionCounter-1;
		end
		
		if (actionCounter>10)
			actionCounter <= 10;
		if (actionCounter<0)
			actionCounter <= 0;	
		
		else if (actionCounter>8)
			intensity <= 4'h1;
		else if (actionCounter>4)
			intensity <= 4'h2;
		else 
			intensity <= 4'h3;
	end
end


endmodule

