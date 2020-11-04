`include "defines.v"

module memwb_reg (
    input  wire                     cpu_clk_50M,
	input  wire                     cpu_rst_n,

	// 来自访存阶段的信息
	input  wire [`REG_ADDR_BUS  ]   mem_wa,
	input  wire                     mem_wreg,
	input  wire                     mem_whilo,
	input  wire                     mem_mreg,
	input  wire [`REG_BUS       ] 	 mem_dreg,
	input  wire [`DOUBLE_REG_BUS] 	 mem_dhilo,
	input wire  [`DATA_WE_BUS   ]   mem_dre,

	// 送至写回阶段的信息 
	output reg  [`REG_ADDR_BUS  ]   wb_wa,
	output reg                      wb_wreg,
	output reg                      wb_whilo,
	output reg                      wb_mreg,
	output reg  [`REG_BUS       ]   wb_dreg,
	output reg  [`DOUBLE_REG_BUS]   wb_dhilo,
	output reg  [`DATA_WE_BUS   ]   wb_dre
    );

    always @(posedge cpu_clk_50M) begin
		// 复位的时候将送至写回阶段的信息清0
		if (cpu_rst_n == `RST_ENABLE) begin
			wb_wa       <= `REG_NOP;
			wb_wreg     <= `WRITE_DISABLE;
			wb_whilo    <= `WRITE_DISABLE;
			wb_mreg     <= `WRITE_DISABLE;
			wb_dreg     <= `ZERO_WORD;
			wb_dhilo    <= `ZERO_DWORD;
			wb_dre      <= 4'b0000;
		end
		// 将来自访存阶段的信息寄存并送至写回阶段
		else begin
			wb_wa 	    <= mem_wa;
			wb_wreg     <= mem_wreg;
			wb_whilo    <= mem_whilo;
			wb_mreg     <= mem_mreg;
			wb_dreg     <= mem_dreg;
			wb_dhilo    <= mem_dhilo;
			wb_dre      <= mem_dre;
		end
	end

endmodule