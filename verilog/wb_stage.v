`include "defines.v"

module wb_stage(
    input  wire                   cpu_rst_n,
    // 从访存阶段获得的信息
	input  wire [`REG_ADDR_BUS  ] wb_wa_i,
	input  wire                   wb_wreg_i,
	input  wire                   wb_whilo_i,
	input  wire                   wb_mreg_i,
	input  wire [`REG_BUS       ] wb_dreg_i,
	input  wire [`DOUBLE_REG_BUS] wb_dhilo_i,
	input  wire [`DATA_WE_BUS   ] wb_dre_i,

    // 写回目的寄存器的数据
    output wire [`REG_ADDR_BUS  ] wb_wa_o,
	output wire                   wb_wreg_o,
	output wire                   wb_whilo_o,
    output wire [`WORD_BUS      ] wb_wd_o,
    output wire [`REG_BUS       ] wb_dhi_o,
    output wire [`REG_BUS       ] wb_dlo_o,
    
    output wire                   wb2exe_whilo,
    output wire [`DOUBLE_REG_BUS] wb2exe_hilo,
    
    input  wire [`DATA_BUS      ] dm
    );
    
    wire inst_word;
    
    wire [`DATA_BUS] dmem;
    wire [`DATA_BUS] dmemw;
    reg  [`BYTE_BUS] dmemb;
    
    assign wb2exe_whilo = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_whilo_i;
    assign wb2exe_hilo  = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_dhilo_i;
    
    assign inst_word = wb_dre_i[0]&wb_dre_i[1]&wb_dre_i[2]&wb_dre_i[3];
    
    assign dmemw = {dm[7:0], dm[15:8], dm[23:16], dm[31:24]};
    
    always @(*) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            dmemb <= `ZERO_BYTE;
        end
        else begin
            if (wb_dre_i[0] == `WRITE_ENABLE) begin
                dmemb <= dm[7:0];
            end
            else if (wb_dre_i[1] == `WRITE_ENABLE) begin
                dmemb <= dm[15:8];
            end
            else if (wb_dre_i[2] == `WRITE_ENABLE) begin
                dmemb <= dm[23:16];
            end
            else if (wb_dre_i[3] == `WRITE_ENABLE) begin
                dmemb <= dm[31:24];
            end
            else begin
                dmemb <= `ZERO_BYTE;
            end                        
        end
    end
    
    assign dmem = inst_word ? dmemw : { { 24 {dmemb[7]} }, dmemb};

    assign wb_wa_o      = (cpu_rst_n == `RST_ENABLE) ? 5'b0 : wb_wa_i;
    assign wb_wreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_wreg_i;
    assign wb_whilo_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_whilo_i;
    assign wb_wd_o      = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                          (wb_mreg_i) ? dmem : wb_dreg_i;
    assign wb_dhi_o     = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : wb_dhilo_i[63:32];
    assign wb_dlo_o     = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : wb_dhilo_i[31:0];
    
endmodule
