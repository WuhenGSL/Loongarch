`default_nettype none


module thinpad_top(
    input wire clk_50M,           //50MHz ???????
    input wire clk_11M0592,       //11.0592MHz ??????????ã?????ã?

    input wire clock_btn,         //BTN5?????????????????????·????????1
    input wire reset_btn,         //BTN6??????????????????????·????????1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4????????????????1
    input  wire[31:0] dip_sw,     //32??????????????ON????1
    output wire[15:0] leds,       //16?LED??????1????
    output wire[7:0]  dpy0,       //???????????????????????1????
    output wire[7:0]  dpy1,       //???????????????????????1????

    //BaseRAM???
    inout wire[31:0] base_ram_data,  //BaseRAM???????8???CPLD?????????????
    output wire[19:0] base_ram_addr, //BaseRAM???
    output wire[3:0] base_ram_be_n,  //BaseRAM??????????????????????????????????0
    output wire base_ram_ce_n,       //BaseRAM?????????
    output wire base_ram_oe_n,       //BaseRAM???????????
    output wire base_ram_we_n,       //BaseRAM??????????

    //ExtRAM???
    inout wire[31:0] ext_ram_data,  //ExtRAM????
    output wire[19:0] ext_ram_addr, //ExtRAM???
    output wire[3:0] ext_ram_be_n,  //ExtRAM??????????????????????????????????0
    output wire ext_ram_ce_n,       //ExtRAM?????????
    output wire ext_ram_oe_n,       //ExtRAM???????????
    output wire ext_ram_we_n,       //ExtRAM??????????

    //??????????
    output wire txd,  //???????????
    input  wire rxd,  //???????????

    //Flash??????????? JS28F640 ?????
    output wire [22:0]flash_a,      //Flash?????a0????8bit???????16bit????????
    inout  wire [15:0]flash_d,      //Flash????
    output wire flash_rp_n,         //Flash????????????
    output wire flash_vpen,         //Flash??????????????????????????
    output wire flash_ce_n,         //Flash???????????
    output wire flash_oe_n,         //Flash??????????????
    output wire flash_we_n,         //Flash?????????????
    output wire flash_byte_n,       //Flash 8bit????????????????flash??16?????????1

    //?????????
    output wire[2:0] video_red,    //????????3?
    output wire[2:0] video_green,  //????????3?
    output wire[1:0] video_blue,   //????????2?
    output wire video_hsync,       //?????????????????
    output wire video_vsync,       //??????????????????
    output wire video_clk,         //??????????
    output wire video_de           //???????????????????????????
);

/* =========== Demo code begin =========== */

// PLL??????
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // ?????????
  // Clock out ports
  .clk_out1(clk_10M), // ??????1???????IP???ý????????? // ????50
  .clk_out2(clk_20M), // ??????2???????IP???ý?????????
  // Status and control signals
  .reset(reset_btn), // PLL???????
  .locked(locked)    // PLL???????????"1"???????????
                     // ???·?????????????????????£?
 );

reg reset_of_clk10M;
// ????????????????locked????????·????reset_of_clk10M
always@(posedge clk_20M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end


//cpu inst sram
wire        cpu_inst_en;
wire [3 :0] cpu_inst_wen;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
//cpu data sram
wire        cpu_data_en;
wire [3 :0] cpu_data_wen;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;


// cpu ?????rst?????????
// cpu ????û??????
mycpu_top u_mycpu(              
    .clk              (clk_20M),
    .resetn           (~reset_of_clk10M),

    .inst_sram_en     (cpu_inst_en   ),//1
    .inst_sram_we     (cpu_inst_wen  ),//0000
    .inst_sram_addr   (cpu_inst_addr ),
    .inst_sram_wdata  (cpu_inst_wdata),
    .inst_sram_rdata  (cpu_inst_rdata),

    .data_sram_en     (cpu_data_en   ),//1
    .data_sram_we     (cpu_data_wen  ),//sel
    .data_sram_addr   (cpu_data_addr ),
    .data_sram_wdata  (cpu_data_wdata),
    .data_sram_rdata  (cpu_data_rdata),
    .debug_wb_pc(),
    .debug_wb_rf_we(),
    .debug_wb_rf_wnum(),
    .debug_wb_rf_wdata()
);
// cpu ????û??????



reg [31:0] cpu_inst_rdata_r;
reg [31:0] cpu_data_rdata_r;

reg [31:0] base_ram_data_r;
reg [19:0] base_ram_addr_r;
reg [3:0] base_ram_be_n_r;
reg base_ram_ce_n_r;
reg base_ram_oe_n_r;
reg base_ram_we_n_r;

reg [31:0] ext_ram_data_r;
reg [19:0] ext_ram_addr_r;
reg [3:0] ext_ram_be_n_r;
reg ext_ram_ce_n_r;
reg ext_ram_oe_n_r;
reg ext_ram_we_n_r;

reg sel_inst; // 1-inst 0-data for base_ram
reg sel_uart;
reg sel_uart_flag; // 1-flag 0-data

wire [31:0] uart_rdata;
reg [31:0] uart_wdata;

wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready; 
wire ext_uart_clear;
wire ext_uart_busy;
reg ext_uart_start;
reg ext_uart_avai;

reg cpu_data_avai;

reg uart_read_flag;
reg uart_write_flag;

reg [19:0] base_ram_addr_r_d;
reg [31:0] base_ram_data_r_d;


assign base_ram_data = ~base_ram_we_n_r ? base_ram_data_r : 32'bz;
assign ext_ram_data = ~ext_ram_we_n_r ? ext_ram_data_r : 32'bz;

assign base_ram_addr = base_ram_addr_r;
assign base_ram_be_n = base_ram_be_n_r;
assign base_ram_ce_n = base_ram_ce_n_r;
assign base_ram_oe_n = base_ram_oe_n_r;
assign base_ram_we_n = base_ram_we_n_r;

assign ext_ram_addr = ext_ram_addr_r;
assign ext_ram_be_n = ext_ram_be_n_r;
assign ext_ram_ce_n = ext_ram_ce_n_r;
assign ext_ram_oe_n = ext_ram_oe_n_r;
assign ext_ram_we_n = ext_ram_we_n_r;



// in 
always @ (*) begin
    if (reset_of_clk10M) begin
        cpu_inst_rdata_r <= 32'b0;
        cpu_data_rdata_r <= 32'b0;
    end
    else begin
        cpu_inst_rdata_r <= ~sel_inst ? 32'b0 
                            : ~base_ram_oe_n_r ? base_ram_data 
                            : 32'b0;
        cpu_data_rdata_r <= sel_uart ? uart_rdata : sel_inst ? (~ext_ram_oe_n_r ? ext_ram_data : 32'b0) : (~base_ram_oe_n_r ? base_ram_data : 32'b0);
    end
end
assign cpu_inst_rdata = cpu_inst_rdata_r;
assign cpu_data_rdata = cpu_data_rdata_r;
assign uart_rdata = sel_uart_flag ? {30'b0,ext_uart_avai,~ext_uart_busy} : {24'b0,ext_uart_buffer};

reg [3:0] state;
 
// out 
always @ (posedge clk_20M) begin
    if (reset_of_clk10M) begin
        base_ram_addr_r <= 19'b0;
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= 1'b1;
        base_ram_oe_n_r <= 1'b1;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= 32'b0;

        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b0;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'b0;
    end
    else if (cpu_data_addr >=32'h80000000 && cpu_data_addr <= 32'h803fffff && cpu_data_en) begin
        base_ram_addr_r <= cpu_data_addr[21:2];
        base_ram_be_n_r <= 4'b0;//(|cpu_data_wen) ? ~cpu_data_wen : 4'b0;
        base_ram_ce_n_r <= ~cpu_data_en;
        base_ram_oe_n_r <= ~(cpu_data_en & ~(|cpu_data_wen));
        base_ram_we_n_r <= ~(cpu_data_en & (|cpu_data_wen));
        base_ram_data_r <= cpu_data_wdata;

        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;  
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b0;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'b1;
    end
    else if (cpu_data_addr >= 32'h80400000 && cpu_data_addr <= 32'h807fffff && cpu_data_en) begin       
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
        
        ext_ram_addr_r <= cpu_data_addr[21:2];
        ext_ram_be_n_r <= 4'b0;//(|cpu_data_wen) ? ~cpu_data_wen : 4'b0;
        ext_ram_ce_n_r <= ~cpu_data_en;
        ext_ram_oe_n_r <= ~(cpu_data_en & ~(|cpu_data_wen));
        ext_ram_we_n_r <= ~(cpu_data_en & (|cpu_data_wen)); 
        ext_ram_data_r <= cpu_data_wdata;

        sel_inst <= 1'b1;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd2;
    end
    else if (cpu_data_addr == 32'hbfd003fc) begin
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
      
        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b1;
        sel_uart <= 1'b1;
        sel_uart_flag <= 1'b1;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd3;
    end
    else if (cpu_data_addr == 32'hbfd003f8 && cpu_data_en) begin        
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
       
        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b1;
        sel_uart <= 1'b1;
        sel_uart_flag <= 1'b0;
        uart_wdata <= cpu_data_wdata;
        cpu_data_avai <= (|cpu_data_wen) ? 1'b1 : 1'b0;
        state <= 4'd4;
    end
    else begin        
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
      
        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b1;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd5;
    end
end


// uart
async_receiver #(.ClkFrequency(40000000),.Baud(9600)) //???????9600??????
    ext_uart_r(
        .clk(clk_20M),                       //????????
        .RxD(rxd),                           //?????????????
        .RxD_data_ready(ext_uart_ready),  //???????????
        .RxD_clear(ext_uart_clear),       //?????????
        .RxD_data(ext_uart_rx)             //???????????????
    );

assign ext_uart_clear = ext_uart_ready; //????????????????????????????????ext_uart_buffer??
always @(posedge clk_20M) begin //???????????ext_uart_buffer
    if (reset_of_clk10M) begin
        ext_uart_buffer <= 8'b0;
        ext_uart_avai <= 1'b0;
    end
    else if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1'b1;
    end 
    else if(cpu_data_addr == 32'hbfd003f8 && (cpu_data_en & ~(|cpu_data_wen)) && ext_uart_avai)begin 
        ext_uart_avai <= 1'b0;
    end
end

always @(posedge clk_20M) begin //????????ext_uart_buffer??????
    if(!ext_uart_busy && cpu_data_avai)begin 
        ext_uart_tx <= uart_wdata[7:0];
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(40000000),.Baud(9600)) //???????9600??????
    ext_uart_t(
        .clk(clk_20M),                  //????????
        .TxD(txd),                      //??????????
        .TxD_busy(ext_uart_busy),       //??????æ????
        .TxD_start(ext_uart_start),    //??????????
        .TxD_data(ext_uart_tx)        //???????????
    );

endmodule