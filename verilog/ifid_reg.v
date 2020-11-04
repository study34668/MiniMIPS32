`include "defines.v"

module ifid_reg (
	input  wire 						cpu_clk_50M,
	input  wire 						cpu_rst_n,

	// 来自取指阶段的信息  
	input  wire [`INST_ADDR_BUS]       if_pc,
	
	// 送至译码阶段的信息  
	output reg  [`INST_ADDR_BUS]       id_pc
	);

	always @(posedge cpu_clk_50M) begin
	    // 复位的时候将送至译码阶段的信息清0
		if (cpu_rst_n == `RST_ENABLE) begin
			id_pc 	<= `PC_INIT;
		end
		// 将来自取指阶段的信息寄存并送至译码阶段
		else begin
			id_pc	<= if_pc;		
		end
	end

endmodule