`include "defines.v"

module exe_stage (
    input  wire 					cpu_clk_50M,
    input  wire 					cpu_rst_n,

    // 从译码阶段获得的信息
    input  wire [`ALUTYPE_BUS	] 	exe_alutype_i,
    input  wire [`ALUOP_BUS	    ] 	exe_aluop_i,
    input  wire [`REG_BUS 		] 	exe_src1_i,
    input  wire [`REG_BUS 		] 	exe_src2_i,
    input  wire [`DATA_BUS     ]   exe_din_i,
    input  wire [`REG_ADDR_BUS 	] 	exe_wa_i,
    input  wire 					exe_wreg_i,
    input  wire                    exe_whilo_i,
    input  wire                    exe_mreg_i,
    input  wire [`REG_BUS      ]   exe_hi_i,
    input  wire [`REG_BUS      ]   exe_lo_i,

    // 送至执行阶段的信息
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire                    exe_whilo_o,
    output wire                    exe_mreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire [`DATA_BUS     ]   exe_din_o,
    output wire [`DOUBLE_REG_BUS]  exe_mul_o
    );

    // 直接传到下一阶段
    assign exe_mreg_o  = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_mreg_i;
    assign exe_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_whilo_i;
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_din_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : exe_din_i;
    
    reg [`REG_BUS       ]      logicres;       // 保存逻辑运算的结果
    reg [`REG_BUS       ]      arithres;
    reg [`DOUBLE_REG_BUS]      mulres;
    reg [`REG_BUS       ]      movres;
    reg [`REG_BUS       ]      shiftres;
    
    // 根据内部操作码aluop进行逻辑运算
    always @(*) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            logicres <= `ZERO_WORD;
        end
        else begin
            case(exe_aluop_i)
                `MINIMIPS32_AND : logicres <= exe_src1_i & exe_src2_i;
                `MINIMIPS32_ORI  : logicres <= exe_src1_i | exe_src2_i;
                `MINIMIPS32_LUI: logicres <= exe_src2_i;
                default: logicres <= `ZERO_WORD;
            endcase
        end
    end
    
    always @(*) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            arithres <= `ZERO_WORD;
        end
        else begin
            case(exe_aluop_i)
                `MINIMIPS32_ADD : arithres <= $signed(exe_src1_i) + $signed(exe_src2_i);
                `MINIMIPS32_SUBU: arithres <= exe_src1_i - exe_src2_i;
                `MINIMIPS32_SLT : begin
                    if ($signed(exe_src1_i) < $signed(exe_src2_i)) begin
                        arithres <= `ONE_WORD;
                    end else begin
                        arithres <= `ZERO_WORD;
                    end
                end
                `MINIMIPS32_ADDIU: arithres <= exe_src1_i + exe_src2_i;
                `MINIMIPS32_SLTIU: begin
                    if (exe_src1_i < exe_src2_i) begin
                        arithres <= `ONE_WORD;
                    end else begin
                       arithres <= `ZERO_WORD;
                    end
                end
                `MINIMIPS32_LB  : arithres <= $signed(exe_src1_i) + $signed(exe_src2_i);
                `MINIMIPS32_LW  : arithres <= $signed(exe_src1_i) + $signed(exe_src2_i);
                `MINIMIPS32_SB  : arithres <= $signed(exe_src1_i) + $signed(exe_src2_i);
                `MINIMIPS32_SW  : arithres <= $signed(exe_src1_i) + $signed(exe_src2_i);
                default: arithres <= `ZERO_WORD;
            endcase
        end
    end
    
    always @(*) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            mulres <= `ZERO_DWORD;
        end
        else begin
            if (exe_aluop_i == `MINIMIPS32_MULT) begin
                mulres <= exe_src1_i * exe_src2_i;
            end
            else begin
                mulres <= `ZERO_DWORD;
            end
        end
    end
    
    always @(*) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            movres <= `ZERO_WORD;
        end
        else begin
            if (exe_aluop_i == `MINIMIPS32_MFHI) begin
                movres <= exe_hi_i;
            end
            else if (exe_aluop_i == `MINIMIPS32_MFLO) begin
                movres <= exe_lo_i;
            end
            else begin
                movres <= `ZERO_WORD;
            end
        end
    end
    
    always @(*) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            shiftres <= `ZERO_WORD;
        end
        else begin
            if (exe_aluop_i == `MINIMIPS32_SLL) begin
                shiftres <= exe_src2_i << exe_src1_i;
            end
            else begin
                shiftres <= `ZERO_WORD;
            end
        end
    end

    assign exe_wa_o   = (cpu_rst_n   == `RST_ENABLE ) ? 5'b0 	 : exe_wa_i;
    assign exe_wreg_o = (cpu_rst_n   == `RST_ENABLE ) ? 1'b0 	 : exe_wreg_i;
    
    // 根据操作类型alutype确定执行阶段最终的运算结果（既可能是待写入目的寄存器的数据，也可能是访问数据存储器的地址）
    assign exe_wd_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_WORD : 
                      (exe_alutype_i == `LOGIC    ) ? logicres  :
                      (exe_alutype_i == `ARITH    ) ? arithres  :
                      (exe_alutype_i == `MOVE     ) ? movres    :
                      (exe_alutype_i == `SHIFT    ) ? shiftres  : `ZERO_WORD;
                      
    assign exe_mul_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_DWORD :
                       (exe_aluop_i == `MINIMIPS32_MULT) ? mulres : `ZERO_DWORD;

endmodule