// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024
// good practice code - Dudy MAR 2025

module	bomberman_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input  logic toggle_2,
					input  logic toggle_4,
					input  logic toggle_6,
					input  logic toggle_8,
					input	 logic toggle_x_key,      //mnonsterhitbomber  
					input  logic collision,         //collision if smiley hits an object
					input  logic playerHitFixedWall,
					input  logic [2:0] HitEdgeCode,
				   input  logic noMove,
				   input  logic speedBoost,	
					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside 
					output logic [2:0] direction

);


// a module used to generate the  ball trajectory.  


parameter int INITIAL_X = 280;
parameter int INITIAL_Y = 244;
parameter int INITIAL_X_SPEED = 0;
parameter int INITIAL_Y_SPEED = 0;
parameter int Y_ACCEL = 0;

const int MAX_Y_SPEED = 500;
const int	FIXED_POINT_MULTIPLIER = 8096*8; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions
const int STEP = 1;


// movement limits 
const int   OBJECT_WIDTH_X = 32;
const int   OBJECT_HIGHT_Y = 32;
const int	SafetyMargin   =	28;

const int	x_FRAME_LEFT	=	(37)*FIXED_POINT_MULTIPLIER; 
const int	x_FRAME_RIGHT	=	(639 - (43 * 2)  - OBJECT_WIDTH_X)*FIXED_POINT_MULTIPLIER; 
const int	y_FRAME_TOP		=	(SafetyMargin)*FIXED_POINT_MULTIPLIER ;
const int	y_FRAME_BOTTOM	=	(479 -(SafetyMargin*2) - OBJECT_HIGHT_Y )*FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y

//edges 
	//------------
	//			 434
	//			 1x2
	//			 404
	//

const logic [4:0] CORNER =	5'b10000; 
const logic [3:0] TOP =		 4'b1000; 
const logic [3:0] RIGHT =   4'b0100; 
const logic [3:0] LEFT =	 4'b0010; 
const logic [3:0] BOTTOM =  4'b0001; 


enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST,
						 WAIT_FRAME_ST// check if inside the frame  
						}  BM_Motion ;

int Xspeed  ; // speed    
int Yspeed  ; 
int Xposition ; //position   
int Yposition ;  
int scaleXpos;
int scaleYpos;

