// (c) Technion IIT, Department of Electrical Engineering 2023 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal Jan 2024

module	airplane_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					// input	 logic enable_sof,    // if want to stop the smiley move
					input	 logic accel_right_key,   //move Y Up   
					input	 logic accel_left_key,      //toggle X   
					input  logic move_down_key,
					input  logic move_up_key,
					input  logic collision,         //collision if smiley hits an object
					input  logic [3:0] HitEdgeCode, //one bit per edge

					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside 
					output logic signed [10:0] vertSpeed
					
);


// a module used to generate the  ball trajectory.  


// movement limits 
const int   OBJECT_WIDTH_X = 64;
const int   OBJECT_HIGHT_Y = 64;
const int	SafetyMargin   =	2;

parameter int INITIAL_X = 200;
parameter int INITIAL_Y = 300;
parameter int MIN_X_SPEED = 70;
parameter int MAX_X_SPEED = 120;
parameter int X_ACCEL = 10;
parameter int LAT_SPEED = 10;

const int MAX_Y_SPEED = 500;
const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


const int	x_FRAME_LEFT	=	(SafetyMargin)* FIXED_POINT_MULTIPLIER; 
const int	x_FRAME_RIGHT	=	(639 - SafetyMargin - OBJECT_WIDTH_X)* FIXED_POINT_MULTIPLIER; 
const int	y_FRAME_TOP		=	(SafetyMargin) * FIXED_POINT_MULTIPLIER;
const int	y_FRAME_BOTTOM	=	(479 -SafetyMargin - OBJECT_HIGHT_Y ) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y
const int	BRACKET_OFFSET =	32;
const int 	LEFT_BRACKET_POS_X = BRACKET_OFFSET+BRACKET_OFFSET/4;
const int	GROUND_Y =	479-(BRACKET_OFFSET+BRACKET_OFFSET/4);
const int 	MIN_Y_POSITION = y_FRAME_TOP+BRACKET_OFFSET*2*FIXED_POINT_MULTIPLIER;
const int 	MAX_Y_POSITION = MIN_Y_POSITION+100*FIXED_POINT_MULTIPLIER;


enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;

int Xspeed  ; // speed    
//int Yspeed  ; 
int Xposition ; //position   
int Yposition ;  

logic accel_right_key_D ;
logic accel_left_key_D ;
logic move_down_key_D ;
logic move_up_key_D ;
  

logic [15:0] hit_reg = 16'b00000;  // register to collect all the collisions in the frame. |corner|left|top|right|bottom|

 //---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= 0 ; 
		Xposition <= 0 ; 
		Yposition <= 0 ; 
		accel_right_key_D <= 0 ;
		accel_left_key_D <= 0 ;
		move_down_key_D <= 0;
		move_up_key_D <= 0;
		hit_reg <= 16'b0 ;	
	
	end 	
	
	else begin
	
		accel_right_key_D <= accel_right_key ;  //shift register to detect edge 
		accel_left_key_D <= accel_left_key ;  //shift register to detect edge 
		move_down_key_D <= move_down_key ;
		move_up_key_D <= move_up_key ;
		
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
				
				Xspeed  <= MIN_X_SPEED ; 
//				Yspeed  <= INITIAL_Y_SPEED  ; 
				Xposition <= x_FRAME_LEFT+OBJECT_WIDTH_X*FIXED_POINT_MULTIPLIER; 
				Yposition <= MIN_Y_POSITION; 
				// if (startOfFrame && enable_sof)   if want to stop the smiley move
				if (startOfFrame) 
					SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving no colision 
		//------------
			  
			
				if ((accel_right_key & !accel_right_key_D) && Xspeed <= MAX_X_SPEED) 
						Xspeed <= Xspeed+X_ACCEL; 
				if ((accel_left_key & !accel_left_key_D) && Xspeed >= MIN_X_SPEED)
						Xspeed <= Xspeed-X_ACCEL; 
						
				if((move_down_key & !move_down_key_D) && Yposition <= MAX_Y_POSITION)
						Yposition <= Yposition + LAT_SPEED*FIXED_POINT_MULTIPLIER;
						
				if((move_up_key & !move_up_key_D) && Yposition-OBJECT_HIGHT_Y >= MIN_Y_POSITION)
						Yposition <= Yposition - LAT_SPEED*FIXED_POINT_MULTIPLIER;
			
//				if((move_down_key & !move_down_key_D) && 
//			
       // collcting collisions 	
				if (collision) begin
					hit_reg[HitEdgeCode]<=1'b1;

				end
				
			
				if (startOfFrame )
					SM_Motion <= START_OF_FRAME_ST ; 
					
					
				
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

			if(hit_reg == 16'h0004 || hit_reg == 16'h0044 || hit_reg == 16'h000C || hit_reg == 16'h0048 || hit_reg == 16'h004C)
				Xposition <=  x_FRAME_LEFT + LEFT_BRACKET_POS_X*FIXED_POINT_MULTIPLIER;
			
			
//			if(Xposition+OBJECT_WIDTH_X*FIXED_POINT_MULTIPLIER == x_FRAME_RIGHT)
//				Xposition <= x_FRAME_LEFT;
				
			hit_reg <= 16'h0000;  //clear for next time 
							
			SM_Motion <= POSITION_CHANGE_ST ; 
			end 

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
	
				Xposition <= Xposition + Xspeed ; 
//				Yposition <= Yposition + Yspeed ;
			 
				// accelerate 
			
//				if (Yspeed < MAX_Y_SPEED ) //  limit the speed while going down 
//   				Yspeed <= Yspeed - Y_ACCEL ; // deAccelerate : slow the speed down every clock tick 
	
//				if ((Yspeed < MAX_Y_speed)&&(Yspeed >0 ))	
//					Yspeed <= Yspeed - Y_ACCEL ; // deAccelerate : slow the speed down every clock tick 
//	
//				else if ((Yspeed > (-MAX_Y_speed))&&(Yspeed < 0 ))
//					Yspeed <= Yspeed + Y_ACCEL ; // deAccelerate : slow the speed down every clock tick
					
				SM_Motion <= POSITION_LIMITS_ST ; 
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------
		if (Xposition < x_FRAME_LEFT) 
						Xposition <= x_FRAME_LEFT ; 
		if (Xposition > x_FRAME_RIGHT)
						Xposition <= x_FRAME_RIGHT ; 
		if (Yposition < y_FRAME_TOP) 
						Yposition <= y_FRAME_TOP ; 
		if (Yposition > y_FRAME_BOTTOM) 
						Yposition <= y_FRAME_BOTTOM ; 

				SM_Motion <= MOVE_ST ; 
			
			end
		
		endcase  // case 

		
	end 

end // end fsm_sync


//return from FIXED point  trunc back to prame size parameters 
  
assign 	topLeftX = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY = Yposition / FIXED_POINT_MULTIPLIER ;    
assign 	vertSpeed = Xspeed ;

endmodule	
//---------------
 
