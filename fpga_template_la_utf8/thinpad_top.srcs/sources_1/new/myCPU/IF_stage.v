`include "mycpu.vh"
module IF_stage(
    input  clk,
    input  reset,
    input  ID_allow_in,
    input  [`BR_BUS - 1:0] br_bus,
    output        inst_sram_en,
    output [ 3:0] inst_sram_we,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    output [`IF_ID_BUS - 1:0] IF_ID_bus,
    output IF_to_ID_valid,
    input EX_store,
    input EX_load,
    input ID_block
);

wire br_stall;
wire br_taken;
wire [31:0] br_target;
assign {br_stall, br_taken, br_target} = br_bus;

wire [31:0] IF_inst;
wire [31:0] IF_inst_buffer;
reg  [31:0] IF_pc;
wire [31:0] seq_pc;
wire [31:0] nextpc;
wire pre_IF_ready_go;
wire IF_ready_go;
wire IF_allow_in;
wire to_IF_valid;
reg  IF_valid;

wire EX_store_d;
wire br_load_store;
wire ld_use_br;

assign EX_store_d = (IF_pc <= 32'h80000004) ? 1'b0 : EX_store;
assign ld_use_br = (IF_pc <= 32'h80000004) ? 1'b0 : EX_load & ID_block;
assign br_load_store = (br_taken & EX_store_d) == 1'b1;
assign IF_ID_bus = {IF_pc, IF_inst};
assign pre_IF_ready_go = ~EX_store_d; 
assign to_IF_valid = ~reset && pre_IF_ready_go;
assign seq_pc       = IF_pc + 3'h4;
assign nextpc       = br_taken ? br_target : seq_pc;

assign IF_ready_go = ~br_taken;
assign IF_allow_in = !IF_valid || (IF_ready_go && ID_allow_in);
assign IF_to_ID_valid = IF_valid && IF_ready_go;

always @(posedge clk) begin
    if (reset) begin
        IF_valid <= 1'b0;
    end else if (IF_allow_in) begin
        IF_valid <= to_IF_valid;
    end
end

always @(posedge clk) begin 
    if (reset) begin
        IF_pc <= 32'h7ffffffc;
    end else if (to_IF_valid && (IF_allow_in || br_taken)) begin
        IF_pc <= nextpc;        
    end
    else if (br_load_store) begin
        IF_pc <= nextpc - 3'h4;
    end
end

assign inst_sram_en = (EX_load && ID_block) || (to_IF_valid && (IF_allow_in || br_taken));
assign inst_sram_addr = ld_use_br ? nextpc - 3'h4 : nextpc;
assign IF_inst = inst_sram_rdata;
assign inst_sram_we = 4'b0;
assign inst_sram_wdata = 32'b0;

endmodule