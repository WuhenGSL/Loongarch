`include "mycpu.vh"
module EX_stage(
    input         clk,
    input         reset,
    input  MEM_allow_in,
    input  ID_to_EX_valid,
    output EX_allow_in,
    input  [`ID_EX_BUS - 1:0] ID_EX_bus,
    input   inst_bl,
    output [`EX_MEM_BUS - 1:0] EX_MEM_bus,
    output  EX_to_MEM_valid,
    output        data_sram_en,
    output [ 3:0] data_sram_we,
    output [ 3:0] sram_be,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    output [ 4:0] EX_dest_reg,
    output EX_load,
    output EX_store,
    output [31:0] EX_to_ID_result
);

reg  [31:0] EX_pc;
reg EX_valid;
wire EX_ready_go;
reg  [11:0] EX_alu_op;
reg         EX_src1_is_pc;
reg         EX_src2_is_imm;
reg         EX_src2_is_4;
reg         EX_res_from_mem;
reg         EX_res_8_bits;
reg         EX_gr_we;
reg         EX_mem_we;
reg  [4: 0] EX_dest;
reg  [31:0] EX_rj_value;
reg  [31:0] EX_rkd_value;
reg  [31:0] EX_imm;
wire [31:0] alu_result;
reg EX_inst_bl;
wire [31:0] alu_src1;
wire [31:0] alu_src2;

assign EX_ready_go    = 1'b1;
assign EX_allow_in     = !EX_valid || EX_ready_go && MEM_allow_in;
assign EX_to_MEM_valid = EX_valid && EX_ready_go;
assign EX_MEM_bus = {
    EX_pc,        // 70:39
    EX_gr_we,     // 38
    EX_dest,      // 37:33
    alu_result,   // 32:1
    EX_res_from_mem,
    EX_res_8_bits // 0
};
assign EX_dest_reg = EX_dest & {5{EX_valid}};

always @(posedge clk) begin
    if (reset) begin
        EX_valid <= 1'b0;
    end else if (EX_allow_in) begin
        EX_valid <= ID_to_EX_valid;
    end

    if (ID_to_EX_valid && EX_allow_in) begin
        {EX_pc,
        EX_alu_op,
        EX_src2_is_4,
        EX_src1_is_pc,
        EX_src2_is_imm,
        EX_gr_we,
        EX_mem_we,
        EX_dest,
        EX_imm,
        EX_rj_value,
        EX_rkd_value,
        EX_res_from_mem,
        EX_res_8_bits} <= ID_EX_bus;
        EX_inst_bl <= inst_bl;
    end
end

assign EX_load = EX_res_from_mem;


alu u_alu(
    .alu_op     (EX_alu_op),
    .alu_src1   (alu_src1),
    .alu_src2   (alu_src2),
    .alu_result (alu_result)
);

assign alu_src1 = EX_src1_is_pc ? EX_pc : EX_rj_value;
assign alu_src2 = EX_src2_is_imm ? EX_imm : (EX_inst_bl ? 32'd4 : EX_rkd_value);

reg [3:0] be_code;
wire [1:0] alu_low_bits = alu_result[1:0];
always @(*) begin
    case(alu_low_bits)
        2'd0: be_code <= 4'b1111;
        2'd1: be_code <= 4'b1110;
        2'd2: be_code <= 4'b1100;
        2'd3: be_code <= 4'b1000;
       endcase
end

assign sram_be = be_code;

/*assign EX_store = (alu_result == 32'hbfd003fc || alu_result == 32'hbfd003f8)
                                ? 1'b0 : EX_mem_we | EX_res_from_mem;*/
assign EX_store = EX_mem_we | EX_res_from_mem;

assign data_sram_en = EX_res_from_mem | EX_mem_we;
assign data_sram_we = EX_mem_we && EX_valid ? 4'b1111 : 4'b0000;
assign data_sram_addr = alu_result;
assign data_sram_wdata = EX_res_8_bits ? EX_rkd_value[7:0] :EX_rkd_value;

assign EX_to_ID_result = alu_result;

endmodule
