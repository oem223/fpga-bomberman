module sound_mux (
  input  logic clk,
  input  logic resetN,

  // events (levels or 1-cycle pulses; we detect rising edge)
  input  logic won,
  input  logic lost,
  input  logic bomb,
  input  logic key,
  input  logic door,
  input  logic timeExtra,
  input  logic bomb2,
  

  // to melody player
  output logic       startMelodyKey,   // 1-cycle start strobe
  output logic [3:0] melody_select     // melody id
);

  // melody IDs 
  localparam logic [3:0] MELODY_BOMB = 4'd12;
  localparam logic [3:0] MELODY_WON  = 4'd13;
  localparam logic [3:0] MELODY_LOST = 4'd3;
  localparam logic [3:0] MELODY_KEY  = 4'd12;
  localparam logic [3:0] MELODY_DOOR = 4'd12;
  localparam logic [3:0] MELODY_TIME = 4'd12;

  logic won_d, lost_d, bomb_d, key_d, door_d, time_d,bomb2_d ;

  logic won_edge, lost_edge, bomb_edge, key_edge, door_edge, time_edge, bomb2_edge;

  always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
      startMelodyKey <= 1'b0;
      melody_select  <= '0;

      won_d  <= 1'b0;
      lost_d <= 1'b0;
      bomb_d <= 1'b0;
		bomb2_d <= 1'b0;
      key_d  <= 1'b0;
      door_d <= 1'b0;
      time_d <= 1'b0;

      won_edge  <= 1'b0;
      lost_edge <= 1'b0;
      bomb_edge <= 1'b0;
		bomb2_edge <= 1'b0;
      key_edge  <= 1'b0;
      door_edge <= 1'b0;
      time_edge <= 1'b0;
    end else begin
      // rising edges 
      won_edge  <=  won       & ~won_d;
      lost_edge <=  lost      & ~lost_d;
      bomb_edge <=  bomb      & ~bomb_d;
		bomb2_edge <=  bomb2      & ~bomb2_d;
      key_edge  <=  key       & ~key_d;
      door_edge <=  door      & ~door_d;
      time_edge <=  timeExtra & ~time_d;

      // update previous samples
      won_d  <= won;
      lost_d <= lost;
      bomb_d <= bomb;
		bomb2_d <= bomb2;
      key_d  <= key;
      door_d <= door;
      time_d <= timeExtra;

      // default: no start this cycle
      startMelodyKey <= 1'b0;

      // priority 
      if (bomb_edge) begin
        melody_select  <= MELODY_BOMB;
		  startMelodyKey <= 1'b1;
		 end else if (bomb2_edge) begin
        melody_select  <= MELODY_BOMB;
        startMelodyKey <= 1'b1;
      end else if (won_edge) begin
        melody_select  <= MELODY_WON;
        startMelodyKey <= 1'b1;
      end else if (lost_edge) begin
        melody_select  <= MELODY_LOST;
        startMelodyKey <= 1'b1;
      end else if (key_edge) begin
        melody_select  <= MELODY_KEY;
        startMelodyKey <= 1'b1;
      end else if (door_edge) begin
        melody_select  <= MELODY_DOOR;
        startMelodyKey <= 1'b1;
      end else if (time_edge) begin
        melody_select  <= MELODY_TIME;
        startMelodyKey <= 1'b1;
      end
    end
  end

endmodule
