`include "defines.v"

module idexe_reg (
    input  wire 				  cpu_clk_50M,
    input  wire 				  cpu_rst_n,

    // 来自译码阶段的信息
    input  wire [`ALUTYPE_BUS  ]  id_alutype,
    input  wire [`ALUOP_BUS    ]  id_aluop,
    input  wire [`REG_BUS      ]  id_src1,
    input  wire [`REG_BUS      ]  id_src2,
    input  wire [`DATA_BUS     ]  id_din,
    input  wire [`REG_ADDR_BUS ]  id_wa,
    input  wire                   id_wreg,
    input  wire                   id_whilo,
    input  wire                   id_mreg,
    input  wire [`REG_BUS      ]  id_retaddr,
    
    input  wire [`STALL_BUS    ]  stall,
    
    // 送至执行阶段的信息
    output reg  [`ALUTYPE_BUS  ]  exe_alutype,
    output reg  [`ALUOP_BUS    ]  exe_aluop,
    output reg  [`REG_BUS      ]  exe_src1,
    output reg  [`REG_BUS      ]  exe_src2,
    output reg  [`DATA_BUS     ]  exe_din,
    output reg  [`REG_ADDR_BUS ]  exe_wa,
    output reg                    exe_wreg,
    output reg                    exe_whilo,
    output reg                    exe_mreg,
    output reg  [`REG_BUS      ]  exe_retaddr
    );

    always @(posedge cpu_clk_50M) begin
        // 复位的时候将送至执行阶段的信息清0
        if ((cpu_rst_n == `RST_ENABLE) || (stall[2] == `STOP && stall[3] == `NOSTOP)) begin
            exe_alutype 	   <= `NOP;
            exe_aluop 		   <= `MINIMIPS32_SLL;
            exe_src1 		   <= `ZERO_WORD;
            exe_src2 		   <= `ZERO_WORD;
            exe_din 		   <= `ZERO_WORD;
            exe_wa 			   <= `REG_NOP;
            exe_wreg    	   <= `WRITE_DISABLE;
            exe_whilo          <= `WRITE_DISABLE;
            exe_mreg           <= `WRITE_DISABLE;
            exe_retaddr		   <= `ZERO_WORD;
        end
        // 将来自译码阶段的信息寄存并送至执行阶段
        else if (stall[2] == `NOSTOP) begin
            exe_alutype 	   <= id_alutype;
            exe_aluop 		   <= id_aluop;
            exe_src1 		   <= id_src1;
            exe_src2 		   <= id_src2;
            exe_din 		   <= id_din;
            exe_wa 			   <= id_wa;
            exe_wreg		   <= id_wreg;
            exe_whilo          <= id_whilo;
            exe_mreg           <= id_mreg;
            exe_retaddr		   <= id_retaddr;
        end
    end

endmodule