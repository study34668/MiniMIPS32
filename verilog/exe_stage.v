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
    input  wire [`REG_BUS      ]   exe_retaddr_i,
    
    input wire                     mem2exe_whilo,
    input wire [`DOUBLE_REG_BUS]   mem2exe_hilo,
    input wire                     wb2exe_whilo,
    input wire [`DOUBLE_REG_BUS]   wb2exe_hilo,

    // 送至执行阶段的信息
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire                    exe_whilo_o,
    output wire                    exe_mreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire [`DATA_BUS     ]   exe_din_o,
    output wire [`DOUBLE_REG_BUS]  exe_mul_o,
    
    output wire                    exe2id_wreg,
    output wire [`REG_ADDR_BUS ]   exe2id_wa,
    output wire [`REG_BUS      ]   exe2id_wd
    );

    // 直接传到下一阶段
    assign exe_mreg_o  = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_mreg_i;
    assign exe_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_whilo_i;
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_din_o   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : exe_din_i;
    assign exe2id_wreg = (cpu_rst_n == `RST_ENABLE) ? `WRITE_DISABLE : exe_wreg_i;
    assign exe2id_wa   = (cpu_rst_n == `RST_ENABLE) ? 5'b0 : exe_wa_i;
    
    wire [`REG_BUS       ]      logicres;       // 保存逻辑运算的结果
    wire [`REG_BUS       ]      arithres;
    wire [`REG_BUS       ]      movres;
    wire [`REG_BUS       ]      shiftres;
    
    // 根据内部操作码aluop进行逻辑运算
    assign logicres = (exe_aluop_i == `MINIMIPS32_AND) ? exe_src1_i & exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_ORI) ? exe_src1_i | exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_LUI) ? exe_src2_i : `ZERO_WORD;
                      
    assign arithres = (exe_aluop_i == `MINIMIPS32_ADD)   ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SUBU)  ? exe_src1_i + (~exe_src2_i) + 1 :
                      (exe_aluop_i == `MINIMIPS32_SLT)   ? ($signed(exe_src1_i) < $signed(exe_src2_i)) ? `ONE_WORD : `ZERO_WORD :
                      (exe_aluop_i == `MINIMIPS32_ADDIU) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SLTIU) ? (exe_src1_i < exe_src2_i) ? `ONE_WORD : `ZERO_WORD :
                      (exe_aluop_i == `MINIMIPS32_LB)    ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_LW)    ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SB)    ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SW)    ? exe_src1_i + exe_src2_i : `ZERO_WORD;
                      
    assign movres = (exe_aluop_i == `MINIMIPS32_MFHI) ? ((mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[`HI_ADDR] :
                                                        (wb2exe_whilo  == `WRITE_ENABLE) ? wb2exe_hilo[`HI_ADDR] : exe_hi_i) :
                    (exe_aluop_i == `MINIMIPS32_MFLO) ? ((mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[`LO_ADDR] :
                                                        (wb2exe_whilo  == `WRITE_ENABLE) ? wb2exe_hilo[`LO_ADDR] : exe_lo_i) : `ZERO_WORD;
    
    assign shiftres = (exe_aluop_i == `MINIMIPS32_SLL) ? exe_src2_i << exe_src1_i : `ZERO_WORD;

    assign exe_wa_o   = (cpu_rst_n   == `RST_ENABLE ) ? 5'b0 	 : exe_wa_i;
    assign exe_wreg_o = (cpu_rst_n   == `RST_ENABLE ) ? 1'b0 	 : exe_wreg_i;
    
    // 根据操作类型alutype确定执行阶段最终的运算结果（既可能是待写入目的寄存器的数据，也可能是访问数据存储器的地址）
    assign exe_wd_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_WORD : 
                      (exe_alutype_i == `LOGIC    ) ? logicres  :
                      (exe_alutype_i == `ARITH    ) ? arithres  :
                      (exe_alutype_i == `MOVE     ) ? movres    :
                      (exe_alutype_i == `SHIFT    ) ? shiftres  :
                      (exe_alutype_i == `JUMP     ) ? exe_retaddr_i : `ZERO_WORD;
                      
    assign exe2id_wd = exe_wd_o;
                      
    assign exe_mul_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_DWORD :
                       (exe_aluop_i == `MINIMIPS32_MULT) ? (exe_src1_i * exe_src2_i) : `ZERO_DWORD;

endmodule