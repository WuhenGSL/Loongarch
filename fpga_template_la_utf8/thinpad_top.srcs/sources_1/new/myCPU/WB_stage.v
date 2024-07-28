`include "mycpu.vh"
module WB_stage(
  input  clk,
  input  reset,
  output WB_allow_in,
  input  MEM_to_WB_valid,
  input  [`MEM_WB_BUS - 1:0] MEM_WB_bus,
  output [`WB_RF_BUS - 1:0] WB_rf_bus,
  output [31:0] debug_wb_pc,
  output [ 3:0] debug_wb_rf_we,
  output [ 4:0] debug_wb_rf_wnum,
  output [31:0] debug_wb_rf_wdata,
  output [ 4:0] WB_dest_reg,
  output [31:0]WB_to_ID_result
  );
reg [31:0] WB_pc;
reg WB_valid;
wire WB_ready_go;
 
reg WB_gr_we;
reg WB_res_8_bits;
reg [4:0]WB_dest;
reg [31:0]WB_final_result;
wire rf_we   ;
wire [4:0]rf_waddr;
wire [31:0]rf_wdata;
assign WB_ready_go = 1'b1;
assign WB_allow_in  = !WB_valid || WB_ready_go;
assign WB_dest_reg = WB_dest & {5{WB_valid}};
always @(posedge clk) begin
    if (reset) begin
        WB_valid <= 1'b0;
    end
    else if (WB_allow_in) begin
        WB_valid <= MEM_to_WB_valid;
    end
 
    if (MEM_to_WB_valid && WB_allow_in) begin
      {WB_pc,
       WB_gr_we,
       WB_dest,
       WB_final_result} <= MEM_WB_bus;
       
    end
end
 
assign rf_we    = WB_gr_we && WB_valid;
assign rf_waddr = WB_dest;
assign rf_wdata = WB_final_result;
 
assign WB_rf_bus = {rf_we,//37
                    rf_waddr,//36:32
                    rf_wdata//31:0
                    };
 
assign debug_wb_pc       = rf_we ? WB_pc : debug_wb_pc;
assign debug_wb_rf_we   = {4{rf_we}};
assign debug_wb_rf_wnum  = WB_valid && rf_we ? WB_dest : debug_wb_rf_wnum;
assign debug_wb_rf_wdata = WB_valid && rf_we ? WB_final_result : debug_wb_rf_wdata;
 
assign WB_to_ID_result = WB_final_result;
endmodule