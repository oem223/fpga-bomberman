

module	timerM	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input  logic OneSecPulse,
					input  logic [10:0] offsetX,
					input  logic [10:0] offsetY,
					input  logic [10:0] offsetXX,
					input  logic [10:0] offsetYY,
					input  logic addTime,
					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside
				   output logic timeUp,
				   output logic [3:0] Sec,
					output logic [3:0] tenSec,
					output logic signed 	[10:0] topLeftXX, 
					output logic signed	[10:0] topLeftYY

);

logic [6:0] counter ;
enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST,
						 WAIT_FRAME_ST// check if inside the frame  
						}  Timer_Motion ;

always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc
	topLeftX <= offsetX ;
	topLeftY <= offsetY ;
	topLeftXX <= offsetXX ;
	topLeftYY <= offsetYY ;
	if (resetN == 1'b0) begin 
		Timer_Motion <= IDLE_ST ; 
		timeUp <= 0;
		counter <= 7'd99;
	end 	
	
	else begin
		if(addTime) begin
			if(tenSec >= 7)
				tenSec <= 9;
			else tenSec <= tenSec + 2; 
		end
	
		case(Timer_Motion)
		
		//------------
			IDLE_ST: begin
			//direction <= 1'b0;
			counter <= 7'd99;
			Sec <= 4'd9;
			tenSec <= 4'd9;
			timeUp <= 0;
			//topLeftX <= offsetX;
			//topLeftY <= offsetY;
				if (startOfFrame) 
					Timer_Motion <= MOVE_ST ;
					
 	
			end
			
			
		//------------
			MOVE_ST:  begin      
		//------------
						  if (OneSecPulse == 1)begin
								Sec <= Sec - 1;
								if( Sec == 0) begin
										tenSec <= tenSec - 1;
										Sec <= 4'd9;
										end
								counter <= counter - 1;
								end
						  if(tenSec == 0 && Sec == 0)begin
						  		timeUp <= 1;
								Timer_Motion <= IDLE_ST;
						  end
						end
						  endcase
						  
	end
 end
	endmodule
			
			
			
			
			
			
			
			
			
			
			
			
			