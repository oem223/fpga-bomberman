// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2025
// (c) Technion IIT, Department of Electrical Engineering 2025 



module	smileyBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
               input	logic [2:0] direction,
					 
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,  //rgb value from the bitmap 
				   output   logic	[2:0] HitEdgeCode 
 ) ;

// this is the devider used to acess the right pixel 
localparam  int OBJECT_NUMBER_OF_Y_BITS = 6;  // 2^5 = 32 
localparam  int OBJECT_NUMBER_OF_X_BITS = 6;  // 2^6 = 64 


localparam  int OBJECT_HEIGHT_Y = 32 ;
localparam  int OBJECT_WIDTH_X = 32;

// --- indices into the 32x32 sprite (don’t change your ROMs) ---
logic [5:0] texX, texY;       // 0..31
assign texX = (offsetX * 1) / 1;  // map 0..31 -> 0..31
assign texY = (offsetY * 1) / 1;


// --- indices into the 16x16 hit map ---
logic [4:0] HitCodeX;
logic [4:0] HitCodeY;   // 0..15
assign HitCodeX = offsetX / 2;    // map 0..31 -> 0..15
assign HitCodeY = offsetY / 2;	
logic  [5:0] counter = 3'b000; 

// generating a smiley bitmap

localparam logic [7:0] TRANSPARENT_ENCODING = 8'h1c ;// RGB value in the bitmap representing a transparent pixel 

