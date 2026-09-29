// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021


module	game_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz 
			input	logic	drawing_request_bomber,
			input	logic	drawing_request_boarders,

//---------------------#1-add input drawing request of box/number
			input logic drawing_request_monster,
			input logic drawing_request_FixedWall,
			input logic [4:0] WallType,
			input logic TimeUp,
			input logic outLives,
			input logic monsterHitBomber,
			input logic oneSecPulse,
		

//---------------------#1-end input drawing request of box/number




//---------------------#2-add  drawing request of hart

		//	input	logic	drawing_request_hart,

//---------------------#2-end drawing request of hart		

			
			output logic collision, // active in case of collision between two objects
			
			output logic SingleHitPulse, // critical code, generating A single pulse in a frame 
			output logic collisionFixedWall,
			output logic PlayerHitWallPulse,
			output logic MonsterHitWallPulse,
			output logic Win,
			output logic Lose,
			output logic playerFlower,
			output logic keyCollected,
			output logic level1,
			output logic addTime,
			output logic addHealth,
			output logic speedBoost
			

//---------------------#3-add collision  smiley and hart   -------------------------------------


		//	output logic collision_Smiley_Hart // active in case of collision between Smiley and hart


//---------------------#3-end collision  smiley and hart	--------------------------------------
			


);

// drawing_request_bomber   -->  smiley
// drawing_request_boarders -->  brackets
// drawing_request_monster   -->  number/box 

logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 
logic collision_smiley_number; // collision between Smiley and number - is not output
logic collision_player_FixedWall;

//assign collision = (drawing_request_bomber && drawing_request_boarders);// any collision --> comment after updating with #4 or #5 

//---------------------#4-update  collision  conditions - add collision between smiley and number   ----------------------------

//assign collision = ((drawing_request_bomber && drawing_request_monster) || (drawing_request_bomber && drawing_request_boarders));
assign collision_smiley_number =  (drawing_request_bomber && drawing_request_monster);
assign collision_player_FixedWall = (drawing_request_bomber && drawing_request_FixedWall);
assign collision = ((drawing_request_bomber && drawing_request_monster) || (drawing_request_bomber && drawing_request_boarders) || (drawing_request_bomber && drawing_request_FixedWall));
assign collisionFixedWall = (drawing_request_bomber && drawing_request_FixedWall);
assign MonsterHitWallPulse = (drawing_request_monster && drawing_request_FixedWall);



//---------------------#4-end update  collision  conditions	 - add collision between smiley and number	-------------------------
	
					
						

//---------------------#5-update  collision  sconditions - add collision between smiley and hart  ---------------------------------

//assign collision = <collision_before> +( drawing_request_bomber && drawing_request_hart ); 
	


//---------------------#5-end update  collision  conditions	- add collision between smiley and hart	-----------------------------
	



//-------------------------- #6-add colision between Smiley and hart-----------------

//assign collision_Smiley_Hart = ( drawing_request_bomber && drawing_request_hart ) ;
int HitFlag=0;
int Hits = 0;
int secLock = 0;
int oneSecLock = 0;
int speedTime = 0;

//---------------------------#6-end colision betweenand Smiley and hart-----------------

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin 
		flag	<= 1'b0;
		SingleHitPulse <= 1'b0 ; 
		PlayerHitWallPulse <= 1'b0;
		playerFlower <= 0;
		Win <= 0;
		Lose <= 0;
		HitFlag <= 0;
		Hits <= 0;
		secLock <= 0;
		oneSecLock <= 0;
		level1 <= 1;
		addTime <= 0;
		addHealth <= 0;
		speedTime <= 0;
		speedBoost <= 0;
	end 
	else begin 
	
//----------------------- #7-define colision between Smiley and number to collision_smiley_number -------
//logic	collision_smiley_number ;

//----------------------- #7-end colision between Smiley and number-----------------------------------	
		Lose <= 0;
		SingleHitPulse <= 1'b0 ; // default 
		PlayerHitWallPulse <= 1'b0;
		playerFlower <= 0;
		keyCollected <= 0;
		addTime <= 0;
		addHealth <= 0;
		if(startOfFrame) 
			flag <= 1'b0 ; // reset for next time 
				
//	---#7 - change the condition below to collision between Smiley and number ---------
		if(oneSecPulse)begin
			secLock <= secLock + 1;
			oneSecLock <= 1;
		end
		if(speedTime && oneSecPulse)begin
			speedTime <= speedTime + 1;
			if(speedTime >= 11)begin
				speedTime <= 0;
				speedBoost <= 0;
				end
		end
		if ( collision_smiley_number  && (flag == 1'b0)) begin 
			flag	<= 1'b1; // to enter only once 
			SingleHitPulse <= 1'b1 ; 
		end ; 
		if (collision_player_FixedWall) begin
			PlayerHitWallPulse <= 1'b1;
			end
		if ((drawing_request_bomber && drawing_request_FixedWall && WallType == 4 && oneSecLock)) begin
			PlayerHitWallPulse <= 1'b1;
			playerFlower <= 1;
			Hits <= Hits + 1;
			oneSecLock <= 0;
			end
		if ((drawing_request_bomber && drawing_request_FixedWall && WallType == 5) && oneSecLock) begin
			PlayerHitWallPulse <= 1'b1;
			oneSecLock <= 0;
			if(level1) begin
				level1 <= 0;
				end
			else 
				Win <= 1;
			end
		if ((drawing_request_bomber && drawing_request_FixedWall && WallType == 7)) begin
			keyCollected <= 1;
			end
		if ((drawing_request_bomber && drawing_request_FixedWall && WallType == 9 && oneSecLock)) begin
			addTime <= 1;
			oneSecLock <= 0;
			end
		if ((drawing_request_bomber && drawing_request_FixedWall && WallType == 10 && secLock >= 3 && oneSecLock)) begin
			speedTime <= 1;
			speedBoost <= 1;
			oneSecLock <= 0;
			end
		if ((drawing_request_bomber && drawing_request_FixedWall && WallType == 8 && secLock >= 3 && oneSecLock)) begin
			addHealth <= 1;
			Hits <= Hits - 1;
			oneSecLock <= 0;

			end
		if(TimeUp)begin
			Lose <= 1;
		end
		if(monsterHitBomber && !HitFlag && secLock >= 3 && oneSecLock )begin
			HitFlag <= 1;
			Hits <= Hits + 1;
			oneSecLock <= 0;
		end
		if(!monsterHitBomber)begin
			HitFlag <= 0;
		end
		if (Hits >= 3)begin
			Lose <= 1;
		end
			//if ((drawing_request_monster && drawing_request_FixedWall)) begin
			//MonsterHitWallPulse <= 1'b1;
			//end
 
	end 
end

endmodule
