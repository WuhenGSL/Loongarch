`include "mycpu.vh"
module MEM_stage(
    input  clk,
    input  reset,
    input  WB_allow_in,
    output MEM_allow_in,
    input  [`EX_MEM_BUS - 1:0]EX_MEM_bus,
    input  [31:0] data_sram_rdata,
    input  EX_to_MEM_valid, 
    output MEM_to_WB_valid,
    output [`MEM_WB_BUS - 1:0]MEM_WB_bus,
    output [ 4:0]MEM_dest_reg,
    output [31:0]MEM_to_ID_result
    );
 
reg [31:0] MEM_pc;
reg MEM_res_from_mem;
reg MEM_gr_we;
reg MEM_res_8_bits;
reg [4:0]MEM_dest;
reg [31:0]MEM_alu_result;
wire [31:0] MEM_final_result;
wire [31:0] MEM_result;
wire [31:0] MEM_data;
 
reg MEM_valid;
wire MEM_ready_go;
assign MEM_ready_go    = 1'b1;
assign MEM_allow_in     = !MEM_valid || MEM_ready_go && WB_allow_in;
assign MEM_to_WB_valid = MEM_valid && MEM_ready_go;
assign MEM_dest_reg = MEM_dest & {5{MEM_valid}};
always @(posedge clk) begin
    if (reset) begin
        MEM_valid <= 1'b0;
    end
    else if (MEM_allow_in) begin
        MEM_valid <= EX_to_MEM_valid;
    end
 
    if (EX_to_MEM_valid && MEM_allow_in) begin
        {MEM_pc ,
        MEM_gr_we ,
        MEM_dest,
        MEM_alu_result,
        MEM_res_from_mem,
        MEM_res_8_bits } <= EX_MEM_bus;
    end
end

reg [4:0] offs;
wire [1:0] alu_low_bits = MEM_alu_result[1:0];
always @(*) begin
    case(alu_low_bits)
        2'd0: offs <= 5'd0;
        2'd1: offs <= 5'd8;
        2'd2: offs <= 5'd16;
        2'd3: offs <= 5'd24;
       endcase
end
assign MEM_data = data_sram_rdata >> offs;

assign MEM_result = MEM_res_8_bits ? {{24{MEM_data[7]}}, MEM_data[7:0]} : data_sram_rdata;
assign MEM_final_result = MEM_res_from_mem ? MEM_result : MEM_alu_result;
assign MEM_WB_bus = {
                        MEM_pc,//69:38
                        MEM_gr_we,//37
                        MEM_dest,// 36:32
                        MEM_final_result//31:0
};

assign MEM_to_ID_result = MEM_final_result;
endmodule