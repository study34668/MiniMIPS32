`include "defines.v"

module hilo(
    input  wire 				 cpu_clk_50M,
	input  wire 				 cpu_rst_n,
	
	// 写使能端
	input  wire 				 we,
	
	// 写端口
	input  wire  [`REG_BUS]  hi_i,
	input  wire  [`REG_BUS]  lo_i,
	
	// 读端口 
	output  reg  [`REG_BUS]  hi_o,
	output  reg  [`REG_BUS]  lo_o
    );
    
    reg [`REG_BUS] hi, lo;
    
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            hi <= `ZERO_WORD;
            lo <= `ZERO_WORD;
        end
        else begin
            if (we == `WRITE_ENABLE) begin 
                hi <= hi_i;
                lo <= lo_i;
            end
        end
    end
    
    always @(*) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            hi_o <= `ZERO_WORD;
            lo_o <= `ZERO_WORD;
        end
        else begin
            hi_o <= hi;
            lo_o <= lo;
        end
    end
    
endmodule
