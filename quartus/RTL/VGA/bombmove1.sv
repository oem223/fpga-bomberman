




module	bombmove1	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input  logic toggle_5,         
					input  logic collision,         //collision if smiley hits an object 
					input  logic OneSecPulse,
					input  logic [10:0] offsetX,
					input  logic [10:0] offsetY,
					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside 
					output logic direction,
					output logic explosion,
					output logic [10:0] bombX,
					output logic [10:0] bombY,
					output logic explosion2,
					output logic [10:0] effectXX,
					output logic [10:0] effectYY

);

enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST,
						 WAIT_FRAME_ST// check if inside the frame  
						}  BM_Motion ;

int counter;
int flag;
int lock_bomb;
int secLock = 0;
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		BM_Motion <= IDLE_ST ; 
		direction <= 1'b0;
		counter <= 0;
		flag <= 0;
		explosion <= 0;
		explosion2 <= 0;
		lock_bomb <= 0;
		secLock <= 0;
	end 	
	
	else begin
	
	
		case(BM_Motion)
		
		//------------
			IDLE_ST: begin
			//direction <= 1'b0;
			counter <= 0;
			//topLeftX <= offsetX;
			//topLeftY <= offsetY;
				if (startOfFrame) 
					BM_Motion <= MOVE_ST ;
					
 	
			end
			
			
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
						 explosion <= 0;
		//------------
						 if (toggle_5 && !lock_bomb)begin
						      direction <= 1;
                        counter <= 0;
								flag <= 0;
						  	topLeftX <= offsetX;
							topLeftY <= offsetY;
							bombX <= offsetX;
							bombY <= offsetY;
							effectXX <= offsetX - 40;
							effectYY <= offsetY - 30;
								lock_bomb <= 1;
								explosion <= 0;
								explosion2 <= 0;
						  end
						  if (OneSecPulse == 1)begin
								secLock <= secLock + 1;
								counter <= counter + 1;
								end
						  if(counter == 2 && secLock >= 3)begin
						  		direction <= 0;
								explosion <= 1;
								explosion2 <= 1;
						  end
						  if (counter == 3 && secLock >= 3) begin
						  		lock_bomb <= 0;
								explosion2 <=0;
						  end
						end
						  endcase
						  
	end
 end
	endmodule
			
			
			
			
			
			
			
			
			
			
			
			
			