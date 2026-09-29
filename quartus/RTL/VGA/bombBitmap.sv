



module	bombBitmap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
               input	logic toggle5,
					input logic OneSecPulse,
					 
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout  //rgb value from the bitmap  
 ) ;
 
 
 
 localparam  int OBJECT_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 
localparam  int OBJECT_NUMBER_OF_X_BITS = 5;  // 2^5 = 32 


localparam  int OBJECT_HEIGHT_Y = 1 <<  OBJECT_NUMBER_OF_Y_BITS ;
localparam  int OBJECT_WIDTH_X = 1 <<  OBJECT_NUMBER_OF_X_BITS;

 logic	[10:0] HitCodeX ;// offset of Hitcode 
 logic	[10:0] HitCodeY ; 
assign HitCodeX = offsetX >> ( OBJECT_NUMBER_OF_X_BITS - 4 );	// hitedge code MSB of the offset
assign HitCodeY = offsetY >> ( OBJECT_NUMBER_OF_Y_BITS - 4 );	 	


// generating a bomb bitmap

localparam logic [7:0] TRANSPARENT_ENCODING = 8'h00 ;// RGB value in the bitmap representing a transparent pixel 



logic [0:OBJECT_HEIGHT_Y-1] [0:OBJECT_WIDTH_X-1] [7:0] object_colors = {
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hf6,8'h80,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hfb,8'ha0,8'h80,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hd6,8'hd6,8'hd6,8'hd6,8'hd6,8'hd1,8'hc4,8'h80,8'hd2,8'hfb,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hfb,8'hd6,8'ha0,8'ha0,8'hc4,8'hc4,8'hf0,8'hf8,8'hf0,8'hc4,8'hcc,8'hf6,8'hb2,8'hdb,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hed,8'he4,8'hec,8'hf4,8'hf8,8'hfc,8'hf8,8'hf0,8'hec,8'hc4,8'h80,8'hd2,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hfa,8'ha4,8'hf4,8'hfc,8'hfc,8'hf4,8'h80,8'hd1,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'h96,8'h92,8'h8d,8'h80,8'hf4,8'hf8,8'hf0,8'hc4,8'hd2,8'hfb,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'h6d,8'h6d,8'h6d,8'h8d,8'h80,8'hc4,8'hc4,8'ha0,8'h80,8'h92,8'hdb,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hdb,8'h20,8'h92,8'hff,8'hd6,8'ha4,8'h80,8'h84,8'h85,8'h80,8'h00,8'h71,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hdb,8'h25,8'h00,8'hff,8'hff,8'hff,8'hfb,8'ha5,8'hdb,8'hff,8'hb3,8'h8e,8'h25,8'h00,8'h00,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h6d,8'h6d,8'h92,8'hff,8'hff,8'hff,8'hff,8'hfb,8'hfb,8'hdf,8'hb7,8'h8e,8'h65,8'h20,8'h00,8'h71,8'hdb,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'h00,8'h92,8'hdb,8'hff,8'hff,8'hff,8'hff,8'hff,8'hdb,8'hd7,8'hb3,8'h92,8'h65,8'h25,8'h25,8'h00,8'h96,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'hdb,8'h21,8'h92,8'hdb,8'hff,8'hff,8'hff,8'hff,8'hdb,8'hd7,8'hb7,8'hb3,8'h8e,8'h65,8'h25,8'h25,8'h00,8'h92,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h6d,8'h00,8'h8e,8'h92,8'hb7,8'hdb,8'hdb,8'hdb,8'hdb,8'hd7,8'hb3,8'h92,8'h8e,8'h8e,8'h65,8'h25,8'h25,8'h25,8'h00,8'h92,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h6d,8'h00,8'h92,8'h92,8'h92,8'hb7,8'hb7,8'hb7,8'hb7,8'hb7,8'h92,8'h8e,8'h8e,8'h8e,8'h65,8'h25,8'h25,8'h25,8'h00,8'h96,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'hff,8'h96,8'h24,8'h25,8'h8e,8'h92,8'h92,8'h92,8'h92,8'h92,8'h92,8'h92,8'h8e,8'h8e,8'h8e,8'h6e,8'h6d,8'h25,8'h25,8'h25,8'h24,8'h24,8'h6d,8'hbb,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'hff,8'h6d,8'h00,8'h25,8'h6e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h6e,8'h65,8'h25,8'h25,8'h25,8'h25,8'h00,8'h00,8'h96,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'hff,8'h6d,8'h25,8'h6d,8'h65,8'h66,8'h6e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h65,8'h65,8'h65,8'h25,8'h25,8'h25,8'h25,8'h00,8'h00,8'h96,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'hff,8'h6d,8'h20,8'h25,8'h65,8'h65,8'h65,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h8e,8'h6e,8'h65,8'h65,8'h25,8'h25,8'h25,8'h25,8'h25,8'h00,8'h00,8'h96,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'hff,8'h6d,8'h00,8'h25,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h6d,8'h25,8'h25,8'h25,8'h25,8'h25,8'h00,8'h00,8'h96,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'hdf,8'h6d,8'h00,8'h25,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h65,8'h25,8'h25,8'h25,8'h25,8'h25,8'h00,8'h00,8'h96,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h96,8'h24,8'h00,8'h25,8'h25,8'h25,8'h65,8'h65,8'h65,8'h6d,8'h65,8'h65,8'h65,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h20,8'h24,8'h6d,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h6d,8'h00,8'h25,8'h25,8'h25,8'h25,8'h65,8'h65,8'h6d,8'h6d,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h00,8'h92,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'hff,8'hdb,8'h00,8'h20,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h00,8'h72,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'h6d,8'h24,8'h00,8'h00,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h25,8'h00,8'h00,8'h00,8'h6d,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hb6,8'h71,8'h6d,8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h71,8'h92,8'h71,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hdb,8'h25,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}};
	
	
	
	
	
	
	//hit bit map has one encoding per edge:  hit_colors[2:0] =   
 
logic [0:15] [0:15] [2:0] hit_colors = 
		  {48'o4433333333333344,     
			48'o4443333333333444,    
			48'o1444333333334442, 
			48'o1144433333344422,
			48'o1114443333444222,
			48'o1111444334442222,
			48'o1111144444422222,
			48'o1111114444222222,
			48'o1111114444222222,
			48'o1111144444422222,
			48'o1111444004442222,
			48'o1114440000444222,
			48'o1144400000044422,
			48'o1444000000004442,
			48'o4440000000000444,
			48'o4400000000000044};
 
 enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST,
						 WAIT_FRAME_ST// check if inside the frame  
						}  BM_Motion ;

 
 
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
	end

	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default   

		
		if (InsideRectangle == 1'b1 && toggle5) 
		begin // inside an external bracket 
				RGBout <= object_colors[offsetY][offsetX];
		end 
		
		
    end
	 
	 
	 
end
 
 // decide if to draw the pixel or not 
 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule
	
	