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
    input  wire [`DOUBLE_REG_BUS]       mem_hilo_i,
    
    // 送至写回阶段的信息
    output wire [`ALUOP_BUS     ]       mem_aluop_o,
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
    
    output wire                         mem2id_mreg,
    
    output wire [`DATA_ADDR_BUS ]       daddr,
    output wire                         dce,
    output wire [`DATA_WE_BUS   ]       we,
    output wire [`DATA_WE_BUS   ]       dre,
    output wire [`DATA_BUS      ]       din
    );
    
    wire [`REG_BUS] din_word;
    wire [`REG_BUS] din_half;
    wire [`REG_BUS] din_byte;
    
    // 如果当前不是访存指令，则只需要把从执行阶段获得的信息直接输出
    assign mem_aluop_o   = (cpu_rst_n == `RST_ENABLE) ? 8'b0  : mem_aluop_i;
    assign mem_wa_o      = (cpu_rst_n == `RST_ENABLE) ? 5'b0  : mem_wa_i;
    assign mem_wreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wreg_i;
    assign mem_whilo_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_whilo_i;
    assign mem_mreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_mreg_i;
    assign mem_dreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wd_i;
    assign mem_dhilo_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_hilo_i;
    assign mem2id_wa     = (cpu_rst_n == `RST_ENABLE) ? 5'b0  : mem_wa_i;
    assign mem2id_wreg   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wreg_i;
    assign mem2id_wd     = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wd_i;
    assign mem2exe_whilo = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_whilo_i;
    assign mem2exe_hilo  = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_hilo_i;
    assign mem2id_mreg   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_mreg_i;
    
    assign dce          = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : 
                          ((mem_aluop_i == `MINIMIPS32_LB) | (mem_aluop_i == `MINIMIPS32_LW) | (mem_aluop_i == `MINIMIPS32_SB) | (mem_aluop_i == `MINIMIPS32_SW) |
                          (mem_aluop_i == `MINIMIPS32_LH) | (mem_aluop_i == `MINIMIPS32_SH) | (mem_aluop_i == `MINIMIPS32_LBU) | (mem_aluop_i == `MINIMIPS32_LHU));
    
    assign daddr        = (dce) ? mem_wd_i  : `ZERO_WORD;
    
    assign we           = (cpu_rst_n == `RST_ENABLE) ? 4'b0  :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b00)) ? 4'b1000 :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b01)) ? 4'b0100 :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b10)) ? 4'b0010 :
                          ((mem_aluop_i == `MINIMIPS32_SB) & (mem_wd_i[1:0] == 2'b11)) ? 4'b0001 :
                          ((mem_aluop_i == `MINIMIPS32_SH) & (mem_wd_i[1:0] == 2'b00)) ? 4'b1100 :
                          ((mem_aluop_i == `MINIMIPS32_SH) & (mem_wd_i[1:0] == 2'b10)) ? 4'b0011 :
                          (mem_aluop_i == `MINIMIPS32_SW) ? 4'b1111 : 4'b0;
    
    assign dre          = (cpu_rst_n == `RST_ENABLE) ? 4'b0  :
                          ((mem_aluop_i == `MINIMIPS32_LB | mem_aluop_i == `MINIMIPS32_LBU) & (mem_wd_i[1:0] == 2'b00)) ? 4'b1000 :
                          ((mem_aluop_i == `MINIMIPS32_LB | mem_aluop_i == `MINIMIPS32_LBU) & (mem_wd_i[1:0] == 2'b01)) ? 4'b0100 :
                          ((mem_aluop_i == `MINIMIPS32_LB | mem_aluop_i == `MINIMIPS32_LBU) & (mem_wd_i[1:0] == 2'b10)) ? 4'b0010 :
                          ((mem_aluop_i == `MINIMIPS32_LB | mem_aluop_i == `MINIMIPS32_LBU) & (mem_wd_i[1:0] == 2'b11)) ? 4'b0001 :
                          ((mem_aluop_i == `MINIMIPS32_LH | mem_aluop_i == `MINIMIPS32_LHU) & (mem_wd_i[1:0] == 2'b00)) ? 4'b1100 :
                          ((mem_aluop_i == `MINIMIPS32_LH | mem_aluop_i == `MINIMIPS32_LHU) & (mem_wd_i[1:0] == 2'b10)) ? 4'b0011 :
                          (mem_aluop_i == `MINIMIPS32_LW) ? 4'b1111 : 4'b0;
    
    assign din_word     = {mem_din_i[7:0], mem_din_i[15:8], mem_din_i[23:16], mem_din_i[31:24]};
    assign din_half     = {mem_din_i[7:0], mem_din_i[15:8], mem_din_i[ 7: 0], mem_din_i[15: 8]};
    assign din_byte     = {mem_din_i[7:0], mem_din_i[ 7:0], mem_din_i[ 7: 0], mem_din_i[ 7: 0]};
    assign din          = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD  :
                          (mem_aluop_i == `MINIMIPS32_SW) ? din_word :
                          (mem_aluop_i == `MINIMIPS32_SH) ? din_half :
                          (mem_aluop_i == `MINIMIPS32_SB) ? din_byte : `ZERO_WORD;

endmodule