// HartsMatrixBitMap File 
// A two level bitmap. dosplaying harts on the screen Feb 2025 
//(c) Technion IIT, Department of Electrical Engineering 2025 



module	WallsMatrixBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic collision_Smiley_Hart,
					input logic explosionPulse,
					input logic [10:0] bombX,
					input logic [10:0] bombY,
					input logic [10:0] bmanX,
					input logic [10:0] bmanY,
					input logic [2:0] random,
					input logic monsterbombercolloion,
					input logic startOfFrame,
					input logic playerFlower,
					input logic oneSecPulse,
					input logic keyCollected,
					input logic level1,
					input logic addTime,
					input logic addHealth,
					input logic speedBoost,
					output   logic collosionDR,
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,  //rgb value from the bitmap 
					output   logic [4:0] WallType,
					output 	logic outLives,
					output 	logic wallBreak
 ) ;
 

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hff ;// RGB value in the bitmap representing a transparent pixel 
logic [7:0] color ;
int rndm;


//-----

localparam  int TILE_WIDTH_X = 40;
localparam  int TILE_HEIGHT_Y = 30;
localparam  int MAZE_WIDTH_X = 15;
localparam  int MAZE_HEIGHT_Y =15;
localparam  int SRC_WIDTH_X = 32;
localparam  int SRC_HEIGHT_Y = 32;
localparam int MAX_HARTS = 3;

// Bits needed to index the maze 
localparam int MAZE_NUMBER_OF__X_BITS = $clog2(MAZE_WIDTH_X); // 4
localparam int MAZE_NUMBER_OF__Y_BITS = $clog2(MAZE_HEIGHT_Y); // 3


// 
logic [MAZE_NUMBER_OF__X_BITS-1:0] tile_x_idx;  // 0..10
logic [MAZE_NUMBER_OF__Y_BITS-1:0] tile_y_idx;  // 0..6
logic [$clog2(TILE_WIDTH_X)-1:0]   px_x_in_tile; // 0..56
logic [$clog2(TILE_HEIGHT_Y)-1:0]  px_y_in_tile; // 0..54
int bombXposMAT;
int bombYposMAT ;
int manXposMAT;
int manYposMAT;
int hitFlag;
logic [16:0] constBombX;
logic [16:0] constBombY;
logic [16:0] constmanX;
logic [16:0] constmanY;
int lock1,lock2,lock3,lock4,lock5;
int nexthart = 1;
int gameover = 0;
int secLock = 0;
assign tile_x_idx   = offsetX / TILE_WIDTH_X;
assign tile_y_idx   = offsetY / TILE_HEIGHT_Y;
assign px_x_in_tile = offsetX % TILE_WIDTH_X;	
assign px_y_in_tile = offsetY % TILE_HEIGHT_Y;
// Map current pixel within the tile to a 32x32 source texel
wire [SRC_WIDTH_X-1:0] tex_x = (px_x_in_tile * SRC_WIDTH_X)  / TILE_WIDTH_X;  // 0..31
wire [SRC_HEIGHT_Y-1:0] tex_y = (px_y_in_tile * SRC_HEIGHT_Y) / TILE_HEIGHT_Y; // 0..31

// Optional: guard for safety if offsetX/offsetY can wander outside the 11x7 area
wire inside_maze = (tile_x_idx < MAZE_WIDTH_X) && (tile_y_idx < MAZE_HEIGHT_Y);


 
// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 8 *16 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the understanding 


logic [0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][4:0] MazeBitMapMask;
logic [0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][4:0] MazeDefaultBitMapMask = '{
  '{0,0,0,0,0,0,0,0,0,0,7,1,1,1,1}, // row 1
  '{2,1,0,1,2,1,0,1,2,1,2,1,1,1,1}, // row 2
  '{0,0,3,0,0,4,0,0,0,0,0,0,4,1,1}, // row 3
  '{0,1,0,1,0,1,1,1,1,1,0,1,0,1,1}, // row 4
  '{0,0,3,0,0,1,0,0,3,1,0,2,0,1,1}, // row 5
  '{9,1,0,1,1,1,0,1,0,1,0,1,0,1,1}, // row 6
  '{0,0,0,0,0,1,0,0,0,1,0,2,2,1,1}, // row 7
  '{0,1,0,1,0,1,1,1,0,1,0,1,0,1,1}, // row 8
  '{0,6,0,0,10,4,0,1,0,2,0,4,0,1,1}, // row 9
  '{1,1,1,1,2,1,8,1,3,1,0,1,0,1,1}, // row 10
  '{1,1,1,1,0,0,0,0,0,0,4,0,0,1,1}, // row 11
  '{1,1,1,1,0,1,0,1,0,1,0,1,1,1,1}, // row 12
  '{1,1,1,1,0,0,4,4,0,0,0,1,1,1,1}, // row 13
  '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}, // row 14
  '{1,1,1,1,1,1,1,1,1,1,1,8,8,8,1} // row 15

};

