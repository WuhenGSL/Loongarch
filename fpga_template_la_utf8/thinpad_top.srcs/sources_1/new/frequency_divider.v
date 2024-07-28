module frequency_divider(
    input wire clk_in,       
    input wire reset,    
    input wire locked,        
    output reg clk_out1   
);

    parameter DIVISOR = 326; 

    reg [8:0] counter; 

    initial begin
        counter = 9'b0;
        clk_out1 = 1'b0;
    end

    // ??????
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 9'b0;
            clk_out1 <= 1'b0;
        end else if (locked) begin
            if (counter == DIVISOR - 1) begin
                counter <= 9'b0;
                clk_out1 <= ~clk_out1; 
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule
