`include "mycpu.vh"
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    
    output wire [ 3:0] sram_be
);
reg         reset;
always @(posedge clk) reset <= ~resetn;
 
 
 
// allow_in
wire ID_allow_in;
wire EX_allow_in;
wire MEM_allow_in;
wire WB_allow_in;
//bus
wire [`IF_ID_BUS - 1:0]IF_ID_bus;
wire [`ID_EX_BUS - 1:0]ID_EX_bus;
wire [`EX_MEM_BUS - 1:0]EX_MEM_bus;
wire [`MEM_WB_BUS - 1:0]MEM_WB_bus;
wire [`BR_BUS - 1:0]br_bus;
wire [`WB_RF_BUS - 1:0]WB_rf_bus;
//valid
wire IF_to_ID_valid;
wire ID_to_EX_valid;
wire EX_to_MEM_valid;
wire MEM_to_WB_valid;
//inst_bl
wire inst_bl;
 
//block
wire EX_load;
wire EX_store;
wire ID_block;
wire [4:0]EX_dest;
wire [4:0]MEM_dest;
wire [4:0]WB_dest;


wire [31:0]EX_to_ID_result;
wire [31:0]MEM_to_ID_result;
wire [31:0]WB_to_ID_result;

IF_stage IF(
    .clk(clk),
    .reset(reset),
    .ID_allow_in(ID_allow_in),
    .br_bus(br_bus),
    .inst_sram_en(inst_sram_en),
    .inst_sram_we(inst_sram_we),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata),
    .IF_ID_bus(IF_ID_bus),
    .IF_to_ID_valid(IF_to_ID_valid),
    .EX_store(EX_store),
    .EX_load(EX_load),
    .ID_block(ID_block)
    );
ID_stage ID(
   .clk(clk),
   .reset(reset),
   .EX_allow_in(EX_allow_in),
   .IF_to_ID_valid(IF_to_ID_valid),
   .IF_ID_bus(IF_ID_bus),
   .WB_rf_bus(WB_rf_bus),
   .ID_allow_in(ID_allow_in),
   .br_bus(br_bus),
   .ID_EX_bus(ID_EX_bus),
   .ID_to_EX_valid(ID_to_EX_valid),
   .to_EX_inst_bl(inst_bl),
   .EX_dest(EX_dest),
   .WB_dest(WB_dest),
   .MEM_dest(MEM_dest),
   .EX_store(EX_store),
   .EX_load(EX_load),
   .EX_to_ID_result (EX_to_ID_result),
   .MEM_to_ID_result (MEM_to_ID_result),
   .WB_to_ID_result (WB_to_ID_result),
   .ID_block(ID_block)
    );
EX_stage EX(
    .clk(clk),
    .reset(reset),
    .MEM_allow_in(MEM_allow_in),
    .ID_to_EX_valid(ID_to_EX_valid),
    .EX_allow_in(EX_allow_in),
    .ID_EX_bus(ID_EX_bus),
    .inst_bl(inst_bl),
    .EX_MEM_bus(EX_MEM_bus),
    .EX_to_MEM_valid(EX_to_MEM_valid),
    .data_sram_en(data_sram_en),
    .data_sram_we(data_sram_we),
    .sram_be(sram_be),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .EX_dest_reg(EX_dest),
    .EX_load(EX_load),
    .EX_store(EX_store),
    .EX_to_ID_result(EX_to_ID_result)
);
MEM_stage MEM(
    .clk(clk),
    .reset(reset),
    .WB_allow_in(WB_allow_in),
    .MEM_allow_in(MEM_allow_in),
    .EX_MEM_bus(EX_MEM_bus),
    .data_sram_rdata(data_sram_rdata),
    .EX_to_MEM_valid(EX_to_MEM_valid),    
    .MEM_to_WB_valid(MEM_to_WB_valid),
    .MEM_WB_bus(MEM_WB_bus),
    .MEM_dest_reg(MEM_dest),
    .MEM_to_ID_result(MEM_to_ID_result)
    );
WB_stage WB(
    .clk(clk),
    .reset(reset),
    .WB_allow_in(WB_allow_in),
    .MEM_to_WB_valid(MEM_to_WB_valid),
    .MEM_WB_bus(MEM_WB_bus),
    .WB_rf_bus(WB_rf_bus),
    .debug_wb_pc(debug_wb_pc) ,
    .debug_wb_rf_we(debug_wb_rf_we),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    .WB_dest_reg(WB_dest),
    .WB_to_ID_result(WB_to_ID_result)
    );
endmodule