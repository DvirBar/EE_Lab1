// (c) Technion IIT, Department of Electrical Engineering 2023 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal Jan 2024

module	bird_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					// input	 logic enable_sof,    // if want to stop the smiley move
					input	 logic showBird,   // determines if the bird is displayed    
					input  logic collision,         // collision if bird hits an object
					
					input	 logic [10:0] planeTopLeftX,
					input	 logic [10:0] planeTopLeftY,
					input  logic [10:0] planeVertSpeed,
					input  logic [3:0] HitEdgeCode, //one bit per ,

					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside 
					output logic signed 	[10:0] speedSum,
					output logic displayBird,
					output logic shootBirdPulse
					
);

// TODO: make y speed loss more natural
// TODO: check why the bird doens't disappear
// TODO: check vertical speed 
// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 280;
parameter int INITIAL_Y = 185;
parameter int INITIAL_X_SPEED = 40;
parameter int INITIAL_Y_SPEED = 20;
parameter int Y_ACCEL = -10;

const int MAX_Y_SPEED = 500;
const int	BRACKET_OFFSET =	32;
const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 64;
const int   OBJECT_HIGHT_Y = 64;
const int	SafetyMargin   =	2;
const int 	HIT_SPEED_LOSS = 2;
const int 	SPEED_THRESH = 1;

const int	X_FRAME_LEFT	=	(SafetyMargin)* FIXED_POINT_MULTIPLIER; 
const int	X_FRAME_RIGHT	=	(639 - SafetyMargin - OBJECT_WIDTH_X)* FIXED_POINT_MULTIPLIER; 
const int	Y_FRAME_TOP		=	(SafetyMargin) * FIXED_POINT_MULTIPLIER;
const int	Y_FRAME_BOTTOM	=	(479 -SafetyMargin - OBJECT_HIGHT_Y ) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y

const int 	X_LEFT_HALF = (X_FRAME_RIGHT-X_FRAME_LEFT)/2;


enum  logic [2:0] {IDLE_ST,         	// initial state
					MOVE_ST, 				// moving no colision 
					START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
					POSITION_CHANGE_ST, // position interpolate 
					POSITION_LIMITS_ST, // check if inside the frame  
					HIDE_BIRD_ST
						}  SM_Motion ;

int Xspeed  ; // speed    
int Yspeed  ;  
int Xposition ; //position   
int Yposition ;  
int onGround ;

int XspeedSize;
int YspeedSize;

logic [15:0] hit_reg = 16'b00000;  // register to collect all the collisions in the frame. |corner|left|top|right|bottom|

 //---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= 0   ; 
		Yspeed <= 0  ; 
		Xposition <= 0  ; 
		Yposition <= 0   ; 
		hit_reg <= 16'b0 ;	
		displayBird <= 0 ;
		onGround <= 0 ;
		shootBirdPulse <= 0;
	end 	
	
	else begin
		

	
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		
				Xspeed <= planeVertSpeed; 
				Yspeed  <= 0 ; 
				Xposition <= planeTopLeftX*FIXED_POINT_MULTIPLIER; 
				Yposition <= planeTopLeftY*FIXED_POINT_MULTIPLIER; 
				shootBirdPulse <= 1'b0;
				
				
				// if (startOfFrame && enable_sof)   if want to stop the smiley move
				if (startOfFrame && showBird && Xposition <= X_LEFT_HALF) begin
					SM_Motion <= MOVE_ST;
					displayBird <= 1'b1;
					shootBirdPulse <= 1'b1;
				end
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving no colision 
		//------------
			shootBirdPulse <= 1'b0;
       // collcting collisions 	
				if (collision) begin
					hit_reg[HitEdgeCode]<=1'b1;
				end

				if (startOfFrame ) begin
					SM_Motion <= START_OF_FRAME_ST ; 
				end
		end 
		
		//------------
			START_OF_FRAME_ST:  begin      //check if any colisin was detected 
		//------------
				
	
