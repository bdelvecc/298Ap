module pc (
  input reg pc_load,
  input reg [5:0] jump_loc,
  output reg [5:0] PC
);
  always @(*) begin
    if(pc_load) begin
      PC = jump_loc;
    end
    else begin
      PC += 1;
    end
  end
  
