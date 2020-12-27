`include "defines.v"

module wb_stage(
    input  wire                   cpu_rst_n,
    
    // 从访存阶段获得的信息
    input  wire [`ALUOP_BUS     ] wb_aluop_i,
	input  wire [`REG_ADDR_BUS  ] wb_wa_i,
	input  wire                   wb_wreg_i,
	input  wire                   wb_whilo_i,
	input  wire                   wb_mreg_i,
	input  wire [`REG_BUS       ] wb_dreg_i,
	input  wire [`DOUBLE_REG_BUS] wb_dhilo_i,
	input  wire [`DATA_WE_BUS   ] wb_dre_i,

    input  wire                     cp0_we_i,
    input  wire [`REG_ADDR_BUS  ]   cp0_waddr_i,
    input  wire [`REG_BUS       ]   cp0_wdata_i,

    // 写回目的寄存器的数据
    output wire [`REG_ADDR_BUS  ] wb_wa_o,
	output wire                   wb_wreg_o,
	output wire                   wb_whilo_o,
    output wire [`WORD_BUS      ] wb_wd_o,
    output wire [`REG_BUS       ] wb_dhi_o,
    output wire [`REG_BUS       ] wb_dlo_o,
    
    output wire                   wb2exe_whilo,
    output wire [`DOUBLE_REG_BUS] wb2exe_hilo,
    
    input  wire [`DATA_BUS      ] dm,
    
    output wire                     cp0_we_o,
    output wire [`REG_ADDR_BUS  ]   cp0_waddr_o,    
    output wire [`REG_BUS       ]   cp0_wdata_o
    );
    
    wire [`REG_BUS] dmem;
    
    assign wb2exe_whilo = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_whilo_i;
    assign wb2exe_hilo  = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_dhilo_i;
    
    // 直接送至CP0协处理器的信号
    assign cp0_we_o     = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : cp0_we_i;
    assign cp0_waddr_o  = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD  : cp0_waddr_i;
    assign cp0_wdata_o  = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD  : cp0_wdata_i;
    
    assign dmem         = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                          (wb_dre_i == 4'b1111) ? {dm[7:0], dm[15:8], dm[23:16], dm[31:24]} :
                          (wb_dre_i == 4'b1100 & wb_aluop_i == `MINIMIPS32_LH ) ? {{16{dm[23]}}, dm[23:16], dm[31:24]} :
                          (wb_dre_i == 4'b1100 & wb_aluop_i == `MINIMIPS32_LHU) ? { 16'b0,       dm[23:16], dm[31:24]} :
                          (wb_dre_i == 4'b0011 & wb_aluop_i == `MINIMIPS32_LH ) ? {{16{dm[ 7]}}, dm[ 7: 0], dm[15: 8]} :
                          (wb_dre_i == 4'b0011 & wb_aluop_i == `MINIMIPS32_LHU) ? { 16'b0,       dm[ 7: 0], dm[15: 8]} :
                          (wb_dre_i == 4'b1000 & wb_aluop_i == `MINIMIPS32_LB ) ? {{24{dm[31]}}, dm[31:24]} :
                          (wb_dre_i == 4'b1000 & wb_aluop_i == `MINIMIPS32_LBU) ? { 24'b0,       dm[31:24]} :
                          (wb_dre_i == 4'b0100 & wb_aluop_i == `MINIMIPS32_LB ) ? {{24{dm[23]}}, dm[23:16]} :
                          (wb_dre_i == 4'b0100 & wb_aluop_i == `MINIMIPS32_LBU) ? { 24'b0,       dm[23:16]} :
                          (wb_dre_i == 4'b0010 & wb_aluop_i == `MINIMIPS32_LB ) ? {{24{dm[15]}}, dm[15: 8]} :
                          (wb_dre_i == 4'b0010 & wb_aluop_i == `MINIMIPS32_LBU) ? { 24'b0,       dm[15: 8]} :
                          (wb_dre_i == 4'b0001 & wb_aluop_i == `MINIMIPS32_LB ) ? {{24{dm[ 7]}}, dm[ 7: 0]} :
                          (wb_dre_i == 4'b0001 & wb_aluop_i == `MINIMIPS32_LBU) ? { 24'b0,       dm[ 7: 0]} : `ZERO_WORD;

    assign wb_wa_o      = (cpu_rst_n == `RST_ENABLE) ? 5'b0 : wb_wa_i;
    assign wb_wreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_wreg_i;
    assign wb_whilo_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_whilo_i;
    assign wb_wd_o      = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                          (wb_mreg_i) ? dmem : wb_dreg_i;
    assign wb_dhi_o     = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : wb_dhilo_i[63:32];
    assign wb_dlo_o     = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : wb_dhilo_i[31:0];
    
endmodule