logic [0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][4:0] MazeLevel1 = '{
  '{0,0,0,0,0,0,0,3,0,0,0,1,1,1,1}, // row 1
  '{2,1,0,1,0,1,0,1,4,1,0,1,1,1,1}, // row 2
  '{0,0,3,0,0,0,0,0,0,0,0,3,0,1,1}, // row 3
  '{10,1,0,1,0,1,1,1,1,1,0,1,0,1,1}, // row 4
  '{2,0,3,0,0,1,6,0,3,1,2,0,0,1,1}, // row 5
  '{0,1,0,1,1,1,0,1,0,1,2,1,7,1,1}, // row 6
  '{0,0,0,4,0,1,3,0,0,1,2,0,0,1,1}, // row 7
  '{0,1,0,1,0,1,1,1,0,1,0,1,0,1,1}, // row 8
  '{0,0,0,0,0,0,0,1,3,0,0,3,0,1,1}, // row 9
  '{1,1,1,1,2,1,3,1,0,1,0,1,0,1,1}, // row 10
  '{1,1,1,1,0,0,0,0,0,0,0,0,8,1,1}, // row 11
  '{1,1,1,1,0,1,0,1,9,1,0,1,1,1,1}, // row 12
  '{1,1,1,1,0,0,0,0,0,0,0,1,1,1,1}, // row 13
  '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}, // row 14
  '{1,1,1,1,1,1,1,1,1,1,1,8,8,8,1} // row 15

};


 logic [0:31][0:31][7:0] object_colors = '{32{'{32{8'hCD}} } };
 logic [0:31][0:31][7:0] clock = {{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hf6,8'hdf,8'hdf,8'h91,8'hdf,8'hff,8'hfa,8'he4,8'he4,8'he4,8'he4,8'he4,8'he0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hec,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hec,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hf6,8'he4,8'he4,8'he4,8'h91,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'h71,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hff,8'he4,8'he4,8'he4,8'hff,8'hff},
	{8'hff,8'hff,8'he4,8'he4,8'he4,8'hff,8'hdf,8'hdf,8'hdf,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'hdf,8'hdf,8'hff,8'he4,8'he4,8'hf6,8'hff},
	{8'hff,8'hff,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'he4,8'hff},
	{8'hff,8'hff,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'hff},
	{8'hff,8'he4,8'he4,8'he5,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'he4},
	{8'hff,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'he4},
	{8'hff,8'he4,8'he4,8'hed,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hed,8'he4,8'he4},
	{8'hff,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4},
	{8'hff,8'he4,8'he4,8'h91,8'h71,8'h91,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h6d,8'h71,8'h6d,8'h71,8'h71,8'h71,8'h71,8'h71,8'hdf,8'hdf,8'hdf,8'hff,8'h71,8'h71,8'h71,8'he4,8'he4},
	{8'hff,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h6d,8'h71,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'hdf,8'hdf,8'hdf,8'he4,8'he4},
	{8'hff,8'he4,8'he4,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'he4,8'hec},
	{8'hff,8'he4,8'he4,8'hec,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'he4},
	{8'hff,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'hec},
	{8'hff,8'he4,8'he4,8'he4,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'he4,8'he4,8'he4},
	{8'hff,8'hff,8'he4,8'he4,8'hfa,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hfe,8'he4,8'he4,8'hff},
	{8'hff,8'hff,8'hec,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'hec,8'hff},
	{8'hff,8'hff,8'hf6,8'he4,8'he4,8'hed,8'hdf,8'hdf,8'hdf,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'hdf,8'hdf,8'hed,8'he4,8'he4,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'hdf,8'hff,8'h91,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hff,8'hff,8'he4,8'he4,8'he4,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'hec,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h91,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hec,8'he4,8'he4,8'hf1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'he4,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'he4,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hfa,8'he4,8'he4,8'he4,8'he4,8'he4,8'hec,8'hf6,8'hdf,8'h71,8'hdf,8'hf6,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hf1,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hfa,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}};


 logic [0:31][0:31][7:0] level2wall = {
 {8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h80,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h80,8'h20,8'h00,8'h60,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h80,8'h60,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h60,8'ha4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'ha4,8'h60,8'h00,8'h80,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'ha0,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h60,8'ha4,8'hc4,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'h80,8'h20,8'h00,8'h80,8'hc4,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h80,8'h80,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h00,8'h00,8'h60,8'h80,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h20,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h84,8'ha4,8'ha4,8'ha4,8'ha4,8'h60,8'h00,8'h60,8'ha4,8'ha4,8'ha4,8'ha4,8'ha4,8'h80,8'h60,8'h60,8'h60,8'h00,8'h20,8'h80,8'ha4,8'ha4,8'h80,8'h60,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h60,8'ha4,8'hc4,8'ha4,8'ha4,8'ha4,8'h60,8'h00,8'h80,8'hc4,8'hc4,8'ha4,8'ha4,8'ha0,8'h80,8'h80,8'h80,8'h60,8'h20,8'h20,8'ha4,8'hc4,8'hc4,8'ha0,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h60,8'ha4,8'hc4,8'h80,8'h80,8'h80,8'h60,8'h00,8'h80,8'hc4,8'ha4,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h20,8'ha4,8'hc4,8'ha0,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h80,8'h80,8'h60,8'h60,8'h60,8'h20,8'h00,8'h60,8'h84,8'h80,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h00,8'h20,8'h60,8'h80,8'h60,8'h60,8'h60,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h20,8'h20,8'h00,8'h00,8'h20,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h60,8'ha4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'hc4,8'ha0,8'h80,8'h80,8'h60,8'h20,8'h00,8'h80,8'hc4,8'hc4,8'hc4,8'hc4,8'ha4,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h60,8'ha4,8'hc4,8'ha4,8'ha4,8'ha4,8'ha4,8'ha0,8'ha0,8'h80,8'h80,8'h60,8'h20,8'h00,8'h80,8'hc4,8'hc4,8'ha4,8'ha4,8'ha0,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h60,8'ha4,8'ha4,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h00,8'h80,8'hc4,8'ha0,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h80,8'ha0,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h00,8'h60,8'ha0,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h00,8'h20,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h20,8'h00,8'h20,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h20,8'h00,8'h20,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h20,8'h00,8'h20,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h20,8'h00,8'h20,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h60,8'h20,8'h20,8'h60,8'h80,8'h80,8'h80,8'h80,8'h60,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h20,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h00,8'h20,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h00,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h24,8'h00,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24}};

	
 logic [0:31][0:31][7:0] turbo = {
{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h2e,8'h00},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h12,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'h2e,8'h00},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h17,8'h1b,8'h1b,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'h2e,8'h00},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h1b,8'h1b,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'h2e,8'h00},
	{8'hff,8'hff,8'hff,8'h00,8'h00,8'h1b,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'h2e,8'h00},
	{8'hff,8'hff,8'hff,8'h00,8'h1b,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h17,8'h17,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'h2e,8'h00},
	{8'hff,8'hff,8'h00,8'h1b,8'h05,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'h2e,8'h00},
	{8'hff,8'h00,8'h04,8'h1b,8'h00,8'h1b,8'h1b,8'h1b,8'h17,8'h00,8'h6e,8'h2e,8'h2e,8'h6e,8'h6e,8'h2e,8'h2e,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'h2e,8'h00},
	{8'hff,8'h00,8'h1b,8'h00,8'h16,8'h1b,8'h1b,8'h1b,8'h00,8'h6e,8'h6e,8'h2e,8'h00,8'h00,8'h00,8'h01,8'h2e,8'h6e,8'h25,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h6e,8'h00},
	{8'hff,8'h00,8'h1b,8'h00,8'h1b,8'h1b,8'h1b,8'h00,8'h6e,8'h2e,8'h00,8'h00,8'h71,8'h96,8'h00,8'h00,8'h00,8'h6e,8'h2e,8'h05,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'hff,8'hff,8'h00,8'h00,8'h00},
	{8'h00,8'h17,8'h12,8'h00,8'h1b,8'h1b,8'h00,8'h00,8'h6e,8'h25,8'h00,8'h96,8'h96,8'h96,8'h00,8'h96,8'h6d,8'h00,8'h2e,8'h26,8'h00,8'h1b,8'h1b,8'h00,8'h00,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'h00,8'h1b,8'h00,8'h1b,8'h1b,8'h1b,8'h00,8'h6e,8'h2e,8'h00,8'h00,8'hb6,8'h96,8'h00,8'h00,8'h96,8'hb6,8'h6d,8'h00,8'h26,8'h00,8'h00,8'h05,8'h00,8'h00,8'h05,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'h00,8'h1b,8'h00,8'h1b,8'h1b,8'h1b,8'h00,8'h2e,8'h6e,8'h00,8'h91,8'h00,8'h00,8'h24,8'h00,8'h00,8'h96,8'h00,8'h00,8'h6e,8'h26,8'h00,8'h12,8'h00,8'h00,8'h12,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'h00,8'h1b,8'h00,8'h1b,8'h1b,8'h1b,8'h00,8'h2e,8'h2e,8'h00,8'h96,8'h96,8'h00,8'hb6,8'hb6,8'h00,8'h00,8'h2d,8'h00,8'h2e,8'h26,8'h00,8'h1b,8'h12,8'h12,8'h1b,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h2e,8'h6e,8'h00,8'h96,8'hb6,8'h00,8'h91,8'h00,8'h00,8'h96,8'h6d,8'h00,8'h2e,8'h26,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h2e,8'h6e,8'h00,8'h96,8'h00,8'h00,8'h00,8'h00,8'h92,8'h96,8'h6d,8'h00,8'h26,8'h01,8'h00,8'h1b,8'h1b,8'h1b,8'h13,8'h04,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'h00,8'h17,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h00,8'h2e,8'h00,8'h00,8'h00,8'h96,8'h96,8'h96,8'h00,8'h6d,8'h00,8'h6e,8'h26,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h6e,8'h2e,8'h00,8'h00,8'h96,8'h96,8'h96,8'h00,8'h00,8'h2e,8'h2e,8'h25,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h05,8'h00,8'h2e,8'h2e,8'h6e,8'h00,8'h00,8'h00,8'h00,8'h2e,8'h6e,8'h26,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'h00,8'h0d,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h05,8'h00,8'h2e,8'h2e,8'h6e,8'h2e,8'h6e,8'h2e,8'h6e,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h1b,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'h91,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h0e,8'h00,8'h00,8'h17,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h0d,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h17,8'h00,8'h16,8'h12,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h05,8'h1b,8'h13,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h05,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h17,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h1b,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}};

	
 logic [0:31][0:31][7:0] level3wall = {
   {8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'h93,8'hbb,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hbb,8'h93,8'hdf,8'h97,8'h97,8'hdf,8'hdf,8'h92},
	{8'hbb,8'hb7,8'hb7,8'hb7,8'hb7,8'h97,8'h72,8'hb7,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hb7,8'h72,8'hdb,8'h97,8'h97,8'hdf,8'hdf,8'h92},
	{8'hbb,8'h97,8'h97,8'h97,8'h97,8'h93,8'h6e,8'hb6,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hb7,8'h6e,8'hdb,8'h97,8'h97,8'hdf,8'hdf,8'h92},
	{8'hbb,8'h97,8'h97,8'h97,8'h97,8'h93,8'h6e,8'hb6,8'h97,8'h97,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hb7,8'h6e,8'hdb,8'h97,8'h97,8'hdf,8'hdf,8'h92},
	{8'hbb,8'h97,8'h97,8'h97,8'h97,8'h93,8'h6e,8'hb6,8'h97,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hb7,8'h6e,8'hdb,8'h97,8'h97,8'hdf,8'hdf,8'h92},
	{8'hb7,8'h97,8'h97,8'h93,8'h93,8'h93,8'h2e,8'h96,8'hdf,8'hdf,8'hdb,8'hbb,8'hbb,8'hbb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hbb,8'hbb,8'hbb,8'hdb,8'h97,8'h2d,8'hba,8'hdf,8'hdf,8'hbb,8'hbb,8'h72},
	{8'h97,8'h93,8'h72,8'h6e,8'h6e,8'h6e,8'h25,8'h6e,8'h97,8'h97,8'h92,8'h72,8'h72,8'h72,8'h92,8'h93,8'h93,8'h93,8'h93,8'h72,8'h72,8'h72,8'h72,8'h92,8'h72,8'h25,8'h6d,8'h72,8'h72,8'h72,8'h72,8'h2d},
	{8'hbb,8'hbb,8'hb7,8'hb6,8'hb6,8'h96,8'h96,8'hb6,8'hbb,8'hbb,8'hbb,8'hb7,8'hb6,8'hb6,8'hb7,8'h97,8'h72,8'h6e,8'h97,8'h97,8'h92,8'h92,8'h92,8'h97,8'h93,8'h72,8'h72,8'h92,8'h72,8'h72,8'h72,8'h2d},
	{8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdb,8'hb7,8'h72,8'h6e,8'hbb,8'hbb,8'h97,8'h97,8'hb7,8'hb7,8'hb7,8'h97,8'h97,8'h97,8'h97,8'h93,8'h93,8'h6e},
	{8'hdf,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hbb,8'h72,8'h6d,8'hbb,8'hdb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hb7,8'h97,8'h97,8'h6e},
	{8'hdf,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hbb,8'h72,8'h6d,8'hbb,8'hdb,8'hbb,8'hbb,8'hbb,8'hb7,8'hb7,8'hbb,8'hb7,8'h97,8'h97,8'h97,8'h97,8'h6e},
	{8'hdf,8'hdf,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hbb,8'h72,8'h6d,8'hbb,8'hdb,8'hbb,8'hbb,8'hbb,8'hbb,8'hb7,8'hb7,8'h97,8'h97,8'h97,8'h97,8'h97,8'h6e},
	{8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hbb,8'h72,8'h6d,8'hbb,8'hdb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h6e},
	{8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hbb,8'h72,8'h6d,8'hbb,8'hdb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h6e},
	{8'hb7,8'hb7,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h92,8'h6d,8'h2d,8'h25,8'h71,8'h92,8'h97,8'h97,8'h97,8'h97,8'h93,8'h93,8'h93,8'h93,8'h72,8'h72,8'h72,8'h2d},
	{8'h97,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h72,8'h72,8'h93,8'h97,8'h97,8'h97,8'h97,8'h72,8'h2d,8'h2d,8'h6d,8'h6d,8'h72,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h72,8'h6e,8'h6e,8'h2d},
	{8'hb7,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h72,8'h6e,8'h97,8'hbb,8'hbb,8'hbb,8'hbb,8'h97,8'h92,8'h92,8'h92,8'h92,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h93,8'h93,8'h73,8'h2d},
	{8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'h72,8'h2d,8'hbb,8'hdf,8'hdf,8'hdf,8'hdf,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hb7,8'h97,8'h97,8'h6e},
	{8'hbb,8'hb7,8'h97,8'h97,8'h97,8'hb7,8'hb7,8'h72,8'h2d,8'hbb,8'hdf,8'hdb,8'hbb,8'hbb,8'hbb,8'hbb,8'hb7,8'hb7,8'hbb,8'hbb,8'hb7,8'h97,8'hb7,8'hbb,8'hbb,8'hb7,8'hbb,8'hbb,8'hb7,8'h97,8'h97,8'h6e},
	{8'hbb,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h72,8'h2d,8'hbb,8'hdf,8'hbb,8'hbb,8'hbb,8'hbb,8'hb7,8'h97,8'h97,8'hb7,8'hb7,8'h97,8'h97,8'h97,8'hb7,8'hb7,8'h97,8'hb7,8'hb7,8'hb7,8'h97,8'h97,8'h6e},
	{8'hbb,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h72,8'h2d,8'hbb,8'hdf,8'hdb,8'hbb,8'hbb,8'hb7,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h6e},
	{8'hbb,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h72,8'h2d,8'hbb,8'hdf,8'hbb,8'hbb,8'hbb,8'hb7,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h6e},
	{8'h97,8'h93,8'h72,8'h72,8'h72,8'h72,8'h72,8'h2d,8'h25,8'h96,8'hb7,8'hb7,8'h97,8'h97,8'h97,8'h93,8'h93,8'h93,8'h93,8'h93,8'h72,8'h72,8'h72,8'h72,8'h73,8'h93,8'h93,8'h93,8'h93,8'h73,8'h73,8'h2e},
	{8'h93,8'h6e,8'h2d,8'h25,8'h2d,8'h2d,8'h2d,8'h2d,8'h2d,8'h72,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h6e,8'h25,8'h25,8'h25,8'h25,8'h6d,8'h93,8'h93,8'h93,8'h72,8'h6e,8'h6e,8'h2d},
	{8'hb7,8'h96,8'h96,8'h92,8'h92,8'h92,8'h92,8'h92,8'h92,8'h97,8'hb7,8'hb7,8'hb7,8'hb7,8'hb7,8'hb7,8'hb7,8'hb7,8'h97,8'h72,8'h2d,8'h2d,8'h2d,8'h72,8'h96,8'hb7,8'hb7,8'hb7,8'h96,8'h92,8'h92,8'h6d},
	{8'hdf,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hb7,8'h72,8'h72,8'h93,8'hdf,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hdf,8'hdf,8'h92},
	{8'hdf,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hb7,8'h72,8'h72,8'h93,8'hdf,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hdf,8'h92},
	{8'hdf,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'h97,8'hdf,8'h97,8'h6e,8'h6e,8'h72,8'hdf,8'h97,8'h97,8'h97,8'h97,8'hdf,8'hdb,8'hbb,8'h72},
	{8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h96,8'h25,8'h25,8'h2d,8'hbb,8'hdf,8'hdf,8'hdf,8'hdf,8'hbb,8'hb7,8'h97,8'h6e},
	{8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'h96,8'h25,8'h04,8'h2d,8'hbb,8'hdf,8'hdf,8'hdf,8'hdf,8'hbb,8'h97,8'h97,8'h6e},
	{8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hdb,8'hbb,8'h92,8'h25,8'h25,8'h2d,8'h97,8'hdb,8'hdb,8'hdb,8'hbb,8'hb7,8'h93,8'h93,8'h6e},
	{8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h93,8'h6e,8'h25,8'h25,8'h25,8'h72,8'h93,8'h93,8'h93,8'h93,8'h72,8'h6e,8'h6e,8'h2d}};

	
	
	logic [0:31][0:31][7:0] flower = {
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h8d,8'h81,8'hfa,8'hda,8'h65,8'h65,8'h85,8'h61,8'h61,8'hff,8'hba,8'h81,8'h8d,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h71,8'h00,8'h00,8'ha1,8'hc2,8'h81,8'h61,8'h81,8'ha6,8'hf3,8'hc6,8'h81,8'h61,8'h65,8'he2,8'ha2,8'h24,8'h24,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'ha2,8'h61,8'h20,8'ha6,8'he7,8'h82,8'h81,8'hc2,8'he7,8'hf3,8'he7,8'hc2,8'h81,8'h81,8'hef,8'ha6,8'h00,8'h61,8'h85,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h71,8'h61,8'he3,8'hc2,8'h61,8'hae,8'hef,8'ha6,8'ha2,8'he3,8'he7,8'hef,8'he7,8'he3,8'ha2,8'ha6,8'hf3,8'ha6,8'h61,8'ha2,8'he3,8'h61,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h6d,8'h65,8'he7,8'he7,8'ha2,8'ha2,8'h65,8'h61,8'h61,8'h61,8'hc2,8'he7,8'hc2,8'h61,8'h61,8'h61,8'h85,8'ha2,8'hc2,8'he7,8'he7,8'h61,8'hdf,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h65,8'hef,8'he7,8'hc2,8'h81,8'h60,8'h60,8'h60,8'h20,8'h81,8'hc2,8'ha1,8'h60,8'h60,8'h20,8'h20,8'h81,8'hc2,8'he7,8'hcf,8'h65,8'h91,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hd6,8'h20,8'h86,8'h81,8'h61,8'h80,8'ha1,8'hc1,8'hc1,8'he1,8'ha1,8'h61,8'ha1,8'he1,8'hc1,8'hc1,8'h81,8'h81,8'h61,8'h81,8'ha2,8'h60,8'h91,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h65,8'h61,8'h61,8'h60,8'ha1,8'he1,8'hc1,8'he1,8'hee,8'hc5,8'h81,8'hc5,8'hee,8'he5,8'he1,8'hc1,8'h80,8'h60,8'h61,8'h61,8'h65,8'h8d,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h2d,8'hce,8'hce,8'h20,8'h60,8'h85,8'hc1,8'he1,8'hc1,8'hce,8'hff,8'hf6,8'he5,8'hf6,8'hfb,8'hcd,8'hc1,8'he1,8'he1,8'ha1,8'h60,8'h20,8'hce,8'hb2,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h24,8'he7,8'hc6,8'h20,8'h60,8'hc1,8'hee,8'hee,8'ha5,8'h85,8'h92,8'had,8'ha1,8'had,8'h92,8'h85,8'ha1,8'hf2,8'hee,8'hc1,8'h60,8'h20,8'hc6,8'hc6,8'h20,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'hc2,8'hc2,8'h20,8'h60,8'he2,8'hf2,8'hdf,8'h6d,8'h00,8'h00,8'h04,8'h00,8'h00,8'h00,8'h00,8'h2d,8'hff,8'hf2,8'he2,8'h80,8'h20,8'hc2,8'ha2,8'h20,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'h61,8'h61,8'h20,8'h80,8'he1,8'hc5,8'h8d,8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h20,8'h00,8'h24,8'h91,8'hce,8'he2,8'h80,8'h00,8'h61,8'h81,8'h20,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h20,8'h20,8'h00,8'h81,8'he1,8'h81,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'he1,8'h80,8'h00,8'h20,8'h20,8'h00,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'ha2,8'h81,8'h20,8'h60,8'hc1,8'h60,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h60,8'ha1,8'h60,8'h20,8'h81,8'h81,8'h20,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hb6,8'ha2,8'ha2,8'h20,8'h60,8'hc1,8'h60,8'h00,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h61,8'ha1,8'h60,8'h20,8'ha2,8'ha2,8'h91,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h8d,8'h60,8'h20,8'h81,8'he1,8'h81,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'he1,8'h80,8'h00,8'h20,8'h92,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h24,8'h60,8'hc1,8'had,8'h71,8'h24,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h24,8'h71,8'had,8'hc1,8'h80,8'h04,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h6d,8'h60,8'ha1,8'hd6,8'hdf,8'h6d,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h6d,8'hff,8'hf6,8'ha5,8'h60,8'h6d,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h61,8'h60,8'h60,8'hcd,8'hee,8'h85,8'h64,8'h91,8'h6d,8'h00,8'h6d,8'h92,8'h85,8'ha5,8'hf2,8'hcd,8'h60,8'h60,8'h61,8'hb6,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h31,8'h20,8'h81,8'h61,8'h20,8'h81,8'he1,8'hc1,8'hce,8'hfb,8'hb6,8'h24,8'hb6,8'hff,8'hce,8'hc1,8'he1,8'h81,8'h20,8'h61,8'h81,8'h20,8'h30,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h71,8'h70,8'h30,8'h24,8'h20,8'h00,8'h20,8'h81,8'hc1,8'he2,8'hee,8'he6,8'hc1,8'he6,8'hee,8'he1,8'hc1,8'h80,8'h20,8'h00,8'h20,8'h64,8'h70,8'h70,8'h70,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hb5,8'h74,8'h74,8'h2c,8'h24,8'h00,8'h04,8'h24,8'ha1,8'he1,8'hc1,8'he1,8'hc1,8'hc1,8'he1,8'he1,8'ha1,8'h24,8'h04,8'h00,8'h04,8'h2c,8'h34,8'h34,8'h71,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h71,8'h2c,8'h74,8'h30,8'h0c,8'h30,8'h74,8'h6c,8'h24,8'h20,8'h60,8'h24,8'h64,8'h60,8'h24,8'h6c,8'h74,8'h30,8'h0c,8'h30,8'h74,8'h2c,8'h95,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h2c,8'h38,8'h34,8'h30,8'h34,8'h38,8'h10,8'h0c,8'h04,8'h04,8'h0c,8'h04,8'h04,8'h0c,8'h30,8'h74,8'h34,8'h30,8'h34,8'h78,8'h2c,8'h75,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h04,8'h14,8'h38,8'h78,8'h34,8'h0c,8'h14,8'h10,8'h04,8'h0c,8'h10,8'h0c,8'h04,8'h10,8'h10,8'h10,8'h34,8'h98,8'h38,8'h14,8'h2c,8'hb6,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hde,8'h2c,8'h34,8'h38,8'h34,8'h34,8'h10,8'h0c,8'h04,8'h0c,8'h14,8'h0c,8'h0c,8'h0c,8'h14,8'h34,8'h38,8'h38,8'h30,8'h0c,8'hb9,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h2c,8'h0c,8'h14,8'h78,8'h78,8'h10,8'h0c,8'h0c,8'h0c,8'h14,8'h10,8'h04,8'h0c,8'h10,8'h78,8'h38,8'h14,8'h0c,8'h2c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h00,8'h04,8'h0c,8'h30,8'h30,8'h14,8'h10,8'h10,8'h10,8'h10,8'h14,8'h10,8'h10,8'h10,8'h30,8'h10,8'h0c,8'h04,8'h04,8'hba,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h75,8'h04,8'h00,8'h00,8'h04,8'h04,8'h0c,8'h10,8'h30,8'h14,8'h10,8'h0c,8'h10,8'h14,8'h10,8'h10,8'h0c,8'h04,8'h00,8'h00,8'h00,8'h0c,8'hba,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h95,8'h04,8'h00,8'h64,8'h8c,8'h64,8'h04,8'h04,8'h04,8'h04,8'h04,8'h00,8'h04,8'h04,8'h04,8'h2c,8'h90,8'h24,8'h00,8'h00,8'h04,8'h04,8'hba,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h95,8'h04,8'h2c,8'h8c,8'h64,8'h00,8'h00,8'h00,8'h00,8'h24,8'h64,8'h24,8'h00,8'h00,8'h24,8'h90,8'h64,8'h00,8'h00,8'h04,8'h95,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h95,8'h04,8'h20,8'h00,8'h00,8'h00,8'h00,8'h00,8'h6c,8'hb5,8'h8c,8'h00,8'h00,8'h00,8'h04,8'h00,8'h00,8'h04,8'h95,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}};

	
	
	logic [0:31][0:31][7:0] flower_dead = {
	{8'he3,8'he3,8'he3,8'he3,8'he3,8'hc1,8'h80,8'h80,8'hc1,8'he3,8'he3,8'he3,8'hc1,8'he1,8'he1,8'he1,8'ha0,8'hc2,8'he3,8'he3,8'hc2,8'ha0,8'h80,8'ha0,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'he3,8'he3,8'ha1,8'he0,8'he1,8'he1,8'hc1,8'he3,8'he3,8'ha1,8'he0,8'he1,8'he1,8'h80,8'hc2,8'he3,8'hc1,8'he1,8'he1,8'he0,8'h80,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc2,8'hc2,8'hc2,8'hc1,8'he1,8'he1,8'he1,8'he0,8'he1,8'hc2,8'hc1,8'he0,8'he1,8'he1,8'hc0,8'hc1,8'he2,8'he0,8'he0,8'he1,8'he1,8'ha1,8'hc2,8'hc2,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'h80,8'ha0,8'hc0,8'he2,8'hc2,8'ha0,8'he0,8'he1,8'he0,8'hc0,8'he1,8'he1,8'he1,8'he1,8'he1,8'he0,8'he0,8'he1,8'he1,8'hc0,8'hc2,8'he3,8'hc1,8'ha0,8'h80,8'ha1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'h80,8'he1,8'he1,8'he1,8'hc0,8'he1,8'he1,8'he2,8'he1,8'he1,8'he1,8'he1,8'he2,8'he1,8'he1,8'he1,8'he1,8'he2,8'he1,8'he1,8'hc0,8'hc0,8'he1,8'he1,8'ha0,8'ha1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc2,8'he1,8'he0,8'he0,8'he1,8'he1,8'he1,8'he1,8'he1,8'he0,8'he0,8'he1,8'he2,8'he1,8'he0,8'he0,8'he0,8'he1,8'he1,8'he1,8'he1,8'he0,8'he0,8'he0,8'ha0,8'ha1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'ha1,8'ha0,8'he0,8'he1,8'he1,8'he1,8'he1,8'he0,8'he0,8'he0,8'he0,8'he1,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'he1,8'he1,8'he1,8'he0,8'h80,8'ha1,8'hc2,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'ha1,8'ha0,8'he0,8'he1,8'he1,8'he1,8'hc0,8'he0,8'he1,8'he1,8'he1,8'he0,8'he0,8'he1,8'he1,8'he0,8'ha0,8'he0,8'he1,8'he1,8'he1,8'hc0,8'h80,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc1,8'ha0,8'h80,8'hc0,8'he1,8'he1,8'he1,8'hc0,8'he0,8'he1,8'he3,8'he3,8'he1,8'he2,8'he3,8'he2,8'he0,8'ha0,8'he0,8'he1,8'he1,8'hc0,8'ha0,8'h80,8'ha1,8'hc2,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'h80,8'he0,8'he0,8'he0,8'he1,8'he1,8'he1,8'ha0,8'he0,8'he1,8'he3,8'he3,8'he1,8'he2,8'he3,8'he2,8'he0,8'hc0,8'he0,8'he1,8'he1,8'he0,8'he0,8'he0,8'ha0,8'ha1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'ha0,8'he1,8'he1,8'he1,8'he1,8'he1,8'he0,8'ha0,8'he0,8'he0,8'he0,8'h80,8'h80,8'h80,8'hc0,8'he0,8'he0,8'hc0,8'he0,8'he1,8'he1,8'he1,8'he1,8'he1,8'hc0,8'hc1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'hc1,8'he0,8'he1,8'he1,8'he1,8'he0,8'ha0,8'he0,8'he0,8'he0,8'h80,8'h80,8'h80,8'hc0,8'he0,8'he0,8'hc0,8'he0,8'he1,8'he1,8'he1,8'he0,8'hc0,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'ha1,8'ha0,8'he1,8'he1,8'he1,8'he0,8'ha0,8'he0,8'he0,8'he0,8'h80,8'h80,8'h80,8'hc0,8'he0,8'he0,8'hc0,8'he0,8'he1,8'he1,8'he1,8'he0,8'h80,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc2,8'he1,8'he0,8'he1,8'he1,8'he1,8'he0,8'ha0,8'he0,8'he0,8'he0,8'h80,8'h80,8'h80,8'hc0,8'he0,8'he0,8'hc0,8'hc0,8'he1,8'he1,8'he1,8'he1,8'he1,8'he2,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'h80,8'he1,8'he2,8'he2,8'he1,8'he1,8'he0,8'ha0,8'he0,8'he0,8'he0,8'h80,8'ha0,8'h80,8'ha0,8'he0,8'he0,8'ha0,8'hc0,8'he1,8'he1,8'he2,8'he2,8'he1,8'ha0,8'ha1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'h80,8'ha0,8'hc0,8'he1,8'he1,8'he1,8'he0,8'ha0,8'he0,8'he0,8'he0,8'hc0,8'he0,8'he0,8'ha0,8'he0,8'he0,8'ha0,8'hc0,8'he1,8'he1,8'he1,8'he0,8'ha0,8'h80,8'ha1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc2,8'hc2,8'hc2,8'hc1,8'he1,8'he1,8'he1,8'he1,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he1,8'he1,8'he1,8'hc0,8'hc1,8'hc2,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'he3,8'he3,8'ha1,8'he0,8'he1,8'he1,8'he1,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'he0,8'he1,8'he1,8'he0,8'h80,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'he3,8'he3,8'hc1,8'hc0,8'he1,8'he1,8'ha0,8'h80,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h80,8'h80,8'hc0,8'he1,8'hc0,8'ha0,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'hc2,8'ha0,8'hc1,8'he3,8'ha1,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h80,8'he3,8'hc2,8'ha0,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc1,8'ha1,8'ha1,8'ha1,8'ha0,8'h80,8'ha0,8'ha1,8'hc2,8'hc2,8'hc1,8'he0,8'he0,8'he0,8'hc0,8'hc1,8'hc2,8'ha1,8'ha0,8'h80,8'ha0,8'ha1,8'ha1,8'ha1,8'ha1,8'hc2,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'h80,8'hc0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'he0,8'he1,8'hc2,8'ha0,8'hc0,8'he0,8'he0,8'h80,8'ha1,8'hc2,8'he0,8'he0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'h80,8'ha1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'hc2,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'h80,8'he0,8'he0,8'he0,8'h80,8'ha0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc1,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'hc1,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'hc1,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'he1,8'he0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'he0,8'he0,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'hc1,8'hc0,8'he1,8'he1,8'hc0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'ha0,8'he1,8'he2,8'he1,8'ha0,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc1,8'he1,8'he0,8'he1,8'he1,8'he0,8'he0,8'ha0,8'h80,8'ha0,8'he1,8'he1,8'ha0,8'he0,8'he1,8'he0,8'h80,8'h80,8'hc0,8'he0,8'he1,8'he1,8'he0,8'he0,8'hc1,8'hc2,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'hc1,8'he1,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'hc0,8'he0,8'he1,8'he1,8'hc0,8'he0,8'he1,8'he1,8'he0,8'h80,8'hc0,8'he0,8'he0,8'hc0,8'he0,8'he0,8'hc1,8'hc2,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'hc1,8'ha0,8'he0,8'he0,8'ha0,8'h80,8'h80,8'he0,8'he1,8'he0,8'hc0,8'he0,8'he0,8'ha0,8'he0,8'he1,8'ha0,8'h80,8'h80,8'he0,8'he0,8'hc0,8'ha0,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'hc1,8'ha0,8'hc2,8'he3,8'he3,8'he3,8'he3,8'hc1,8'ha0,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3},
	{8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'hc2,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3,8'he3}};

	
	
	

	logic [0:31][0:31][7:0] door_closed = {
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h7f,8'h7f,8'h7f,8'h96,8'h96,8'h96,8'h96,8'h7f,8'h7f,8'h7f,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h04,8'h7a,8'h9f,8'h7f,8'h96,8'h96,8'h96,8'h9a,8'h96,8'h96,8'h9f,8'h96,8'h96,8'h96,8'h9f,8'h9f,8'h04,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h7a,8'h7a,8'h9a,8'h96,8'h2d,8'h00,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h00,8'h96,8'h96,8'h9f,8'h7a,8'h9f,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h7a,8'h96,8'h96,8'h96,8'h04,8'h84,8'h84,8'h84,8'hf1,8'h84,8'hf1,8'hd1,8'hd1,8'hd1,8'h84,8'hf0,8'h84,8'h84,8'h84,8'h96,8'h96,8'h96,8'h96,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'h00,8'h7a,8'h96,8'h7a,8'h00,8'h84,8'hf4,8'hf1,8'hd1,8'hf1,8'h84,8'hf1,8'hd1,8'hd1,8'hd1,8'h84,8'hd1,8'hf1,8'hf1,8'hf1,8'h84,8'h00,8'h7f,8'h96,8'h9f,8'h00,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'h00,8'h7f,8'h96,8'h96,8'h24,8'h84,8'ha4,8'hf5,8'hf1,8'hd1,8'hf1,8'h84,8'hf1,8'hd1,8'hf1,8'hd1,8'h84,8'hd1,8'hd1,8'hf1,8'hf1,8'hf5,8'h84,8'h96,8'h96,8'h96,8'h7f,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'h7f,8'h96,8'h9a,8'h04,8'h84,8'hd1,8'ha4,8'hf5,8'hf1,8'hf1,8'hf1,8'h84,8'hf1,8'hf1,8'hf1,8'hd1,8'h84,8'hd1,8'hd1,8'hf1,8'hd1,8'hf5,8'hd1,8'h64,8'h04,8'h9a,8'h96,8'h04,8'hff,8'hff},
	{8'hff,8'hff,8'h7f,8'h96,8'h96,8'h00,8'hcc,8'hd1,8'ha4,8'hf5,8'hd1,8'hf1,8'hd1,8'h84,8'hf1,8'hf1,8'hf1,8'hd1,8'h84,8'hd1,8'hd1,8'hf1,8'hf1,8'hf5,8'hd1,8'h84,8'h00,8'h96,8'h96,8'h04,8'hff,8'hff},
	{8'hff,8'h00,8'h7f,8'h7f,8'h0d,8'h84,8'hf0,8'hd1,8'ha4,8'hf5,8'hd1,8'hd1,8'hd1,8'h84,8'hf1,8'hf1,8'hd1,8'hd1,8'h84,8'hd1,8'hd1,8'hf1,8'hf1,8'hf5,8'hd1,8'hd1,8'h84,8'h9f,8'h7f,8'h7f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hf1,8'hd1,8'ha4,8'hf5,8'hd1,8'hd1,8'hd1,8'h84,8'hf5,8'hd1,8'hd1,8'hd1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hd1,8'hd1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7f,8'h9f,8'hf0,8'hf1,8'hf1,8'hf5,8'hf1,8'hf1,8'hf1,8'hf5,8'hf1,8'hf1,8'hf1,8'hf1,8'hf5,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'h84,8'h9f,8'h7f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h8c,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'hb6,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hf1,8'hd1,8'ha4,8'hf5,8'hf1,8'hd1,8'hd1,8'h84,8'hf1,8'hd1,8'hd1,8'hf1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hd1,8'hd1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hf1,8'hd1,8'ha4,8'hf5,8'hf1,8'hd1,8'hd1,8'h84,8'hf1,8'hf1,8'hd1,8'hf1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hf1,8'hf1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'h8c,8'hda,8'h64,8'hf5,8'hf1,8'hf1,8'hd1,8'h84,8'hf1,8'hf1,8'hf0,8'hd1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hf1,8'hf1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h7a,8'h04,8'h84,8'hf1,8'h2d,8'ha4,8'hf5,8'hd1,8'hf1,8'hf1,8'h84,8'hf1,8'hd1,8'hf1,8'hd1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hf1,8'hf1,8'h84,8'h9a,8'h7a,8'h7f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hf0,8'h2d,8'ha4,8'hf5,8'hd1,8'hd1,8'hf1,8'h84,8'hf1,8'hd1,8'hf1,8'hd1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hd1,8'hd1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7f,8'h7f,8'h0d,8'h84,8'hf0,8'h2d,8'ha4,8'hf5,8'hd1,8'hd1,8'hf1,8'h84,8'hf1,8'hd1,8'hf1,8'hd1,8'h84,8'hd1,8'hf1,8'hf1,8'hd1,8'hf5,8'hd1,8'hf1,8'h84,8'h9f,8'h7f,8'h7f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hac,8'hda,8'h84,8'hf5,8'hd1,8'hd1,8'hf1,8'h84,8'hf1,8'hd1,8'hf1,8'hd1,8'h84,8'hd1,8'hf1,8'hf1,8'hd1,8'hf5,8'hd1,8'hd1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7f,8'h7f,8'h0d,8'h84,8'hf0,8'hd1,8'ha4,8'hf5,8'hd1,8'hd1,8'hf1,8'h84,8'hf1,8'hd1,8'hd1,8'hd1,8'h84,8'hf0,8'hf1,8'hf1,8'hd1,8'hf5,8'hd1,8'hd1,8'h84,8'h9f,8'h7f,8'h7f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hf0,8'hd1,8'ha4,8'hf5,8'hd1,8'hd1,8'hf1,8'h84,8'hf1,8'hd1,8'hd1,8'hd1,8'h84,8'hf0,8'hf1,8'hd1,8'hf1,8'hf5,8'hd1,8'hd1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'h84,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'hf0,8'hd0,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h84,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hcc,8'hcc,8'h84,8'hcc,8'hac,8'hcc,8'hac,8'h84,8'hcc,8'hac,8'hac,8'hac,8'h84,8'hac,8'hcc,8'hac,8'hac,8'hcc,8'hac,8'hac,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h24,8'h84,8'hf1,8'hf1,8'ha4,8'hf5,8'hd1,8'hf1,8'hd1,8'h84,8'hf1,8'hf1,8'hd1,8'hd1,8'h84,8'hd1,8'hd1,8'hf1,8'hd1,8'hf5,8'hd1,8'hd1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'h00,8'h7a,8'h96,8'h04,8'h84,8'hf1,8'hd1,8'ha4,8'hf5,8'hf1,8'hd1,8'hd1,8'h84,8'hf1,8'hf1,8'hd1,8'hf1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hd1,8'hd1,8'h84,8'h96,8'h96,8'h9f,8'h00,8'hff},
	{8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h84,8'h84,8'h20,8'h84,8'h84,8'h84,8'h84,8'h00,8'h84,8'h84,8'h84,8'h84,8'h00,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}};


	logic [0:31][0:31][7:0] door_open = {
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h24,8'h24,8'h9f,8'h9f,8'h7f,8'h7a,8'h7a,8'h31,8'hf1,8'hf5,8'hf1,8'h84,8'hf1,8'h84,8'hb1,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h7f,8'h7f,8'h96,8'h96,8'h96,8'h7a,8'h96,8'h84,8'hf5,8'hf5,8'hf9,8'hd1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h7f,8'h96,8'h96,8'h96,8'h96,8'h00,8'h00,8'h24,8'h24,8'h84,8'hf5,8'hfd,8'hcc,8'hd1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'h7f,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'h71,8'h9f,8'h96,8'h96,8'h96,8'h04,8'h00,8'h24,8'h24,8'h24,8'h24,8'h84,8'hf5,8'hf9,8'hf5,8'hcc,8'hf1,8'h84,8'hf1,8'h84,8'hf1,8'h84,8'h84,8'h9b,8'h36,8'hb6,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'h00,8'h7b,8'h96,8'h9f,8'h00,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h64,8'hf5,8'hf5,8'hfd,8'hd1,8'hcc,8'hf1,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'h96,8'h96,8'h9f,8'hff,8'hff,8'hff},
	{8'hff,8'h00,8'h7f,8'h96,8'h96,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h64,8'hf5,8'hf5,8'hfd,8'hd1,8'hcc,8'hf1,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'hb6,8'h96,8'h7a,8'h00,8'hff,8'hff},
	{8'hff,8'h9f,8'h96,8'h7f,8'h96,8'h00,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'hf1,8'hcc,8'hd1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h7f,8'h9f,8'h7f,8'h00,8'hff},
	{8'hff,8'h9f,8'h96,8'h96,8'h00,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'hf1,8'hcc,8'hd1,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h7f,8'h00,8'hff},
	{8'h00,8'h7f,8'h7f,8'h2d,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'h84,8'hf5,8'hf5,8'hf5,8'h84,8'h84,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h7f,8'h7f,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'h84,8'hf5,8'hd1,8'hda,8'hd1,8'hd1,8'hf5,8'hf5,8'h84,8'h84,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h7f,8'h7f,8'h2d,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hac,8'h84,8'h84,8'hac,8'hac,8'hd5,8'hd1,8'hd1,8'hf1,8'hf1,8'hcc,8'h84,8'h7f,8'h7f,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'hf1,8'hcc,8'hd1,8'h84,8'ha4,8'h84,8'h84,8'h84,8'h84,8'hd1,8'h84,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hf0,8'hd1,8'hcc,8'hd1,8'h84,8'hf0,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd1,8'h25,8'hcc,8'hd1,8'h84,8'hf1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'h24,8'hda,8'hb1,8'hd1,8'h84,8'hf1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'h2d,8'hcc,8'hf1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hf1,8'h2d,8'hcc,8'hf1,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h9f,8'h9f,8'h2d,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'h2d,8'hcc,8'hf1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h9f,8'h9f,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'h64,8'hda,8'hb1,8'hd1,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h7f,8'h7f,8'h2d,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'h2d,8'hcc,8'hd1,8'h84,8'hf0,8'h84,8'hf1,8'h84,8'hf5,8'h84,8'h00,8'h7f,8'h7f,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'hf1,8'hcc,8'hf1,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h20,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h7f,8'h7f,8'h2d,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hf0,8'hd1,8'hcc,8'hd1,8'h84,8'ha4,8'h84,8'hac,8'hf5,8'hf5,8'hf1,8'hd1,8'h6c,8'h7f,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hd0,8'h84,8'h84,8'hf1,8'hf5,8'hf1,8'hd1,8'hd1,8'hd1,8'hd1,8'h84,8'h84,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'h84,8'hf5,8'hf5,8'hd1,8'hd1,8'hda,8'hd1,8'hd1,8'h84,8'h84,8'h84,8'h84,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'ha4,8'hf0,8'hcc,8'hcc,8'h84,8'h84,8'h84,8'ha4,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'h00,8'h76,8'h96,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'ha4,8'hf5,8'hf5,8'hf0,8'hd1,8'hcc,8'hf1,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'h84,8'h00,8'h96,8'h96,8'h7f,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha4,8'hf5,8'hf5,8'hd0,8'hf1,8'hcc,8'hf1,8'h84,8'hf0,8'h84,8'hf5,8'h84,8'hf5,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha4,8'hf5,8'hf5,8'hd0,8'hf1,8'hcc,8'hf1,8'h84,8'hf0,8'h84,8'hf1,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha4,8'hf5,8'hf5,8'hd0,8'hd1,8'hcc,8'hd1,8'h84,8'hfa,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha4,8'hf5,8'hf5,8'hd0,8'hd1,8'h84,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h84,8'h84,8'h84,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}};
	
	
	
	logic [0:31][0:31][7:0] key = {
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'h00,8'h00,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'h00,8'h00,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'h00,8'h00,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff},
	{8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'h00,8'h00,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff},
	{8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff},
	{8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'hff,8'hff,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'hff,8'hff,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'h00,8'h00,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfc,8'hfd,8'hfd,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfc,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'hff,8'hff,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfc,8'hfc,8'hff,8'hff,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'hfd,8'hfd,8'hfd,8'hfd,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hfc,8'hfc,8'hfd,8'hfd,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}};
	
	
	logic [0:31] [0:31] [7:0] harts = {
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'hc0,8'hc0,8'ha0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha0,8'hc0,8'hc0,8'hc0,8'hc0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha0,8'hc0,8'hc0,8'hc0,8'ha0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'ha0,8'hc0,8'hc0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'hc0,8'hc0,8'ha0,8'hc0,8'ha0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha0,8'ha0,8'ha0,8'ha0,8'hc0,8'ha0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'ha0,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'ha0,8'hff,8'hff,8'ha0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'ha0,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'he0,8'he0,8'hfa,8'hfa,8'hfa,8'hfa,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'he0,8'he0,8'hfa,8'hfa,8'hfa,8'hfa,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'ha0,8'ha0,8'he4,8'he4,8'he4,8'he4,8'he0,8'he0,8'he4,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hfa,8'hf6,8'hf6,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hfa,8'hfa,8'hfa,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hfa,8'hfa,8'hfa,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hc0,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'ha0,8'ha0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'hc0,8'ha0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'ha0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'ha0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'ha0,8'ha0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'he0,8'he0,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hc0,8'hc0,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb1,8'hd1,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}};
	
// pipeline (ff) to get the pixel color from the array 	 
int Hits = 0;
int oneSecLock =0;
int firstTime = 0;
//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		MazeBitMapMask  <=  MazeLevel1 ;  //  copy default tabel 
		hitFlag <= 0;
		lock1 <= 0;
		lock2 <= 0;
		lock3 <= 0;
		lock4 <= 0;
		lock5 <= 0;
		nexthart <= 1;
		gameover <= 0;
		Hits <= 0;
		secLock <= 0;
		oneSecLock <= 0;
		wallBreak <= 0;
		firstTime <= 0;
	end
	else begin
		if (oneSecPulse)begin
			secLock <= secLock + 1;
			oneSecLock <= 1;
		end
		wallBreak <= 0;
		outLives = (Hits >= 3) ? 1'b1 : 1'b0;
		rndm <= random % 2;
		RGBout <= TRANSPARENT_ENCODING ; // default
			constBombX <= bombX - 9;
			constBombY <= bombY - 13;
			constmanX <= bmanX - 12;
			constmanY <= bmanY - 18;
			manXposMAT <= (constmanX) /TILE_WIDTH_X ;
			manYposMAT <= (constmanY) /TILE_HEIGHT_Y ;
			bombXposMAT <= (constBombX) /TILE_WIDTH_X ;
			bombYposMAT <= (constBombY) /TILE_HEIGHT_Y;	
		//if (collision_Smiley_Hart)
			//MazeBitMapMask[tile_y_idx][tile_x_idx] <= 4'h00;  // clear entry 
			
		if (!explosionPulse) begin
			lock1 <= 0;
			lock2 <= 0;
			lock3 <= 0;
			lock4 <= 0;
			lock5 <= 0;
		end
		
		if(rndm == 0) begin   // explotion on X 
			if (explosionPulse && MazeBitMapMask[bombYposMAT][bombXposMAT + 1] == 2 && !lock1)begin
					MazeBitMapMask[bombYposMAT][bombXposMAT + 1] <= 0;
					wallBreak <= 1;
					lock1 <= 1;
					end
		else if (explosionPulse && MazeBitMapMask[bombYposMAT][bombXposMAT + 1] == 3 && !lock1) begin
					MazeBitMapMask[bombYposMAT][bombXposMAT + 1] <= 2;
					wallBreak <= 1;
					lock1 <= 1;
					end
		if (explosionPulse && MazeBitMapMask[bombYposMAT][bombXposMAT - 1] == 2 && !lock2) begin
					MazeBitMapMask[bombYposMAT][bombXposMAT - 1] <= 0;		
					wallBreak <= 1;
					lock2 <= 1;
					end
		else if (explosionPulse && MazeBitMapMask[bombYposMAT][bombXposMAT - 1] == 3 && !lock2) begin
					MazeBitMapMask[bombYposMAT][bombXposMAT - 1] <= 2;
					wallBreak <= 1;
					lock2 <= 1;
					end
		end
		
		
		if (rndm == 1) begin // explotion on Y 
			
		if (explosionPulse && MazeBitMapMask[bombYposMAT+1][bombXposMAT ] == 2 && !lock3) begin
					MazeBitMapMask[bombYposMAT+1][bombXposMAT ] <= 0;
					wallBreak <= 1;		
					lock3 <= 1;
					end
		else if (explosionPulse && MazeBitMapMask[bombYposMAT+1][bombXposMAT ] == 3 && !lock3 ) begin
					MazeBitMapMask[bombYposMAT+1][bombXposMAT ] <= 2;	
					wallBreak <= 1;
					lock3 <= 1;
				   end	
		if (explosionPulse && MazeBitMapMask[bombYposMAT-1][bombXposMAT ] == 2 && !lock4) begin
					MazeBitMapMask[bombYposMAT-1][bombXposMAT ] <= 0;	
					wallBreak <= 1;
					lock4 <= 1;
					end
		else if (explosionPulse && MazeBitMapMask[bombYposMAT-1][bombXposMAT ] == 3 && !lock4) begin
					MazeBitMapMask[bombYposMAT-1][bombXposMAT ] <= 2;
					wallBreak <= 1;
					lock4 <= 1;
					end
		if (explosionPulse && MazeBitMapMask[bombYposMAT][bombXposMAT ] == 2 && !lock5) begin
					MazeBitMapMask[bombYposMAT][bombXposMAT ] <= 0;
					wallBreak <= 1;
					lock5 <= 1;
					end
		else if (explosionPulse && MazeBitMapMask[bombYposMAT][bombXposMAT ] == 3 && !lock5) begin
					MazeBitMapMask[bombYposMAT][bombXposMAT ] <= 2;
					wallBreak <= 1;
					lock5 <= 1;
					end
		
		end
					
					
					
				if(!level1 && !firstTime)begin
					firstTime <= 1;
					MazeBitMapMask <= MazeDefaultBitMapMask;
				end
				if( keyCollected  && level1 )begin
					MazeBitMapMask[4][6] <= 5 ;
					MazeBitMapMask[5][12] <= 0 ;
					end
				if (keyCollected && !level1) begin
					MazeBitMapMask[0][10] <= 0;
					MazeBitMapMask[8][1] <= 5;
					end
				if (addTime && level1)begin
					MazeBitMapMask[11][8] <= 0;
					end
				if (addTime && !level1)begin
					MazeBitMapMask[5][0] <= 0;
					end
				if (addHealth && level1)begin
					MazeBitMapMask[10][12] <= 0;
					end
				if (addHealth && !level1) begin
					MazeBitMapMask[9][6] <= 0;
					end
				if(addHealth)begin
					nexthart <= nexthart - 1;
					MazeBitMapMask[14][9+nexthart] <= 8;
					end
				if(speedBoost)begin
					MazeBitMapMask[1][14] <= 10;
					end
				if(speedBoost && level1)begin
					MazeBitMapMask[3][0] <= 0;
					end
				if(speedBoost && !level1)begin
					MazeBitMapMask[8][4] <= 0;
					end
				if (!speedBoost) begin
					MazeBitMapMask[1][14] <= 0;
					end
	if(((monsterbombercolloion && !hitFlag)||(playerFlower && !hitFlag)) && secLock >= 3 && oneSecLock)begin
					Hits <= Hits + 1;
					hitFlag <= 1;
					oneSecLock <= 0;
					//MazeBitMapMask  <=  MazeDefaultBitMapMask ;
					MazeBitMapMask[14][10+nexthart] <= 1;
					
					/*for (int i = 0; i < MAX_HARTS; i++) begin
						if (i+1 < nexthart) 
							MazeBitMapMask[14][11+i] <= 1 ;
							end*/
					nexthart <= nexthart + 1 ;
					if(nexthart >= 4  && !level1) begin
							MazeBitMapMask  <=  MazeDefaultBitMapMask ;
							nexthart <= 1 ;
							gameover <= 1 ;
							end
					if(nexthart >= 4  && level1) begin
							MazeBitMapMask  <=  MazeLevel1 ;
							nexthart <= 1 ;
							gameover <= 1 ;
							end
					end
					
					if (gameover)begin 
						outLives <= 1;
					end
					else outLives <= 0;
					if(!monsterbombercolloion || !playerFlower)
						hitFlag <= 0;
					
		if (InsideRectangle == 1'b1 )	
			begin 
		   	case (MazeBitMapMask[tile_y_idx][tile_x_idx])
					5'h0: begin RGBout <= TRANSPARENT_ENCODING;
							color <= TRANSPARENT_ENCODING;
							WallType <= 0;
							end
					5'h1: begin color <= TRANSPARENT_ENCODING;
							RGBout <= object_colors[tex_y][tex_x];
							WallType <= 1;
							end
					5'h2: begin color <= level2wall[tex_y][tex_x];
							RGBout <= level2wall[tex_y][tex_x];
							WallType <= 2;
							end
					5'h3: begin color <= level3wall[tex_y][tex_x];
							RGBout <= level3wall[tex_y][tex_x];
							WallType <= 3;
							end
					5'h4: begin color <= flower[tex_y][tex_x];
							RGBout <= flower[tex_y][tex_x];
							WallType <= 4;
							end
					5'h5: begin color <= door_open[tex_y][tex_x];
							RGBout <= door_open[tex_y][tex_x];
							WallType <= 5;
							end
					5'h6: begin color <= door_closed[tex_y][tex_x];
							RGBout <= door_closed[tex_y][tex_x];
							WallType <= 6;
							end
					5'h7: begin color <= key[tex_y][tex_x];
							RGBout <= key[tex_y][tex_x];
							WallType <= 7;
							end
					5'h8: begin color <= harts[tex_y][tex_x];
							RGBout <= harts[tex_y][tex_x];
							WallType <= 8;
							end	
					5'h9: begin color <= clock[tex_y][tex_x];
							RGBout <= clock[tex_y][tex_x];
							WallType <= 9;
							end
					10: begin color <= turbo[tex_y][tex_x];
							RGBout <= turbo[tex_y][tex_x];
							WallType <= 10;
							end				
					default: begin RGBout <= TRANSPARENT_ENCODING;
								color <= TRANSPARENT_ENCODING;
								WallType <= 0;
								end
					endcase
			end 
			
		

	end 
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (color != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
assign collosionDR = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ;
endmodule

