// BASED ON
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
			input logic bird_disappear,
			input logic game_start_key,
			input logic cheat_key,

			
			output logic airplaneCollision,
			output logic collisionBird,
			output logic collisionBirdFortress,
			output logic collisionBirdPig,
			output logic [12:0] score,
			output logic [3:0] level,
			output logic [1:0] currScreen,
			output logic SingleHitPulse, // critical code, generating A single pulse in a frame 
			output logic startGame
			
);


assign airplaneCollision = drawing_request_airplane && drawing_request_boarders;
					
assign collisionBird = (drawing_request_bird && drawing_request_boarders) ||
								(drawing_request_bird && drawing_request_fortress)|| 
								(drawing_request_bird && drawing_request_pig)
								;

assign collisionBirdFortress = drawing_request_bird && drawing_request_fortress;
assign collisionBirdPig = drawing_request_bird && drawing_request_pig;


parameter int NUM_PIGS = 3;
parameter int NUM_BIRDS = 10; 
parameter int MAX_LEVEL = 4;

logic [4:0] SCORE_PER_HIT = 5'b10000;
logic [3:0] BONUS_SCORE_PER_BIRD = 4'd5;


logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 

enum  logic [2:0] {START_ST,         	
						GAME_PLAY_ST, 	
						GAME_OVER_ST,			
						GAME_WIN_ST
					}  SM_GAME;
						
int pigs_left;
int birds_left;



always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin 
		SM_GAME <= START_ST;
		level <= 0;
		score <= 0;
		flag	<= 1'b0;
		SingleHitPulse <= 1'b0;
		birds_left <= 0;
		pigs_left <= 0;
		startGame <= 1'b0;
		
	end 
	else begin 
		case(SM_GAME)
			START_ST, GAME_OVER_ST, GAME_WIN_ST: begin
				startGame <= 1'b0;
				if(game_start_key) begin
					score <= 0;
					level <= 0;
					startGame <= 1'b1;
					pigs_left <= NUM_PIGS;
					birds_left <= NUM_BIRDS;
					SM_GAME <= GAME_PLAY_ST;
				end
			end
			
			GAME_PLAY_ST: begin
				startGame <= 1'b1;
				SM_GAME <= GAME_PLAY_ST;
				
				if(bird_disappear) begin
					if(birds_left == 1) begin // Lost game - no more birds left but still more pigs
						SM_GAME <= GAME_OVER_ST;
					end

					birds_left <= birds_left - 1;
				end
				
				if(collisionBirdPig) begin
					score <= score + SCORE_PER_HIT;
					pigs_left <= pigs_left-1;
				
					if(pigs_left == 1) begin // Level has ended
						if(level == MAX_LEVEL) // Either we finish the game or move to the next game
							SM_GAME <= GAME_WIN_ST;
						else
							level <= level+1;
						
						score <= score + (birds_left-1)*BONUS_SCORE_PER_BIRD;
						pigs_left <= NUM_PIGS;
						birds_left <= NUM_BIRDS;
					end
				end
			
				if(cheat_key) begin
					if(level == MAX_LEVEL)
						SM_GAME <= GAME_WIN_ST;
					else begin
						level <= level + 1;
						pigs_left <= NUM_PIGS;
						birds_left <= NUM_BIRDS;
					end
				end
			end
		endcase
			SingleHitPulse <= 1'b0 ; // default 
			if(startOfFrame) 
				flag <= 1'b0 ; // reset for next time 
				
//	---#7 - change the condition below to collision between Smiley and number ---------

if ( collisionBird  && (flag == 1'b0)) begin
			flag	<= 1'b1; // to enter only once 
			SingleHitPulse <= 1'b1 ; 
		end ; 
 
	end 
end


assign currScreen = SM_GAME;

endmodule
