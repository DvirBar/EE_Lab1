
// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021


module	game_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz 
			input	logic	drawing_request_airplane,
			input	logic	drawing_request_boarders,
			input logic drawing_request_fortress,
			input logic drawing_request_pig,
			input logic drawing_request_bird,

			
			output logic airplaneCollision,
			output logic collisionBird,
			output logic collisionBirdFortress,
			output logic collisionBirdPig,
			
			output logic SingleHitPulse // critical code, generating A single pulse in a frame 
			
			

//---------------------#3-add collision  smiley and hart   -------------------------------------


//			output logic collision_Smiley_Hart // active in case of collision between Smiley and hart


//---------------------#3-end collision  smiley and hart	--------------------------------------
			


);

// drawing_request_smiley   -->  smiley
// drawing_request_boarders -->  brackets
// drawing_request_number   -->  number/box 

//assign collision = (drawing_request_smiley && drawing_request_boarders);// any collision --> comment after updating with #4 or #5 

//---------------------#4-update  collision  conditions - add collision between smiley and number   ----------------------------




//---------------------#4-end update  collision  conditions	 - add collision between smiley and number	-------------------------
	
					
						

//---------------------#5-update  collision  sconditions - add collision between smiley and hart  ---------------------------------

assign airplaneCollision = drawing_request_airplane && drawing_request_boarders;
					
assign collisionBird = (drawing_request_bird && drawing_request_boarders) ||
								(drawing_request_bird && drawing_request_fortress)|| 
								(drawing_request_bird && drawing_request_pig)
								;

assign collisionBirdFortress = drawing_request_bird && drawing_request_fortress;
assign collisionBirdPig = drawing_request_bird && drawing_request_pig;


//---------------------#5-end update  collision  conditions	- add collision between smiley and hart	-----------------------------
	



//-------------------------- #6-add colision between Smiley and hart-----------------
//
//assign collision_Smiley_Hart = ( drawing_request_smiley && drawing_request_hart ) ;


//---------------------------#6-end colision betweenand Smiley and hart-----------------



logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 
//logic collision_smiley_number; // collision between Smiley and number - is not output


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin 
		flag	<= 1'b0;
		SingleHitPulse <= 1'b0 ; 
		
	end 
	else begin 
	
//-------------------------- #7-add colision between Smiley and number-----------------


//			collision_smiley_number <= drawing_request_smiley && drawing_request_number;
//-------------------------- #7-end colision between Smiley and number-----------------	
		
		
			SingleHitPulse <= 1'b0 ; // default 
			if(startOfFrame) 
				flag <= 1'b0 ; // reset for next time 
				
//	---#7 - change the condition below to collision between Smiley and number ---------

//if ( collision_aiplane_number  && (flag == 1'b0)) begin ///// DOESNT WORK! COMMENTED OUT!!!
//			flag	<= 1'b1; // to enter only once 
//			SingleHitPulse <= 1'b1 ; 
//		end ; 
 
	end 
end

endmodule
