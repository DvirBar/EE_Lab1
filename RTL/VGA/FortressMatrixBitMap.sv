// FortressMatrixBitMap File 
// A two level bitmap. displaying the fort on the screen
// Based on HartsMatrixBitMap (apr 2023) 
// (c) Technion IIT, Department of Electrical Engineering 2023 



module	FortressMatrixBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic [3:0] level,
					input logic [10:0] speedSum,
					input bird_wall_collision,
			

					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout  //rgb value from the bitmap 
 ) ;
 

// Size represented as Number of X and Y bits 
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 
int hitThreshold;
logic [2:0] renderedLevel;


// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 16*16 and use only the top left 16*15 squares 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the  understanding 


logic [0:15] [0:15] [3:0]  MazeBitMapMask ;  

//  1 - wood
//  2 - hollow wood
//  3 - glass
//  4 - stone
logic [0:4] [0:15] [0:15] [3:0]  MazeDefaultBitMapMask= // defult table to load on reset 
{

{{64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000001000000},
 {64'h0000000001400000},
 {64'h0000000111440000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000}},

{{64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000333330000},
 {64'h0000003001003000},
 {64'h0000000001000000},
 {64'h0000000001000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000}},
 
 {{64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000200000},
 {64'h0000000002120000},
 {64'h0000000033033000},
 {64'h0000000140004100},
 {64'h0000000144444100},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000}},
 
 {{64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000002020200},
 {64'h0000000002222200},
 {64'h0000000003000300},
 {64'h0000000004000400},
 {64'h0000000004000400},
 {64'h0000000004444400},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000}},
 
 {{64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000101010100},
 {64'h0000000111111100},
 {64'h0000000300300300},
 {64'h0000000111111100},
 {64'h0000000340004300},
 {64'h0000000444444400},
 {64'h0000000000000000},
 {64'h0000000000000000},
 {64'h0000000000000000}},
 
 };


 

 logic [0:3] [0:31] [0:31] [7:0]  object_colors  = {
{//fullwood
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hfe,8'hd5,8'hb1,8'hd5,8'hd5,8'hd5,8'hd5,8'hd5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hd5,8'hd5,8'hd5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hd5,8'hfa,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hf5,8'hd0,8'hf5,8'hfe,8'hfd,8'hf9,8'hf9,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hfd,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hb0,8'hd1,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hd1,8'hfe,8'hfe,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf8,8'hf8,8'hf9,8'hf9,8'hf9,8'hf8,8'hf8,8'hf8,8'hf8,8'hf8,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hac,8'hd5,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf5,8'hfd,8'hf9,8'hf8,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hcc,8'hf5,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf5,8'hfd,8'hfd,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hcc,8'hd0,8'hfe,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf5,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hac,8'hd5,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf5,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hd0,8'hac,8'hd5,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf5,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hcc,8'hac,8'hd5,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf4,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hec,8'ha4,8'hd1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf4,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hec,8'ha4,8'hd1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf4,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf5,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf4,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'hec,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf4,8'hfd,8'hf9,8'hf4,8'hf8,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hec,8'hf0,8'hf0,8'hec,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hf4,8'hfd,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hf5,8'hf4,8'hfd,8'hf9,8'hf4,8'hf4,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hd0,8'hf9,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hac,8'hf4,8'hf0,8'hcc,8'hd0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hac,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd1,8'hac,8'hf0,8'hf0,8'hd0,8'hf0,8'hf0,8'hf0,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hac,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hd5,8'hac,8'hf4,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hac,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hfa,8'hb0,8'hf4,8'hf8,8'hf4,8'hf4,8'hf8,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'hec,8'hcc,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hf5,8'hf0,8'hf9,8'hf8,8'hf4,8'hf8,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hd0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'hcc,8'hcc,8'ha4,8'hb1,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hf5,8'hd0,8'hf8,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hcc,8'hcc,8'hcc,8'hcc,8'hec,8'hec,8'hec,8'hcc,8'hcc,8'ha4,8'hd5,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hf9,8'hac,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hec,8'hec,8'hcc,8'hcc,8'hcc,8'hec,8'hec,8'hec,8'hec,8'hcc,8'hcc,8'hcc,8'hac,8'hac,8'hfa,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hfe,8'hb0,8'hd0,8'hf0,8'hf0,8'hcc,8'hcc,8'hcc,8'hcc,8'hec,8'hec,8'hec,8'hec,8'hf0,8'hec,8'hcc,8'hcc,8'hec,8'hec,8'hf0,8'hf0,8'hcc,8'hd0,8'hac,8'hd1,8'hfe,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hd1,8'h84,8'hcc,8'hcc,8'hf0,8'hd0,8'hcc,8'hcc,8'hec,8'hec,8'hec,8'hec,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'hcc,8'ha4,8'hac,8'hac,8'h84,8'hd1,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hfa,8'h84,8'h84,8'h84,8'h80,8'h80,8'h80,8'h80,8'h60,8'h60,8'h60,8'h60,8'h80,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h84,8'hac,8'hfa,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
},

{
	{8'hFF,8'hFF,8'hff,8'hff,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hff,8'hFF,8'hFF,8'hFF},
	{8'hfe,8'hd0,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf5,8'hf9,8'hf5,8'hf9,8'hf9,8'hf5,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hf9,8'hac,8'hFF},
	{8'hfe,8'hf9,8'hf9,8'hf5,8'hf5,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hf0,8'hf0,8'hd0,8'hf0,8'hf0,8'hf0,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf4,8'hd0,8'hf0,8'hd0,8'hd0,8'hb0,8'hFF},
	{8'hfa,8'hf9,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hf4,8'hf4,8'hf4,8'hf0,8'hd0,8'hd0,8'hcc,8'hcc,8'hcc,8'hac,8'hac,8'hfe},
	{8'hf5,8'hf9,8'hf4,8'hf5,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf0,8'hf0,8'hd0,8'hd0,8'hf0,8'hd0,8'hac,8'hac,8'hfa},
	{8'hf5,8'hf9,8'hf0,8'hf0,8'hf5,8'hf0,8'hf4,8'hf4,8'hf4,8'hf4,8'hf4,8'hf5,8'hf0,8'hf0,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hcc,8'hcc,8'hfe},
	{8'hd1,8'hf9,8'hf0,8'hf0,8'hf0,8'hf5,8'hf5,8'hf5,8'hf4,8'hf5,8'hf1,8'hd0,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hd0,8'hd0,8'hf1,8'hd0,8'hd0,8'hac,8'hd0,8'hd0,8'hd0,8'hd0,8'hac,8'hac,8'hfa},
	{8'hd1,8'hf5,8'hf0,8'hf0,8'hf4,8'hf5,8'hd0,8'hfa,8'hfe,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd5,8'hd0,8'hf0,8'hf0,8'hd0,8'hcc,8'hcc,8'hfa},
	{8'hb0,8'hf5,8'hf0,8'hf4,8'hf4,8'hf5,8'hd0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hfe,8'hd0,8'hd0,8'hd0,8'hd0,8'hcc,8'hcc,8'hfa},
	{8'hac,8'hf9,8'hf0,8'hf4,8'hf0,8'hf4,8'hd0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hcc,8'hd0,8'hd0,8'hd0,8'hd0,8'hcc,8'hfa},
	{8'hac,8'hf5,8'hf0,8'hf5,8'hf4,8'hf0,8'hd0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd1,8'hf1,8'hf1,8'hd0,8'hd0,8'hcc,8'hfa},
	{8'hac,8'hf9,8'hf0,8'hf0,8'hf0,8'hf5,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd1,8'hd0,8'hd0,8'hf0,8'hd0,8'hcc,8'hfa},
	{8'hac,8'hf5,8'hf0,8'hf0,8'hf4,8'hf5,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd1,8'hd0,8'hf0,8'hd0,8'hd0,8'hac,8'hfa},
	{8'hac,8'hf5,8'hf4,8'hf4,8'hf4,8'hf5,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd0,8'hd0,8'hd0,8'hd0,8'hcc,8'hac,8'hfa},
	{8'hac,8'hf5,8'hf4,8'hf4,8'hf0,8'hf0,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd0,8'hf0,8'hd0,8'hd0,8'hd0,8'hac,8'hfa},
	{8'hac,8'hf5,8'hf0,8'hf0,8'hf0,8'hf0,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd0,8'hf1,8'hf0,8'hf0,8'hd0,8'hac,8'hfa},
	{8'hac,8'hf5,8'hf4,8'hf4,8'hf5,8'hf5,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hcc,8'hf1,8'hd0,8'hd0,8'hd0,8'hac,8'hfa},
	{8'hac,8'hf5,8'hf4,8'hf4,8'hf4,8'hf5,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hcc,8'hf1,8'hd0,8'hd0,8'hd0,8'hac,8'hfa},
	{8'hac,8'hf9,8'hf4,8'hf4,8'hf0,8'hf0,8'hac,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hac,8'hcc,8'hcc,8'hac,8'hcc,8'hac,8'hfa},
	{8'hac,8'hf5,8'hf0,8'hf0,8'hf0,8'hf5,8'hd0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd0,8'hf0,8'hd0,8'hd0,8'hf1,8'hac,8'hfa},
	{8'hac,8'hf9,8'hf0,8'hf4,8'hf5,8'hf5,8'hd1,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd0,8'hf0,8'hd0,8'hd0,8'hd0,8'hac,8'hfa},
	{8'hac,8'hf9,8'hf4,8'hf5,8'hf4,8'hf5,8'hd1,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd0,8'hf0,8'hd0,8'hf0,8'hd0,8'hac,8'hfe},
	{8'hac,8'hf9,8'hf4,8'hf4,8'hf4,8'hf5,8'hd1,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hd1,8'hf0,8'hd0,8'hd0,8'hac,8'hac,8'hff},
	{8'hac,8'hf5,8'hf0,8'hf0,8'hf0,8'hd0,8'hd0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hcc,8'hd0,8'hcc,8'hd0,8'hac,8'hac,8'hff},
	{8'hac,8'hf9,8'hf4,8'hf4,8'hf5,8'hf5,8'hf0,8'hd1,8'hfa,8'hfa,8'hfe,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hfe,8'hfe,8'hfe,8'hfa,8'hb1,8'had,8'h84,8'hcc,8'hd0,8'hd0,8'hf0,8'hd0,8'hac,8'hFF},
	{8'hd1,8'hf9,8'hf4,8'hf4,8'hf4,8'hf5,8'hf5,8'hf5,8'hf1,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hd0,8'hf0,8'hf1,8'hf1,8'hd0,8'hf0,8'hf0,8'hf0,8'hf0,8'hcc,8'hac,8'hFF},
	{8'hd5,8'hf9,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hd0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hd0,8'hf0,8'hf0,8'hf0,8'hf0,8'hcc,8'hac,8'hac,8'hFF},
	{8'hd5,8'hf5,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf4,8'hf5,8'hf5,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hd0,8'hcc,8'hd0,8'hcc,8'hac,8'h84,8'hFF},
	{8'hfe,8'hf9,8'hf5,8'hf4,8'hf5,8'hf5,8'hf0,8'hf5,8'hf5,8'hf5,8'hf4,8'hf0,8'hf0,8'hf0,8'hf0,8'hd0,8'hd0,8'hd0,8'hd0,8'hcc,8'hcc,8'hcc,8'hd0,8'hd0,8'hd0,8'hf0,8'hf0,8'hd0,8'hd0,8'hcc,8'hac,8'hFF},
	{8'hfa,8'hf9,8'hf0,8'hd0,8'hf0,8'hd0,8'hf0,8'hf0,8'hf0,8'hf5,8'hd0,8'hcc,8'hcc,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hcc,8'hd0,8'hd0,8'hd0,8'hd0,8'hcc,8'hd0,8'hcc,8'hac,8'hac,8'hac,8'hac,8'hFF},
	{8'hff,8'h84,8'hac,8'hcc,8'hcc,8'hd0,8'hcc,8'hcc,8'hcc,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'hac,8'h8c,8'h84,8'h84,8'h84,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'hff,8'hfe,8'hfe,8'hfe,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
},

{//GLASS
	{8'hff,8'hbf,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hdf,8'hff},
	{8'hbe,8'h04,8'h76,8'h71,8'h96,8'h96,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'h9a,8'h9a,8'h9a,8'h9a,8'h9a,8'h9a,8'h96,8'h9a,8'hba,8'hba,8'h96,8'h96,8'h9a,8'h96,8'h96,8'h96,8'h76,8'h71,8'h04,8'hdf},
	{8'hba,8'h76,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hdf,8'hdf,8'hdf,8'hbf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hbe,8'hba,8'hdf,8'hdf,8'hdf,8'hdf,8'h71,8'hda},
	{8'hba,8'h96,8'hff,8'hff,8'hdf,8'hba,8'hba,8'hba,8'hba,8'hba,8'hbb,8'hbb,8'hba,8'hbb,8'hbb,8'hbb,8'hbb,8'hbb,8'hba,8'hbb,8'hbb,8'hbb,8'hbb,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'h71,8'hba},
	{8'hba,8'h96,8'hff,8'hdf,8'hba,8'hba,8'hba,8'hba,8'hba,8'hbb,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbb,8'hbb,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hbb,8'hba,8'hba,8'hba,8'hbb,8'hba,8'hba,8'h71,8'hba},
	{8'h96,8'hba,8'hff,8'hba,8'hba,8'hbf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hbf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdb,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hba,8'hba,8'hdb,8'hdf,8'hba,8'hba,8'h71,8'hba},
	{8'h96,8'hbf,8'hff,8'hba,8'hbf,8'hbf,8'hba,8'h96,8'h96,8'h76,8'h96,8'h71,8'h71,8'h91,8'h92,8'h96,8'h96,8'h96,8'h96,8'h96,8'h92,8'h91,8'h91,8'h71,8'h96,8'hdf,8'hba,8'hdf,8'hba,8'hba,8'h76,8'hba},
	{8'h96,8'hdf,8'hff,8'hba,8'hbf,8'hbf,8'h76,8'h96,8'hba,8'hb6,8'hba,8'hba,8'hda,8'hda,8'hda,8'hdf,8'hdf,8'hdf,8'hff,8'hff,8'hdf,8'hda,8'hda,8'hba,8'h96,8'hdf,8'hba,8'hba,8'hba,8'hba,8'h76,8'hba},
	{8'h96,8'hdf,8'hff,8'hba,8'hbf,8'hba,8'h76,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'hba,8'hdb,8'hba,8'hbf,8'hba,8'h76,8'hb6},
	{8'h96,8'hdf,8'hdf,8'hba,8'hbb,8'hba,8'h96,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'hba,8'hdf,8'hb6,8'hba,8'hba,8'h76,8'hba},
	{8'h76,8'hdf,8'hdf,8'hbb,8'hbb,8'hba,8'h92,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hba,8'h76,8'hba},
	{8'h76,8'hdf,8'hdf,8'hbb,8'hbf,8'hba,8'h96,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h96,8'hdf,8'hba,8'hba,8'hba,8'h76,8'hba},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hba,8'h76,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hba,8'h76,8'hba},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hba,8'h75,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hba,8'h96,8'hba},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hba,8'h75,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hba,8'h96,8'hba},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hba,8'h75,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hff,8'hba,8'hba,8'hba,8'h76,8'hba},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hba,8'h75,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hba,8'h96,8'hff,8'hba,8'hba,8'hba,8'h76,8'hba},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hba,8'h75,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hba,8'h96,8'hff,8'hba,8'hba,8'hba,8'h96,8'hba},
	{8'h96,8'hff,8'hdb,8'hba,8'hdf,8'hba,8'h76,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hba,8'h96,8'hff,8'hb6,8'hba,8'hba,8'h76,8'hb6},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hba,8'h76,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hbf,8'h71,8'hba},
	{8'h76,8'hff,8'hdf,8'hba,8'hdf,8'hbe,8'h76,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hba,8'h71,8'hba},
	{8'h76,8'hdf,8'hdf,8'hdb,8'hbf,8'hbf,8'h75,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hbf,8'h71,8'hba},
	{8'h76,8'hdf,8'hdf,8'hdb,8'hbb,8'hdf,8'h75,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h96,8'hdf,8'hba,8'hba,8'hdf,8'h71,8'hba},
	{8'h76,8'hdf,8'hdf,8'hdf,8'hbf,8'hdf,8'h71,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hba,8'hdf,8'hba,8'hba,8'hdf,8'h2d,8'hba},
	{8'h96,8'hdf,8'hdf,8'hba,8'hbf,8'hdf,8'h9a,8'h96,8'h96,8'h96,8'h96,8'hb6,8'h96,8'h96,8'h96,8'h96,8'h96,8'h96,8'h76,8'h9a,8'hba,8'h96,8'h71,8'h2d,8'h96,8'hdf,8'hba,8'hba,8'hdf,8'hdf,8'h31,8'hbf},
	{8'h96,8'hbb,8'hdf,8'hba,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hba,8'hb6,8'hba,8'h96,8'h96,8'h96,8'h96,8'h96,8'h96,8'hba,8'hba,8'hba,8'hba,8'hdf,8'hff,8'hdf,8'hdf,8'hba,8'hba,8'hdf,8'hdf,8'h71,8'hdb},
	{8'h96,8'hba,8'hdf,8'hba,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hff,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdf,8'hdb,8'hdf,8'hdf,8'hdb,8'hba,8'hba,8'hba,8'hba,8'hba,8'hdf,8'hdf,8'hbf,8'h71,8'hdf},
	{8'h96,8'h9a,8'hdf,8'hba,8'hdf,8'hdf,8'hdb,8'hdf,8'hdb,8'hdb,8'hdf,8'hdb,8'hbb,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hbb,8'hba,8'hba,8'hba,8'h96,8'hbf,8'hdf,8'hdf,8'hff,8'hba,8'hba,8'h71,8'hdf},
	{8'h9a,8'h96,8'hdf,8'hba,8'hba,8'hba,8'hba,8'hdf,8'hba,8'hbb,8'hdf,8'hbf,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hba,8'hbf,8'hbf,8'hdf,8'hdf,8'hdf,8'hba,8'hba,8'hba,8'h71,8'hff},
	{8'h9a,8'h71,8'hdf,8'hba,8'hbf,8'hbf,8'hbf,8'hbf,8'hbe,8'hbf,8'hbf,8'h9a,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hbe,8'hbe,8'hba,8'hba,8'hba,8'h96,8'h96,8'h71,8'h71,8'hff},
	{8'hdf,8'h31,8'h76,8'h2d,8'h31,8'h31,8'h31,8'h71,8'h76,8'h72,8'h71,8'h71,8'h76,8'h76,8'h71,8'h71,8'h71,8'h71,8'h31,8'h71,8'h31,8'h31,8'h31,8'h31,8'h2d,8'h2d,8'h71,8'h96,8'h96,8'h96,8'hda,8'hff},
	{8'hff,8'hff,8'hdf,8'hdf,8'hbf,8'hba,8'hba,8'hba,8'hba,8'h9a,8'h9a,8'hba,8'h9a,8'h9a,8'h9a,8'h9a,8'h9a,8'hba,8'hba,8'hba,8'hbf,8'hbf,8'hbf,8'hbf,8'hbf,8'hdf,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
},

{//STONE
	{8'hff,8'hff,8'hda,8'hda,8'hda,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hd6,8'hd6,8'hb6,8'hd6,8'hd6,8'hb6,8'hda,8'hda,8'hda,8'hff,8'hff},
	{8'hda,8'h91,8'hb6,8'hb6,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hb6,8'hb6,8'hb1,8'h8d,8'hda},
	{8'hb6,8'hb6,8'hff,8'hff,8'hff,8'hff,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hb6,8'h8d,8'hda},
	{8'hb6,8'hda,8'hfe,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hd6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb5,8'hb6,8'hb6,8'hb6,8'hd6,8'hb6,8'hb1,8'h91,8'h6d,8'hb6},
	{8'hb6,8'hda,8'hda,8'hb6,8'hb6,8'hda,8'hda,8'hda,8'hda,8'hda,8'hd6,8'hb6,8'hd6,8'hd6,8'hd6,8'hd6,8'hd6,8'hd6,8'hd6,8'hda,8'hd6,8'hb6,8'hda,8'hda,8'hda,8'hd6,8'hda,8'hd6,8'hb5,8'h91,8'h91,8'hb6},
	{8'h91,8'hda,8'hda,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hd6,8'hda,8'hda,8'hfe,8'hda,8'hd6,8'hd6,8'hd6,8'hb6,8'h91,8'h6d,8'hb6},
	{8'h91,8'hda,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb5,8'hb6,8'hb5,8'hb1,8'h91,8'h91,8'h91,8'h91,8'hb5,8'hb6,8'hb6,8'hb5,8'hb6,8'hda,8'hd6,8'hd6,8'hb6,8'h91,8'h91,8'h91},
	{8'h91,8'hda,8'hd6,8'hb6,8'hb6,8'hda,8'hb6,8'h91,8'hb6,8'hb6,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hfe,8'hff,8'hff,8'hfa,8'hda,8'hda,8'hda,8'hda,8'h91,8'hb6,8'hd6,8'hd6,8'hb6,8'h91,8'h91,8'h91},
	{8'h91,8'hfe,8'hda,8'hb6,8'hda,8'hda,8'h91,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h91,8'hda,8'hd6,8'hb6,8'h91,8'h8d,8'h91},
	{8'h91,8'hff,8'hda,8'hb6,8'hb6,8'hb6,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'hb5,8'hda,8'hb6,8'hb6,8'h91,8'h8d,8'h91},
	{8'h91,8'hff,8'hda,8'hb6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'hb1,8'hda,8'hd6,8'hb6,8'h91,8'h91,8'h91},
	{8'h91,8'hff,8'hda,8'hb6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'h91,8'hd6,8'hda,8'hb6,8'h91,8'h91,8'h91},
	{8'h91,8'hff,8'hda,8'hb6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hb6,8'hda,8'hb6,8'h91,8'h6d,8'h91},
	{8'h91,8'hff,8'hda,8'hd6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hda,8'hda,8'hb6,8'h91,8'h8d,8'h91},
	{8'h91,8'hff,8'hda,8'hd6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hd6,8'hb6,8'hb6,8'h91,8'h91,8'h91},
	{8'h91,8'hff,8'hda,8'hd6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hb6,8'hb6,8'hb6,8'h91,8'h8d,8'h91},
	{8'h91,8'hff,8'hda,8'hd6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hda,8'hda,8'hd6,8'hb1,8'h6d,8'h91},
	{8'h91,8'hff,8'hda,8'hd6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hda,8'hb6,8'hb6,8'hb1,8'h91,8'h91},
	{8'h91,8'hff,8'hda,8'hd6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hb6,8'hb5,8'hb5,8'hb1,8'h91,8'h91},
	{8'h91,8'hff,8'hda,8'hd6,8'hb6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hb6,8'hb5,8'hb5,8'hb1,8'h91,8'hb1},
	{8'h91,8'hff,8'hda,8'hd6,8'hd6,8'hda,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hb5,8'hb5,8'hb5,8'hb5,8'h91,8'hb6},
	{8'h91,8'hff,8'hda,8'hb6,8'hd6,8'hd6,8'h91,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'hb5,8'hb5,8'hb5,8'hb1,8'h8d,8'hb6},
	{8'h91,8'hff,8'hda,8'hb6,8'hd6,8'hda,8'h91,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'h91,8'hb6,8'hb6,8'hb5,8'h91,8'h8d,8'hb6},
	{8'h91,8'hff,8'hda,8'hb6,8'hda,8'hda,8'h91,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hb6,8'h91,8'hb6,8'hb5,8'hb5,8'h91,8'h8d,8'hb6},
	{8'h91,8'hff,8'hda,8'hd6,8'hd6,8'hb6,8'hb6,8'h91,8'hb6,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hda,8'hb6,8'hb6,8'h91,8'h91,8'h91,8'hb6,8'hb5,8'hb6,8'h91,8'h6d,8'hda},
	{8'h91,8'hff,8'hda,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'h91,8'h91,8'hb1,8'h91,8'h91,8'h91,8'hb1,8'hb1,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'hb1,8'h91,8'hb6,8'hb6,8'hb6,8'hb6,8'h91,8'h6d,8'hda},
	{8'h91,8'hda,8'hda,8'hb6,8'hb6,8'hb6,8'hb6,8'hda,8'hb6,8'hb6,8'hda,8'hda,8'hda,8'hda,8'hda,8'hd6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb5,8'hb6,8'hb6,8'hb6,8'hb6,8'h91,8'h6d,8'hda},
	{8'hb6,8'hda,8'hda,8'hb6,8'hb6,8'hb6,8'hda,8'hda,8'hda,8'hda,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb5,8'hb1,8'hb5,8'hb5,8'hb5,8'hb5,8'hb6,8'hb6,8'hb5,8'hb6,8'hb5,8'h91,8'hb1,8'h91,8'h6d,8'hda},
	{8'hb6,8'hb6,8'hda,8'hb6,8'hb6,8'hda,8'hda,8'hb5,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb5,8'h91,8'h91,8'h91,8'h6d,8'hff},
	{8'hb6,8'h91,8'hb6,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'h91,8'h6d,8'h6d,8'hff},
	{8'hff,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h8d,8'h91,8'h91,8'h8d,8'h91,8'h91,8'h6d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h6d,8'h91,8'hb6,8'hff},
	{8'hff,8'hff,8'hda,8'hda,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb6,8'hb5,8'h91,8'hb5,8'hb6,8'hb5,8'hb5,8'hb5,8'hb1,8'hb6,8'hb6,8'hb6,8'hd6,8'hd6,8'hda,8'hda,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
},
};
 
// assign offsetY_LSB  = offsetY[4:0] ; // get lower 5 bits 
// assign offsetY_MSB  = offsetY[8:5] ; // get higher 4 bits 
// assign offsetX_LSB  = offsetX[4:0] ; 
// assign offsetX_MSB  = offsetX[8:5] ; 

// pipeline (ff) to get the pixel color from the array 	 

//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		renderedLevel = level;
		MazeBitMapMask  <=  MazeDefaultBitMapMask[renderedLevel];  //  Load initial level
	end
	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default 
		
		if(renderedLevel != level) begin  // Level was switched
			renderedLevel = level;
			MazeBitMapMask  <=  MazeDefaultBitMapMask[renderedLevel];
		end
		
		if (bird_wall_collision == 1'b1) begin
			case (MazeBitMapMask[offsetY[8:5]][offsetX[8:5]])  // determine breaking speed of materials
					 4'h1 : hitThreshold = 700;  // hard wood
					 4'h2 : hitThreshold = 450;  // hollow wood
					 4'h3 : hitThreshold = 300;   // glass
					 4'h4 : hitThreshold = 1000; // stone
					 default:  hitThreshold = 2000; //  object will be unbreakable if not identified
			endcase
			if (speedSum > hitThreshold)
				MazeBitMapMask[offsetY[8:5]][offsetX[8:5]] <= 4'h0;
		end
		
		if (InsideRectangle == 1'b1 )	begin 
		   	case (MazeBitMapMask[offsetY[8:5]][offsetX[8:5]])
					 4'h0 : RGBout <= TRANSPARENT_ENCODING ;
					 4'h1 : RGBout <= object_colors[4'h0][offsetY[4:0]][offsetX[4:0]]; 
					 4'h2 : RGBout <= object_colors[4'h1][offsetY[4:0]][offsetX[4:0]];
					 4'h3 : RGBout <= object_colors[4'h2][offsetY[4:0]][offsetX[4:0]]; 
					 4'h4 : RGBout <= object_colors[4'h3][offsetY[4:0]][offsetX[4:0]]; 
					 default:  RGBout <= TRANSPARENT_ENCODING ; 
				endcase
		end 
	end 
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING && resetN ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
endmodule