logic lock_2, lock_4, lock_6, lock_8, lock;
logic toggle_x_key_D ;

  logic [4:0] hit_reg = 5'b00000;
 //---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		BM_Motion <= IDLE_ST ; 
		Xspeed <= 0   ; 
		Yspeed <= 0  ; 
		Xposition <= 0  ; 
		Yposition <= 0   ;
		lock_2 <= 0;
		lock_4 <= 0;
      lock_6 <= 0;
      lock_8 <= 0;  	
		//toggle_x_key_D <= 0 ;
		hit_reg <= 5'b0 ;	
	
	end 	
	
	else begin
	
		toggle_x_key_D <= toggle_x_key ;  //shift register to detect edge 
		if (!noMove) begin
	
		case(BM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		
				Xspeed  <= INITIAL_X_SPEED ; 
				Yspeed  <= INITIAL_Y_SPEED  ; 
				Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER; 
				Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER;
				scaleXpos <= Xposition*FIXED_POINT_MULTIPLIER;
				scaleYpos <= Yposition*FIXED_POINT_MULTIPLIER;
				
				if (startOfFrame) 
					BM_Motion <= MOVE_ST ;
				
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
			
		//------------
						 
						 if ( playerHitFixedWall && HitEdgeCode == 1) begin
								lock <= 1;
								lock_4 <= 1;
								BM_Motion <= WAIT_FRAME_ST;
							end
						else if ( playerHitFixedWall && HitEdgeCode == 2) begin
								lock <= 1;
								lock_6 <= 1;
								BM_Motion <= WAIT_FRAME_ST;
							end
						else if ( playerHitFixedWall && HitEdgeCode == 0) begin
								lock <= 1;
								lock_2 <= 1;
								BM_Motion <= WAIT_FRAME_ST;
							end
						else if ( playerHitFixedWall && HitEdgeCode == 3) begin
								lock <= 1;
								lock_8 <= 1;
								BM_Motion <= WAIT_FRAME_ST;
							end
						else if ( playerHitFixedWall && HitEdgeCode == 4) begin
								lock <= 1;
								lock_8 <= 1;
								lock_6 <= 1;
								
								BM_Motion <= WAIT_FRAME_ST;
							end
						else if ( playerHitFixedWall && HitEdgeCode == 5) begin
								lock <= 1;
								lock_8 <= 1;
								lock_4 <= 1;
								
								BM_Motion <= WAIT_FRAME_ST;
							end
						else if ( playerHitFixedWall && HitEdgeCode == 6) begin
								lock <= 1;
								lock_6 <= 1;
								lock_2 <= 1;
								
								BM_Motion <= WAIT_FRAME_ST;
							end
						else if ( playerHitFixedWall && HitEdgeCode == 7) begin
								lock <= 1;
								lock_2 <= 1;
								lock_4 <= 1;
								
								BM_Motion <= WAIT_FRAME_ST;
							end
						
						
						 if (toggle_4 && !playerHitFixedWall && !lock_4 ) begin
								lock_2 <= 0;
								lock_6 <= 0;
								lock_8 <= 0;
                        if (Xposition - STEP*FIXED_POINT_MULTIPLIER > x_FRAME_LEFT && !speedBoost)begin
									 scaleXpos<= scaleXpos - STEP;
                            Xposition<= Xposition - STEP;
									 end
									 else if (Xposition - STEP*FIXED_POINT_MULTIPLIER > x_FRAME_LEFT && speedBoost)begin
												Xposition<= Xposition - (STEP*13/10);
									 end
                        direction <= 3'b010; // left
                    end 
                    if (toggle_6 && !playerHitFixedWall && !lock_6 ) begin
                        lock_4 <= 0;
								lock_2 <= 0;
								lock_8 <= 0;
                        if (Xposition + STEP*FIXED_POINT_MULTIPLIER < x_FRAME_RIGHT && !speedBoost)begin
									 scaleXpos<= scaleXpos + STEP;
                            Xposition<= Xposition + STEP;
									 end
									 else if (Xposition + STEP*FIXED_POINT_MULTIPLIER < x_FRAME_RIGHT && speedBoost)begin
												Xposition<= Xposition + (STEP*13/10);
									 end
                        direction <= 3'b011; // right
                    end 
                    if (toggle_2 && !playerHitFixedWall && !lock_2 ) begin
                        lock_4 <= 0;
								lock_6 <= 0;
								lock_8 <= 0;
                       lock_8 <= 0;
                        if (Yposition + STEP*FIXED_POINT_MULTIPLIER < y_FRAME_BOTTOM && !speedBoost)begin
									 scaleYpos<= scaleYpos + STEP;
                            Yposition<=Yposition + STEP;
									 end
									 else if (Yposition + STEP*FIXED_POINT_MULTIPLIER < y_FRAME_BOTTOM && speedBoost)begin
												Yposition<=Yposition + (STEP*13/10);
									 end
                        direction <= 3'b001; // up
                    end 
                    if (toggle_8 && !playerHitFixedWall && !lock_8 ) begin
                        lock_4 <= 0;
								lock_2 <= 0;
								lock_6 <= 0;
                        if (Yposition - STEP*FIXED_POINT_MULTIPLIER > y_FRAME_TOP && !speedBoost)begin
									 scaleYpos<= scaleYpos - STEP;
                            Yposition<=Yposition - STEP;
									 end
									 else if (Yposition - STEP*FIXED_POINT_MULTIPLIER > y_FRAME_TOP && speedBoost)begin
												Yposition<=Yposition - (STEP*13/10);
									 end
                        direction <= 3'b000; // down
                    end
						  if (lock_8 && lock_6 && lock_4 && lock_2) begin
								lock_4 <= 0;
								lock_2 <= 0;
								lock_6 <= 0;
								lock_8 <= 0;
								end
						  if(!toggle_8 && !toggle_4 && !toggle_6 && !toggle_2 )
							   direction <= 3'b111;
                    BM_Motion <= WAIT_FRAME_ST;
                end

		//-----------
		//------------------------
			WAIT_FRAME_ST: begin 
                    BM_Motion <= POSITION_LIMITS_ST ;
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
	   if(toggle_x_key)begin
		      Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER; 
				Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER;
       end
				BM_Motion <= MOVE_ST ; 
			
			end
		
		endcase  // case 
		end
		
	end 

end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftX = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY = Yposition / FIXED_POINT_MULTIPLIER ;    
	

endmodule	
//---------------
 
