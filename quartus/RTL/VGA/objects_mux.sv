
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
		   // smiley 
					input		logic	smileyDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] smileyRGB, 
					     
		  // add the box here 
					input    logic BoxDrawingRequest,
					input    logic [7:0] BoxRGB,
			  
			  
		  ////////////////////////
		  // background 
					input    logic BombDrawingRequest, // box of numbers
					input		logic	[7:0] bombRGB,
					input    logic WallDrawingRequest,
					input    logic [7:0] wallRGB,
					input		logic	[7:0] backGroundRGB, 
					input		logic	BGDrawingRequest, 
					input		logic	[7:0] RGB_MIF, 
					input    logic [7:0] eagleRGB,
					input    logic eagleDR,
					input    logic secDR,
					input    logic [7:0] secRGB,
					input    logic tenSecDR,
					input    logic [7:0] tenSecRGB,
					input    logic monsterDR,
					input    logic [7:0] monsterRGB,
					input    logic effectXDR,
					input    logic [7:0] effectXRGB,
					input    logic effectYDR,
					input    logic [7:0] effectYRGB,
					input    logic MessageDR,
					input    logic [7:0] MessageRGB,
					input 	logic scoreFDR,
					input 	logic [7:0] scoreFRGB,
					input 	logic scoreSDR,
					input 	logic [7:0] scoreSRGB,
				   output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
	if (MessageDR == 1'b1) 
			RGBOut <= MessageRGB;
	else if ( eagleDR == 1'b1)
				RGBOut <= eagleRGB;  //first priority 
		else if ( smileyDrawingRequest == 1'b1 )   
			RGBOut <= smileyRGB; 
		else if ( effectXDR == 1'b1 )   
			RGBOut <= effectXRGB; 
		else if ( effectYDR == 1'b1 )   
			RGBOut <= effectYRGB; 
		else if (monsterDR == 1'b1)
				RGBOut <= monsterRGB;
		 
//--- add logic for box here ------------------------------------------------------		

		else if (BoxDrawingRequest == 1'b1)
				RGBOut <= BoxRGB;
				
//---------------------------------------------------------------------------------	 
 		else if ( BombDrawingRequest == 1'b1)
				RGBOut <= bombRGB;
		else if ( WallDrawingRequest == 1'b1)
				RGBOut <= wallRGB;		
		else if (BGDrawingRequest == 1'b1)
				RGBOut <= backGroundRGB ;
		else if (secDR == 1'b1)
				RGBOut <= secRGB;
		else if (tenSecDR == 1'b1)
				RGBOut <= tenSecRGB;
		else if (scoreFDR == 1)
				RGBOut <= scoreFRGB;
		else if (scoreSDR == 1)
				RGBOut <= scoreSRGB;
		else RGBOut <= RGB_MIF ;// last priority 
		end ; 
	end

endmodule