//		  {32'hC4444446,     
//			32'h8C444462,    
//			32'h88c44622,    
//			32'h888C6222,    
//			32'h88893222,    
//			32'h88911322,    
//			32'h89111132,    
//			32'h91111113};

			// Reduce speed size on collision
			if(hit_reg != 16'h0000) begin // if some collision
				onGround <= 1'b1;
			end

			// Change speed direction in some collisions
			case (hit_reg) 
				16'h0000:  // no collision in the frame 
					begin
						Yspeed <= Yspeed ;
						Xspeed <= Xspeed ;
					end
				//   1H  (1H & 9H) (1H & 3H) (3H & 9H ) (3H & 1H & 9H )
				16'h0002,16'h0202,16'h000A, ,16'h0028 ,16'h002A: // bottom side 
				  begin
						if (Yspeed > 0) begin
							Yspeed <= -Yspeed/HIT_SPEED_LOSS;
						end
						Xspeed <= Xspeed/HIT_SPEED_LOSS;
				  end
				//   CH       6H		3H         9H
				16'h1000,16'h0040,16'h0008,16'h0200:	// one of the four corners 	

				  begin
						Yspeed <= -Yspeed/HIT_SPEED_LOSS;
						Xspeed <= -Xspeed/HIT_SPEED_LOSS;
					end
			//   8H   ; (CH & 8H) ; (8H & 9H) ; (cH & 9H) ;(cH & 9H & 8H)   
				16'h0100,16'h1100,16'h0300,16'h1200,16'h1300:  // left side 
				  begin
						if (Xspeed < 0) 
							Xspeed <= -Xspeed/HIT_SPEED_LOSS;
						Yspeed <= Yspeed/HIT_SPEED_LOSS;
				  end
				//  4H     (CH & 4H)  (4H & 6H) (CH & 6H)  (CH & 4H & 6H)
				16'h0010,16'h1010,16'h0050, 16'h1040 , 16'h1050 : //  top side 
				  begin 
						if (Yspeed < 0)
							Yspeed <= -Yspeed/HIT_SPEED_LOSS;
						Xspeed <= Xspeed/HIT_SPEED_LOSS;
				  end
				//   2H  (2H & 6H) (2H & 3H) (6H & 3H )  (6H & 2H &3H )
				16'h0004,16'h0044,16'h000C, 16'h0048 , 16'h004C: // right side 
				 begin
						if (Xspeed > 0)
							Xspeed <= -Xspeed/HIT_SPEED_LOSS; 
						Yspeed <= Yspeed/HIT_SPEED_LOSS;
				 end
				
				 default:  //complex corner 
				  begin
							Yspeed <= -Yspeed;
							Xspeed <= -Xspeed;
					end
				 

				 endcase
					
				hit_reg <= 16'h0000;  //clear for next time 
		
				SM_Motion <= POSITION_CHANGE_ST ; 
			end 

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
	
				Xposition <= Xposition + Xspeed ; 
				Yposition <= Yposition + Yspeed ;
			 
				// accelerate 
			
				if (Yspeed < MAX_Y_SPEED ) //  limit the speed while going down 
   				Yspeed <= Yspeed - Y_ACCEL ; // deAccelerate : slow the speed down every clock tick 
					
				SM_Motion <= POSITION_LIMITS_ST ; 
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------
				if (Xposition < X_FRAME_LEFT) 
								Xposition <= X_FRAME_LEFT ; 
				if (Xposition > X_FRAME_RIGHT)
								Xposition <= X_FRAME_RIGHT ; 
				if (Yposition < Y_FRAME_TOP) 
								Yposition <= Y_FRAME_TOP ; 
				if (Yposition > Y_FRAME_BOTTOM) 
								Yposition <= Y_FRAME_BOTTOM ; 
								
				speedSum <= (Xspeed < 0 ? -Xspeed : Xspeed) + (Yspeed < 0 ? -Yspeed : Yspeed);
				
				if((Xspeed <= SPEED_THRESH) && (Yspeed <= SPEED_THRESH) && onGround == 1'b1) begin
					SM_Motion <= HIDE_BIRD_ST;
				end
				else
					SM_Motion <= MOVE_ST ; 

				onGround <= 1'b0;
			end

		//------------------------
			HIDE_BIRD_ST : begin  // hides the bird when it becomes stationary and sends a hide pulse to the game manager
		//------------------------
			 	displayBird <= 1'b0;
				SM_Motion <= IDLE_ST;
			end
		endcase  // case 

		
	end 

end // end fsm_sync


//return from FIXED point  trunc back to prame size parameters 
  
assign 	topLeftX = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY = Yposition / FIXED_POINT_MULTIPLIER ; 

endmodule	
//---------------
 