logic [0:31] [0:31] [7:0] object_colors_stand = {
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hf3,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h04,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h0c,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h13,8'hff,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h04,8'h00,8'he3,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'he7,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hdf,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'he0,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'h0c,8'h00,8'hfc,8'he0,8'hfe,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'he0,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'h6c,8'h00,8'hfc,8'he0,8'hff,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'he0,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'h0c,8'h00,8'hfc,8'he0,8'hff,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hdb,8'hff,8'hff,8'he0,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'h24,8'h00,8'hfc,8'he0,8'hff,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'hff,8'h1f,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h1f,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hfb,8'hff,8'hcc,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'h14,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h00,8'hff,8'hff,8'hff,8'hff,8'h61,8'h00,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'h00,8'h00,8'h1f,8'h1f,8'h1f,8'h1f,8'h0f,8'h13,8'h1f,8'h1f,8'h1b,8'h1f,8'h1f,8'h00,8'h00,8'h7f,8'hff,8'h82,8'h00,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'hfc,8'hfc,8'hf4,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h00,8'h00,8'h1f,8'h1b,8'h13,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h0f,8'h02,8'h13,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'h00,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h80,8'he0,8'he0,8'he0,8'h00,8'h00,8'hff,8'hff,8'h1f,8'h7f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h9f,8'h1f,8'hff,8'hff,8'h04,8'h00,8'he0,8'he0,8'he0,8'h10,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h66,8'hff,8'hff,8'hff,8'hff,8'hff,8'h01,8'h02,8'h65,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h04,8'h00,8'h00,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'ha3,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h95,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h04,8'h00,8'h00,8'h80,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h14,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h10,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h04,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c}};

	
logic [0:31][0:31][7:0] object_colors_right = {
{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h18,8'h18,8'h18,8'h18,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h30,8'h60,8'h20,8'h1c,8'h1c,8'h14,8'h1c,8'h18,8'h21,8'h20,8'h20,8'h20,8'h20,8'h21,8'h1c,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h80,8'hf8,8'hf0,8'h00,8'h1c,8'h21,8'h20,8'h25,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h21,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h64,8'hec,8'hcc,8'h04,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h21,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h00,8'h0c,8'h1c,8'h65,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hfe,8'hff,8'h60,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf4,8'hcc,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hfc,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hfc,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hfc,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hf4,8'hf8,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hbf,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hdf,8'hdf,8'hdf,8'hff,8'h00,8'he0,8'he0,8'h00,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'h00,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hdf,8'h36,8'h00,8'h17,8'h1f,8'h1f,8'h1f,8'h1f,8'h00,8'h00,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hbf,8'h76,8'h00,8'h1b,8'h1f,8'h1f,8'h1b,8'h1f,8'h1f,8'h1f,8'h00,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'he0,8'h00,8'hff,8'h31,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hf0,8'hfc,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h3c,8'he0,8'hf4,8'he0,8'h00,8'h00,8'h1b,8'h17,8'h17,8'h17,8'h13,8'h1f,8'h1f,8'h1f,8'h1f,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'he0,8'he0,8'h00,8'h12,8'h06,8'h0e,8'h9a,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h76,8'hdf,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h20,8'he0,8'h00,8'hff,8'hff,8'hff,8'h9b,8'h00,8'h00,8'h76,8'hdf,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'he0,8'h00,8'h00,8'h7b,8'h76,8'h00,8'h00,8'h00,8'h00,8'h76,8'hff,8'h00,8'h00,8'he0,8'he0,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h20,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c}};

	
	
	logic [0:31] [31:0] [7:0] object_colors_left = {
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h18,8'h18,8'h18,8'h18,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h30,8'h60,8'h20,8'h1c,8'h1c,8'h14,8'h1c,8'h18,8'h21,8'h20,8'h20,8'h20,8'h20,8'h21,8'h1c,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h80,8'hf8,8'hf0,8'h00,8'h1c,8'h21,8'h20,8'h25,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h21,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h64,8'hec,8'hcc,8'h04,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h21,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h00,8'h0c,8'h1c,8'h65,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hfe,8'hff,8'h60,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf4,8'hcc,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hfc,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hfc,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hfc,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf0,8'hf4,8'hf8,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hbf,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hdf,8'hdf,8'hdf,8'hff,8'h00,8'he0,8'he0,8'h00,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'h00,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hdf,8'h36,8'h00,8'h17,8'h1f,8'h1f,8'h1f,8'h1f,8'h00,8'h00,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hbf,8'h76,8'h00,8'h1b,8'h1f,8'h1f,8'h1b,8'h1f,8'h1f,8'h1f,8'h00,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'he0,8'h00,8'hff,8'h31,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hf0,8'hfc,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h3c,8'he0,8'hf4,8'he0,8'h00,8'h00,8'h1b,8'h17,8'h17,8'h17,8'h13,8'h1f,8'h1f,8'h1f,8'h1f,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'he0,8'he0,8'h00,8'h12,8'h06,8'h0e,8'h9a,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h76,8'hdf,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h20,8'he0,8'h00,8'hff,8'hff,8'hff,8'h9b,8'h00,8'h00,8'h76,8'hdf,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'he0,8'h00,8'h00,8'h7b,8'h76,8'h00,8'h00,8'h00,8'h00,8'h76,8'hff,8'h00,8'h00,8'he0,8'he0,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h20,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c}};

	
	
	

	logic [0:31] [0:31] [7:0] object_colors_up = {
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h3c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h1c,8'h20,8'h20,8'h00,8'h01,8'h00,8'h80,8'h04,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h81,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'h00,8'h00,8'h00,8'h00,8'ha0,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hbf,8'h01,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hbf,8'h00,8'hfc,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'he4,8'hfc,8'hf8,8'hec,8'hf4,8'hf0,8'hf8,8'he4,8'hfe,8'hff,8'hff,8'hbe,8'h9f,8'h00,8'h3c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'he0,8'hfc,8'h00,8'hfc,8'hec,8'hfc,8'hfc,8'h00,8'h04,8'hf4,8'he4,8'hff,8'hfb,8'h9f,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hec,8'hfc,8'h00,8'hfc,8'hf0,8'hfc,8'hfc,8'hd4,8'h74,8'hfc,8'hf0,8'hff,8'hfb,8'h7b,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'he0,8'hfc,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'h0c,8'h0c,8'hfc,8'hf0,8'hff,8'hff,8'h7b,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'he0,8'hfc,8'hec,8'he0,8'he0,8'hec,8'hfc,8'hec,8'hfa,8'hff,8'hff,8'hdf,8'h9f,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h9f,8'h76,8'h05,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'h00,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h20,8'hdf,8'hbb,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h14,8'h00,8'hff,8'hff,8'h00,8'he0,8'he0,8'h00,8'h1f,8'h0f,8'h1b,8'h1b,8'h17,8'h1b,8'h1a,8'h17,8'h0e,8'h20,8'h9a,8'h9f,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h14,8'h00,8'hff,8'hbf,8'h00,8'h00,8'h00,8'h00,8'h00,8'hf8,8'hfc,8'hfc,8'hfc,8'hc0,8'h00,8'h00,8'h00,8'h00,8'h00,8'hb7,8'h00,8'he0,8'h00,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hff,8'h0d,8'hdf,8'h00,8'h1f,8'h16,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h0f,8'h16,8'h16,8'h04,8'h00,8'h00,8'he0,8'he0,8'h00,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'hff,8'hbb,8'hff,8'h11,8'h1b,8'h1f,8'h16,8'h17,8'h16,8'h12,8'h12,8'h11,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'h24,8'h00,8'h01,8'hbb,8'hff,8'hbf,8'hff,8'h9b,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h0d,8'h9a,8'hff,8'hff,8'hff,8'h77,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h8e,8'h2c,8'h94,8'h00,8'h00,8'h00,8'h2c,8'hbf,8'hff,8'hff,8'hff,8'hdf,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h04,8'h11,8'h01,8'h0c,8'h11,8'h0d,8'h00,8'h00,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h0c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'ha0,8'h80,8'he0,8'he0,8'hc0,8'hc0,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h14,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c}};

	
	logic [0:31] [0:31] [7:0] object_colors_down = {
		{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h18,8'h18,8'h18,8'h18,8'h18,8'h1c,8'h18,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h14,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hdf,8'hff,8'h00,8'hf4,8'hf8,8'h80,8'h04,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hff,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'hf4,8'hf8,8'h80,8'h00,8'h0c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'ha4,8'hec,8'h8c,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h9b,8'hdf,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'hb2,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hbf,8'h36,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h8d,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hdf,8'h36,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h8d,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hbf,8'h32,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h8d,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hbf,8'h32,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h6d,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hbf,8'h32,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h21,8'hbf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hdf,8'h76,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h0c,8'h25,8'hbf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hdf,8'h96,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h00,8'h7a,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h9b,8'h7a,8'h31,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'hce,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h8d,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h14,8'h00,8'h92,8'hff,8'h00,8'h00,8'hfa,8'hfa,8'h76,8'h12,8'h0e,8'h0e,8'h12,8'h12,8'h12,8'h00,8'h00,8'hba,8'hff,8'hff,8'h92,8'h04,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'hb6,8'hb6,8'h00,8'h0d,8'hff,8'hff,8'h3f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1b,8'h1b,8'h0e,8'h0d,8'h92,8'hdf,8'hff,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hd6,8'hfa,8'h00,8'h00,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h17,8'h17,8'h1f,8'h05,8'h00,8'h7a,8'hdf,8'hff,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h04,8'h6e,8'h9a,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hbf,8'h00,8'he0,8'h60,8'h10,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'hae,8'hbb,8'h00,8'h00,8'h12,8'h0e,8'h0d,8'h16,8'h16,8'h16,8'h16,8'h1a,8'h12,8'h05,8'h06,8'h00,8'h00,8'h00,8'h05,8'hc0,8'he0,8'h20,8'h10,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h14,8'h31,8'h6d,8'h00,8'h71,8'h9f,8'h7f,8'h7f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h9f,8'h7b,8'h9f,8'h96,8'h24,8'h00,8'h00,8'he0,8'hc0,8'h04,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h10,8'h00,8'h25,8'hff,8'hff,8'hff,8'hff,8'h36,8'h0e,8'h17,8'h13,8'h0e,8'hff,8'hff,8'hff,8'hff,8'hba,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h18,8'h00,8'hff,8'hff,8'hff,8'hdf,8'hff,8'hb6,8'h00,8'h00,8'h7f,8'hdf,8'hff,8'hff,8'hff,8'h96,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h14,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'h92,8'h00,8'h20,8'he0,8'he4,8'he4,8'he4,8'he4,8'he0,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h04,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h00,8'h00,8'he0,8'hc0,8'hc0,8'ha0,8'he0,8'ha0,8'h00,8'h18,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h0c,8'h00,8'h04,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h04,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h04,8'h00,8'h00,8'h20,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h14,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h0c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h14,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c},
	{8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h10,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c,8'h1c}};

	
//////////--------------------------------------------------------------------------------------------------------------=
//hit bit map has one encoding per edge:  hit_colors[2:0] =   
 
logic [0:15] [0:15] [2:0] hit_colors = 
		  {48'o5533333333333344,     
			48'o5553333333333444,    
			48'o1555333333334442, 
			48'o1155533333344422,
			48'o1115553333444222,
			48'o1111555334442222,
			48'o1111155544422222,
			48'o1111114444222222,
			48'o1111114444222222,
			48'o1111177766622222,
			48'o1111777006662222,
			48'o1117770000666222,
			48'o1177700000066622,
			48'o1777000000006662,
			48'o7770000000000666,
			48'o7700000000000066};
 
 
// pipeline (ff) to get the pixel color from the array 	 

//////////--------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		HitEdgeCode <= 3'h0;
		counter <= 3'b000;

	end

	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default  
		HitEdgeCode <= 3'h0;

		if (InsideRectangle == 1'b1 && direction == 3'b111 ) 
		begin // inside an external bracket 
			RGBout <= object_colors_stand[texY][texX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];	//get hitting edge code from the colors table  
		
		end 
		if (InsideRectangle == 1'b1 && direction == 3'b010 )
		begin
		RGBout <= object_colors_left[texY][texX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
		end
		if (InsideRectangle == 1'b1 && direction == 3'b011 )
		begin
		RGBout <= object_colors_right[texY][texX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
		/*if(counter <= 15 && counter >= 0)
		begin
		RGBout <= object_colors_right[offsetY][offsetX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
			counter <= counter +1;
			end
			if(counter > 15 && counter <= 30)
		begin
		RGBout <= object_colors_right1[offsetY][offsetX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
			counter <= counter +1;
			end
			if(counter > 30 && counter < 45)
		begin
		RGBout <= object_colors_right2[offsetY][offsetX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
			counter <= counter +1;
			end
			if(counter >= 45 && counter < 60)
		begin
		RGBout <= object_colors_right3[offsetY][offsetX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
			counter <= counter + 1;
			end
			if( counter == 60)
			counter <= 0;*/
		end
		if (InsideRectangle == 1'b1 && direction == 3'b001 )
		begin
		RGBout <= object_colors_up[texY][texX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
		end
		if (InsideRectangle == 1'b1 && direction == 3'b000 )
		begin
		RGBout <= object_colors_down[texY][texX];
			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
		end
	end
		
end

//////////--------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule