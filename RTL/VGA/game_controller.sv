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
			input logic shoot_bird_pulse,
			input logic game_start_key,
			input logic cheat_key,
			input logic display_bird,

			
			output logic airplaneCollision,
			output logic collisionBird,
			output logic collisionBirdFortress,
			output logic collisionBirdPig,
			output logic [11:0] score,
			output logic [3:0] level,
			output logic [1:0] currScreen,
			output logic SingleHitPulse, // critical code, generating A single pulse in a frame 
			output logic startGame,
			output logic [3:0] birdsLeft,
			output logic newLevelPulse
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

const int NUM_BITS = 12;
logic [5:0] SCORE_PER_HIT = 6'b110000;
logic [3:0] BONUS_SCORE_PER_BIRD = 4'd1;
logic [11:0] updatedScore;
int loopCounter = 0;


logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 

enum  logic [2:0] {START_ST,         	
						GAME_PLAY_ST, 	
						GAME_OVER_ST,			
						GAME_WIN_ST,
						UPDATE_SCORE_ST,
						CHANGE_LEVEL_ST
					}  SM_GAME;
						
int pigs_left;
int birds_left;


logic cheat_key_D ;

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin 
		SM_GAME <= START_ST;
		level <= 9;
		score <= 0;
		flag	<= 1'b0;
		SingleHitPulse <= 1'b0;
		birds_left <= 0;
		pigs_left <= 0;
		startGame <= 1'b0;
		cheat_key_D <= 1'b0;
		newLevelPulse <= 1'b0;
		updatedScore <= 6'b0;
		loopCounter <= 0;
		
	end 
	else begin 
		cheat_key_D <= cheat_key;
		
		case(SM_GAME)
			START_ST, GAME_OVER_ST, GAME_WIN_ST: begin
				startGame <= 1'b0;
				level <= 9;
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
				SM_GAME <= GAME_PLAY_ST;
				if(birds_left == 0 && !display_bird) begin // Lost game - no more birds left but still more pigs
						SM_GAME <= GAME_OVER_ST;
				end
				
				startGame <= 1'b1;
				
				newLevelPulse <= 1'b0;
				
				if(shoot_bird_pulse) begin
					birds_left <= birds_left - 1;
				end
				
				if(collisionBirdPig) begin
					SM_GAME <= UPDATE_SCORE_ST;
					updatedScore <= score + SCORE_PER_HIT;
					pigs_left <= pigs_left-1;
				
					if(pigs_left == 1) begin // Level has ended
						updatedScore <= score + (birds_left-1)*BONUS_SCORE_PER_BIRD;
					end
					
					
				end
			
				if(cheat_key & !cheat_key_D) begin
					if(level == MAX_LEVEL)
						SM_GAME <= GAME_WIN_ST;
					else begin
						level <= level + 1;
						pigs_left <= NUM_PIGS;
						birds_left <= NUM_BIRDS;
					end
				end
			end
		
			UPDATE_SCORE_ST: begin
				for(loopCounter=0; loopCounter<NUM_BITS-4; loopCounter = loopCounter+4) begin
					if(updatedScore[loopCounter+3 -: 4] > 9) begin
						updatedScore[loopCounter+4] = updatedScore[loopCounter+4]+1;
						updatedScore[loopCounter+3 -: 4] = updatedScore[loopCounter+3 -: 4] - 10;
					end
				end

				score <= updatedScore;
				SM_GAME <= CHANGE_LEVEL_ST;
			end
			
			CHANGE_LEVEL_ST: begin
				SM_GAME <= GAME_PLAY_ST;
				if(pigs_left == 0) begin // Level has ended
					if(!display_bird) begin
						if(level == MAX_LEVEL) // Either we finish the game or move to the next game
							SM_GAME <= GAME_WIN_ST;
						else begin
							level <= level+1;
							newLevelPulse <= 1'b1;
						end
						pigs_left <= NUM_PIGS;
						birds_left <= NUM_BIRDS;
					end
					else
						SM_GAME <= CHANGE_LEVEL_ST;
				end
			end
		endcase
			SingleHitPulse <= 1'b0 ; // default 
			if(startOfFrame) 
				flag <= 1'b0 ; // reset for next time 
				
//	---#7 - change the condition below to collision between Smiley and number ---------

if (collisionBird  && (flag == 1'b0)) begin
			flag	<= 1'b1; // to enter only once 
			SingleHitPulse <= 1'b1 ; 
		end ; 
 
	end 
end

assign birdsLeft = birds_left;
assign currScreen = SM_GAME;

endmodule
