



module	monsterBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic OneSecPulse,
					input logic effectmonsterhit,
					 
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,
			      output   logic	[2:0] HitEdgeCode,		//rgb value from the bitmap 
				   output   logic monsterDead	
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

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hfe ;// RGB value in the bitmap representing a transparent pixel 



logic [0:OBJECT_HEIGHT_Y-1] [0:OBJECT_WIDTH_X-1] [7:0] object_colors = {
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'hf9,8'h24,8'h00,8'h00,8'h24,8'hd5,8'h00,8'h24,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'h24,8'h00,8'h10,8'h14,8'h14,8'h24,8'h04,8'h14,8'h74,8'h24,8'hf9,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'hf9,8'hf9,8'h6c,8'h10,8'h14,8'h04,8'h78,8'hbc,8'h78,8'h14,8'h14,8'h10,8'h10,8'h00,8'h00,8'h6c,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hd5,8'h6c,8'h04,8'h04,8'h04,8'h30,8'h78,8'h34,8'hbc,8'hdc,8'hbc,8'h9c,8'h78,8'h10,8'h04,8'h0c,8'h10,8'h0c,8'h8c,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hd5,8'h6c,8'h10,8'h14,8'h0c,8'h10,8'h70,8'h98,8'h78,8'h9c,8'hbc,8'hbc,8'h9c,8'h34,8'h14,8'h14,8'h30,8'h70,8'h30,8'h6c,8'hd5,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'h8c,8'h04,8'h34,8'h98,8'h38,8'h38,8'hbc,8'hbc,8'h38,8'h34,8'h9c,8'h9c,8'h34,8'h38,8'h38,8'h34,8'h78,8'hbc,8'h9c,8'h10,8'h6c,8'hd5,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hd5,8'h2c,8'h30,8'h34,8'h9c,8'hbc,8'hbc,8'h9c,8'h34,8'h34,8'h14,8'h14,8'h34,8'h78,8'hdc,8'hbc,8'h9c,8'h38,8'h78,8'h78,8'h14,8'h0c,8'h8c,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hd5,8'h6c,8'h74,8'h9c,8'h78,8'h9c,8'hdc,8'hbc,8'h78,8'h38,8'h34,8'h14,8'h14,8'h14,8'h78,8'h9c,8'h9c,8'h98,8'h14,8'h14,8'h34,8'h30,8'h0c,8'h2c,8'hd5,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hb1,8'h2c,8'h9c,8'hbc,8'h78,8'h78,8'h70,8'h30,8'h14,8'h78,8'h14,8'h14,8'h14,8'h10,8'h2c,8'h2c,8'h14,8'h14,8'h14,8'h14,8'h78,8'h98,8'h74,8'h34,8'h6c,8'hd5,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hf9,8'h90,8'h6c,8'h74,8'h34,8'h0c,8'h0c,8'h10,8'h0c,8'h14,8'h14,8'h14,8'h14,8'h04,8'h00,8'h0c,8'h0c,8'h14,8'h10,8'h0c,8'h38,8'h9c,8'h98,8'h34,8'h04,8'hb1,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hb1,8'h0c,8'h10,8'h14,8'h04,8'h00,8'h30,8'hbc,8'h78,8'h14,8'h04,8'h10,8'h10,8'hbc,8'hbc,8'h74,8'h10,8'h00,8'h04,8'h14,8'h10,8'h0c,8'h14,8'h04,8'hb1,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hd5,8'h2c,8'h10,8'h78,8'h34,8'h10,8'h78,8'hbc,8'h98,8'hbc,8'h14,8'h10,8'h04,8'h78,8'h98,8'hbc,8'hbc,8'h38,8'h10,8'h10,8'h14,8'h10,8'h0c,8'h00,8'hb1,8'hf9,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hb1,8'h04,8'h34,8'h78,8'h2c,8'h0c,8'h38,8'hbc,8'hbc,8'h98,8'h14,8'h04,8'h10,8'hbc,8'hbc,8'h78,8'h78,8'h14,8'h14,8'h14,8'h0c,8'h0c,8'h0c,8'h6c,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hf9,8'hf9,8'hb1,8'h20,8'h0c,8'h10,8'h10,8'h0c,8'h0c,8'h74,8'h24,8'h10,8'h04,8'h10,8'h74,8'h14,8'h14,8'h10,8'h10,8'h04,8'h10,8'h0c,8'h24,8'h91,8'hfe,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hf9,8'hb1,8'h24,8'h8c,8'h6c,8'h20,8'h24,8'h0c,8'h10,8'h24,8'h20,8'h10,8'h10,8'h10,8'h24,8'h24,8'h10,8'h10,8'h10,8'h20,8'h20,8'h20,8'h91,8'hfe,8'hf9,8'hf9,8'h6c,8'hb1,8'hf9,8'hfe,8'hfe},
	{8'hf9,8'hb1,8'h0c,8'h34,8'h70,8'h24,8'hb1,8'hf9,8'h91,8'h20,8'hc4,8'hec,8'h64,8'h60,8'h20,8'hec,8'ha4,8'h20,8'h60,8'h60,8'hc4,8'hc4,8'h8c,8'hfe,8'hf9,8'hb1,8'h24,8'h10,8'h04,8'hb1,8'hfe,8'hfe},
	{8'hb1,8'h04,8'h38,8'hbc,8'h9c,8'h14,8'h04,8'hb1,8'hf9,8'h8c,8'hec,8'hf4,8'hf0,8'hf0,8'hec,8'hec,8'hec,8'hec,8'hf0,8'hf0,8'hf4,8'hec,8'h8c,8'hf9,8'hb1,8'h04,8'h38,8'hbc,8'h70,8'hb1,8'hf9,8'hfe},
	{8'hd5,8'h6c,8'h30,8'h74,8'h34,8'h10,8'h8c,8'h60,8'h84,8'hec,8'hf0,8'hfc,8'hfc,8'hf8,8'hf4,8'hec,8'hec,8'hf4,8'hf8,8'hfc,8'hfc,8'hf4,8'hec,8'hac,8'hb0,8'h8c,8'h10,8'h98,8'h34,8'h04,8'hb1,8'hfe},
	{8'hfe,8'hd5,8'h64,8'h04,8'h0c,8'h04,8'hc4,8'he4,8'hec,8'hec,8'hf0,8'hfc,8'hfc,8'hfc,8'hfc,8'hf0,8'hf0,8'hfc,8'hfc,8'hfc,8'hfc,8'hf0,8'hec,8'hec,8'hc4,8'hc4,8'h04,8'h34,8'h10,8'h04,8'hb1,8'hfe},
	{8'hfe,8'hfe,8'hd5,8'h8c,8'h8c,8'h8c,8'h8c,8'hec,8'he4,8'h84,8'he4,8'hf4,8'hfc,8'hfc,8'hfc,8'hf4,8'hf4,8'hfc,8'hfc,8'hfc,8'hf4,8'he4,8'hc4,8'hec,8'h84,8'h24,8'h6c,8'h0c,8'h6c,8'h8c,8'hd5,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hb1,8'hac,8'h84,8'h20,8'hc4,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hc4,8'h20,8'h20,8'h64,8'hd5,8'hf9,8'hb1,8'hf9,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hb1,8'h24,8'h60,8'h64,8'h64,8'ha4,8'hf0,8'hec,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'hf0,8'hec,8'hec,8'hec,8'hec,8'hec,8'hac,8'hb1,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hd5,8'hb1,8'h64,8'hc4,8'hec,8'hec,8'hec,8'hec,8'hf0,8'hf0,8'hec,8'hf0,8'hec,8'hec,8'hec,8'hec,8'hec,8'hec,8'hc4,8'hec,8'hec,8'hb1,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hb1,8'hec,8'hec,8'hec,8'hc4,8'hc4,8'hec,8'hec,8'hec,8'hc4,8'hec,8'hec,8'hec,8'hc4,8'hc4,8'ha4,8'h60,8'h20,8'h84,8'h84,8'h24,8'hd5,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'h91,8'hc4,8'ha4,8'h60,8'h20,8'h20,8'h20,8'h20,8'hec,8'hf0,8'hf0,8'hec,8'h20,8'h60,8'h84,8'h20,8'h20,8'h20,8'h04,8'h0c,8'h70,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hd5,8'h20,8'h20,8'h24,8'h0c,8'h0c,8'h04,8'h20,8'h20,8'h20,8'h60,8'hec,8'hf0,8'hf0,8'hec,8'h20,8'h20,8'h04,8'h70,8'hf9,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'h2c,8'h0c,8'h00,8'h20,8'h60,8'h84,8'hf0,8'h00,8'h2c,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'h2c,8'h24,8'h64,8'hec,8'h24,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'h2c,8'h24,8'h24,8'h91,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe}};
	
	
	
logic [0:OBJECT_HEIGHT_Y-1] [0:OBJECT_WIDTH_X-1] [7:0] object_colors_died = {
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hd1,8'hd1,8'hf9,8'hfe,8'hf9,8'ha4,8'hf9,8'hfe,8'hfe,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'ha4,8'hf5,8'hf9,8'hfe,8'hf9,8'hf1,8'ha0,8'hd1,8'hf9,8'ha4,8'he4,8'ha4,8'hf9,8'hf9,8'hcc,8'hf5,8'hfe,8'hfe,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'ha4,8'he4,8'hc4,8'hd1,8'hcc,8'he4,8'he4,8'hcc,8'he4,8'hec,8'he4,8'ha0,8'hcc,8'hc0,8'hd1,8'hfe,8'hf5,8'hd1,8'hd1,8'hd1,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hd1,8'he4,8'he4,8'hc0,8'hc0,8'he4,8'hec,8'he4,8'hec,8'hf0,8'he4,8'he0,8'he4,8'he4,8'hcc,8'hd1,8'hc4,8'hc0,8'ha4,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hf5,8'hd1,8'hd1,8'ha0,8'he4,8'he0,8'he0,8'he4,8'hf0,8'hec,8'hf0,8'hf4,8'hec,8'hec,8'hec,8'he4,8'ha0,8'hc0,8'he0,8'he4,8'ha4,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hcc,8'hc0,8'he4,8'hec,8'he4,8'he0,8'he4,8'he4,8'hec,8'he4,8'hf0,8'hec,8'he4,8'hec,8'hf0,8'hec,8'he4,8'he4,8'hec,8'he4,8'hf5,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hf5,8'hc4,8'he4,8'hec,8'hf0,8'hec,8'he4,8'hec,8'hec,8'he4,8'hec,8'he4,8'he4,8'he4,8'hf0,8'hf0,8'hec,8'hf0,8'hec,8'hc0,8'hd1,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hcc,8'hc0,8'he4,8'hec,8'hec,8'he4,8'he4,8'hf0,8'hec,8'he4,8'he4,8'he4,8'he4,8'he4,8'hec,8'hf0,8'hf4,8'he4,8'he4,8'he4,8'hcc,8'hd1,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hf5,8'hcc,8'he4,8'he0,8'he4,8'he4,8'he4,8'he4,8'he4,8'hec,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hec,8'hf0,8'hf0,8'he4,8'hf0,8'hec,8'he4,8'he4,8'hd1,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hf5,8'ha0,8'he0,8'he4,8'hf0,8'hf0,8'he4,8'he4,8'he4,8'he4,8'he0,8'ha0,8'he0,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hf0,8'hf0,8'he4,8'hcc,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hf9,8'hd1,8'ha0,8'he0,8'hec,8'hec,8'he4,8'hc0,8'he4,8'he0,8'he0,8'hc0,8'ha0,8'he0,8'he4,8'he4,8'he0,8'he0,8'he0,8'he0,8'he4,8'hec,8'he4,8'ha4,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hf9,8'hf9,8'hcc,8'he4,8'hc0,8'he0,8'ha0,8'he0,8'he4,8'hec,8'hec,8'he4,8'he4,8'hc0,8'he4,8'hec,8'hec,8'he4,8'ha0,8'ha0,8'he4,8'ha4,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hd1,8'hcc,8'hf9,8'hf9,8'hc4,8'he4,8'he0,8'he4,8'he4,8'hec,8'hf0,8'hec,8'hec,8'hc0,8'he4,8'hec,8'hf0,8'hec,8'hec,8'hec,8'hf0,8'hec,8'he0,8'ha4,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hd1,8'ha0,8'hd1,8'hcc,8'he4,8'he4,8'hc0,8'he4,8'he4,8'hec,8'hec,8'hec,8'hec,8'he4,8'he0,8'he4,8'he4,8'he4,8'hec,8'hec,8'hc0,8'ha0,8'ha4,8'hf9,8'hf9,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hf9,8'hf9,8'hd1,8'hc0,8'hc0,8'ha0,8'ha4,8'ha0,8'he4,8'he4,8'he0,8'he4,8'he4,8'he0,8'he4,8'he4,8'ha0,8'he0,8'he0,8'ha0,8'he0,8'he4,8'he4,8'ha0,8'hf5,8'ha0,8'ha0,8'hcc,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hf9,8'hcc,8'ha0,8'he0,8'he0,8'hc0,8'hd1,8'ha0,8'he0,8'he0,8'he4,8'he4,8'he4,8'he4,8'he4,8'he0,8'he4,8'he4,8'he0,8'he4,8'hc0,8'ha4,8'hcc,8'ha0,8'he0,8'he4,8'he4,8'hc4,8'hd1,8'hf9,8'hfe,8'hfe},
	{8'hfe,8'hf9,8'he4,8'hec,8'he4,8'he4,8'he4,8'he4,8'ha0,8'ha0,8'hf0,8'hf4,8'hf4,8'hf0,8'he4,8'hec,8'hf8,8'hf8,8'hec,8'hec,8'he4,8'hcc,8'hf9,8'ha4,8'he4,8'hf0,8'hf0,8'he4,8'ha0,8'hd1,8'hfe,8'hfe},
	{8'hf9,8'hd1,8'he4,8'hf0,8'hec,8'he0,8'hec,8'hec,8'he4,8'hc4,8'hfc,8'hfc,8'hfc,8'hfc,8'he4,8'hf8,8'hfc,8'hfc,8'hfc,8'hf4,8'he4,8'he4,8'hd1,8'hec,8'ha0,8'he4,8'hec,8'he4,8'hc4,8'hf5,8'hfe,8'hfe},
	{8'hf9,8'ha0,8'he4,8'he4,8'he4,8'hc0,8'hd1,8'hec,8'he4,8'he4,8'hfc,8'hfc,8'hfc,8'hfc,8'he4,8'hf8,8'hfc,8'hfc,8'hfc,8'hf4,8'hec,8'hec,8'he4,8'he4,8'ha0,8'he0,8'he4,8'ha4,8'hf9,8'hfe,8'hfe,8'hfe},
	{8'hf9,8'hd1,8'hd1,8'hd1,8'hc4,8'hcc,8'hcc,8'hc4,8'hc0,8'hc0,8'hf0,8'hfc,8'hfc,8'hf0,8'he4,8'he4,8'hfc,8'hfc,8'hf4,8'hec,8'he4,8'he4,8'he4,8'hd1,8'hd1,8'ha0,8'hc4,8'hf5,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hf5,8'hd1,8'hc4,8'he4,8'hc0,8'ha0,8'he4,8'hec,8'hec,8'he4,8'he4,8'he4,8'hec,8'hf0,8'hec,8'hec,8'he4,8'ha0,8'he4,8'hcc,8'hf9,8'hd1,8'hf5,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hf9,8'ha4,8'ha0,8'hf0,8'he4,8'hec,8'hf0,8'hf0,8'hf0,8'hec,8'hf0,8'hec,8'hf0,8'hec,8'hec,8'hc4,8'hec,8'hc4,8'hf5,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hd1,8'ha4,8'ha0,8'he4,8'hf0,8'hf0,8'hec,8'hf0,8'hf0,8'hf1,8'hf0,8'hf0,8'hec,8'hf0,8'hec,8'he4,8'he4,8'hf0,8'hf0,8'hc4,8'ha4,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hf5,8'he4,8'hec,8'he4,8'hf0,8'he4,8'hf0,8'hec,8'hec,8'hec,8'hec,8'he4,8'he4,8'hec,8'hec,8'he4,8'he4,8'hf0,8'hec,8'hec,8'hf0,8'he4,8'ha4,8'hd1,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hf5,8'ha0,8'ha0,8'he4,8'hf0,8'hec,8'ha0,8'he4,8'hec,8'hf0,8'hf0,8'hec,8'hf0,8'hf0,8'hc0,8'he4,8'hec,8'hec,8'he4,8'hc0,8'ha0,8'hc0,8'ha0,8'h2c,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'h94,8'h84,8'he4,8'ha4,8'h80,8'ha0,8'hc0,8'he4,8'hec,8'hf0,8'hec,8'hf0,8'hec,8'hc0,8'ha0,8'hc0,8'ha0,8'ha4,8'h2c,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'h2c,8'ha4,8'ha4,8'h80,8'hc4,8'he4,8'ha0,8'he4,8'hf0,8'hf0,8'he4,8'hc0,8'h64,8'hb5,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hb5,8'h2c,8'h84,8'ha4,8'h80,8'h80,8'he4,8'he4,8'h80,8'ha4,8'ha4,8'h6c,8'hf9,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'h94,8'hac,8'hcc,8'hac,8'hb5,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe}};
	
	
	
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
 


 int counter = 0;
 int dead = 0;
 int firstTime = 0;
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		HitEdgeCode <= 3'h0;
		dead <= 0;
		firstTime <= 0;
		monsterDead <= 1;
	end

	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default 
      HitEdgeCode <= 3'h0;	
		monsterDead <= 0;
		if (effectmonsterhit)begin
			dead <= 1;
			monsterDead <= 1;
			if(firstTime == 0)begin
				dead <= 0;
				firstTime <= 1; 
				end
		end
		// if(!died)begin;
		if (InsideRectangle == 1'b1 && !effectmonsterhit  ) begin   // inside an external bracket 
				RGBout <= object_colors[offsetY][offsetX];
				HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
		 end
			if (InsideRectangle == 1'b1 && effectmonsterhit  ) begin   // inside an external bracket 
				RGBout <= object_colors_died[offsetY][offsetX];
				HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
		 end
	 end
	 
	 
end
 
 // decide if to draw the pixel or not 
 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING && !dead ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   


endmodule
	
	