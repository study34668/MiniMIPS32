`include "defines.v"

module mem_stage (
    input  wire                         cpu_rst_n,

    // 从执行阶段获得的信息
    input  wire [`ALUOP_BUS     ]       mem_aluop_i,
    input  wire [`REG_ADDR_BUS  ]       mem_wa_i,
    input  wire                         mem_wreg_i,
    input  wire                         mem_whilo_i,
    input  wire                         mem_mreg_i,
    input  wire [`REG_BUS       ]       mem_wd_i,
    input  wire [`DATA_BUS      ]       mem_din_i,
    input  wire [`DOUBLE_REG_BUS]       mem_mul_i,
    
    // 送至写回阶段的信息
    output wire [`REG_ADDR_BUS  ]       mem_wa_o,
    output wire                         mem_wreg_o,
    output wire                         mem_whilo_o,
    output wire                         mem_mreg_o,
    output wire [`REG_BUS       ]       mem_dreg_o,
    output wire [`DOUBLE_REG_BUS]       mem_dhilo_o,
    
    output wire                         mem2id_wreg,
    output wire [`REG_ADDR_BUS ]        mem2id_wa,
    output wire [`REG_BUS      ]        mem2id_wd,
    output wire                         mem2exe_whilo,
    output wire [`DOUBLE_REG_BUS]       mem2exe_hilo,
    
    output wire [`DATA_ADDR_BUS ]       daddr,
    output wire                         dce,
    output wire [`DATA_WE_BUS   ]       we,
    output wire [`DATA_WE_BUS   ]       dre,
    output wire [`DATA_BUS      ]       din
    );
    
    // 如果当前不是访存指令，则只需要把从执行阶段获得的信息直接输出
    assign mem_wa_o      = (cpu_rst_n == `RST_ENABLE) ? 5'b0  : mem_wa_i;
    assign mem_wreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wreg_i;
    assign mem_whilo_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_whilo_i;
    assign mem_mreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_mreg_i;
    assign mem_dreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wd_i;
    assign mem_dhilo_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_mul_i;
    assign mem2id_wa     = (cpu_rst_n == `RST_ENABLE) ? 5'b0  : mem_wa_i;
    assign mem2id_wreg   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wreg_i;
    assign mem2id_wd     = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wd_i;
    assign mem2exe_whilo = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_whilo_i;
    assign mem2exe_hilo  = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_mul_i;
    
    assign dce          = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : ((mem_aluop_i == `MINIMIPS32_LB) | (mem_aluop_i == `MINIMIPS32_LW) | (mem_aluop_i == `MINIMIPS32_SB) | (mem_aluop_i == `MINIMIPS32_SW));
    assign daddr        = (dce) ? mem_wd_i  : `ZERO_WORD;
    assign we[3]        = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b00)) | (mem_aluop_i == `MINIMIPS32_SW);
    assign we[2]        = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b01)) | (mem_aluop_i == `MINIMIPS32_SW);
    assign we[1]        = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b10)) | (mem_aluop_i == `MINIMIPS32_SW);
    assign we[0]        = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b11)) | (mem_aluop_i == `MINIMIPS32_SW);
    assign dre[3]       = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_LB) & (mem_wd_i[1:0] == 2'b00)) | (mem_aluop_i == `MINIMIPS32_LW);
    assign dre[2]       = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_LB) & (mem_wd_i[1:0] == 2'b01)) | (mem_aluop_i == `MINIMIPS32_LW);
    assign dre[1]       = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_LB) & (mem_wd_i[1:0] == 2'b10)) | (mem_aluop_i == `MINIMIPS32_LW);
    assign dre[0]       = (cpu_rst_n == `RST_ENABLE) ? 1'b0  :
                          ((mem_aluop_i == `MINIMIPS32_LB) & (mem_wd_i[1:0] == 2'b11)) | (mem_aluop_i == `MINIMIPS32_LW);
    assign din          = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD  : {mem_din_i[7:0], mem_din_i[15:8], mem_din_i[23:16], mem_din_i[31:24]};

endmodule