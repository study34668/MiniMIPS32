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
    output wire [`DOUBLE_REG_BUS]  exe_hilo_o,
    
    output wire                    exe2id_wreg,
    output wire [`REG_ADDR_BUS ]   exe2id_wa,
    output wire [`REG_BUS      ]   exe2id_wd,
    output wire                    exe2id_mreg,
    
    output wire                    stallreq_exe,
    
    input  wire [`REG_ADDR_BUS ]   cp0_addr_i,
    input  wire [`REG_BUS      ]   cp0_data_i,
    
    input  wire                    mem2exe_cp0_we,
    input  wire [`REG_ADDR_BUS ]   mem2exe_cp0_wa,
    input  wire [`REG_BUS      ]   mem2exe_cp0_wd,
    input  wire                    wb2exe_cp0_we,
    input  wire [`REG_ADDR_BUS ]   wb2exe_cp0_wa,
    input  wire [`REG_BUS      ]   wb2exe_cp0_wd,
    
    input  wire [`INST_ADDR_BUS]   exe_pc_i,
    input  wire                    exe_in_delay_i,
    input  wire [`EXC_CODE_BUS ]   exe_exccode_i,
    
    output wire                    cp0_re_o,
    output wire [`REG_ADDR_BUS ]   cp0_raddr_o,
    output wire                    cp0_we_o,
    output wire [`REG_ADDR_BUS ]   cp0_waddr_o,
    output wire [`REG_BUS      ]   cp0_wdata_o,
    
    output wire [`INST_ADDR_BUS]   exe_pc_o,
    output wire                    exe_in_delay_o,
    output wire [`EXC_CODE_BUS ]   exe_exccode_o
    );

    // 直接传到下一阶段
    assign exe_mreg_o  = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_mreg_i;
    assign exe_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_whilo_i;
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_din_o   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : exe_din_i;
    assign exe2id_wreg = (cpu_rst_n == `RST_ENABLE) ? `WRITE_DISABLE : exe_wreg_i;
    assign exe2id_wa   = (cpu_rst_n == `RST_ENABLE) ? 5'b0 : exe_wa_i;
    assign exe2id_mreg = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_mreg_i;
    
    //直接输出的信号
    assign exe_pc_o =(cpu_rst_n ==  `RST_ENABLE)? `PC_INIT : exe_pc_i;
    assign exe_in_delay_o =(cpu_rst_n ==  `RST_ENABLE)? 1'b0 : exe_in_delay_i;
    
    wire [`REG_BUS       ]      logicres;       // 保存逻辑运算的结果
    wire [`REG_BUS       ]      arithres;
    wire [`REG_BUS       ]      movres;
    wire [`REG_BUS       ]      shiftres;
    reg  [`DOUBLE_REG_BUS]      divres;
    
    wire                        signed_div_i;
    wire [`REG_BUS       ]      div_opdata1;
    wire [`REG_BUS       ]      div_opdata2;
    wire                        div_start;
    reg                         div_ready;
    
    wire [`REG_BUS       ]      hi_t;
    wire [`REG_BUS       ]      lo_t;
    //保存CP0中寄存器的最新值
    wire[`REG_BUS        ]      cp0_t;
    
    assign stallreq_exe = (cpu_rst_n == `RST_ENABLE) ? `NOSTOP :
                          ((exe_aluop_i == `MINIMIPS32_DIV | exe_aluop_i == `MINIMIPS32_DIVU) && (div_ready == `DIV_NOT_READY)) ? `STOP : `NOSTOP;
                          
    assign div_opdata1 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                         (exe_aluop_i == `MINIMIPS32_DIV | exe_aluop_i == `MINIMIPS32_DIVU) ? exe_src1_i : `ZERO_WORD;
                         
    assign div_opdata2 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                         (exe_aluop_i == `MINIMIPS32_DIV | exe_aluop_i == `MINIMIPS32_DIVU) ? exe_src2_i : `ZERO_WORD;
                         
    assign div_start = (cpu_rst_n == `RST_ENABLE) ? `DIV_STOP :
                       ((exe_aluop_i == `MINIMIPS32_DIV | exe_aluop_i == `MINIMIPS32_DIVU) && (div_ready == `DIV_NOT_READY)) ? `DIV_START : `DIV_STOP;
    
    assign signed_div_i = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                          (exe_aluop_i == `MINIMIPS32_DIV) ? 1'b1 : 1'b0;
                         
    //根据内部操作码alu_op_i，确定CP0寄存器的读/写访存信号
    assign cp0_we_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                      (exe_aluop_i == `MINIMIPS32_MTC0) ? 1'b1: 1'b0;
    
    assign cp0_wdata_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                         (exe_aluop_i == `MINIMIPS32_MTC0) ? exe_src2_i :`ZERO_WORD;
    
    assign cp0_waddr_o = (cpu_rst_n == `RST_ENABLE) ? `REG_NOP : cp0_addr_i;
    
    assign cp0_raddr_o = (cpu_rst_n == `RST_ENABLE) ? `REG_NOP :cp0_addr_i;
    
    assign cp0_re_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                      (exe_aluop_i == `MINIMIPS32_MTC0) ? 1'b1: 1'b0;
    
    //判断是否存在针对CP0中寄存器的数据相关，并获得CP0中寄存器的最新值
    assign cp0_t = (cp0_re_o  != `READ_ENABLE) ? `ZERO_WORD :
                   (mem2exe_cp0_we == `WRITE_ENABLE && mem2exe_cp0_wa == cp0_raddr_o) ? mem2exe_cp0_wd :
                   (wb2exe_cp0_we == `WRITE_ENABLE && wb2exe_cp0_wa == cp0_raddr_o) ? wb2exe_cp0_wd : cp0_data_i;       



    wire [34:0]     div_temp;
    wire [34:0]     div_temp1;
    wire [34:0]     div_temp2;
    wire [34:0]     div_temp3;
    wire [33:0]     divisor1;
    wire [33:0]     divisor2;
    wire [33:0]     divisor3;
    wire [ 1:0]     mul_cnt;
    
    reg  [31:0]     temp_op1;
    reg  [31:0]     temp_op2;
    reg  [ 5:0]     cnt;
    reg  [65:0]     dividend;
    reg  [ 1:0]     state;
    
    assign divisor1 = temp_op2;
    assign divisor2 = temp_op2 * 2;
    assign divisor3 = temp_op2 * 3;
    
    assign div_temp1 = {1'b000, dividend[63:32]} - {1'b0, divisor1};
    assign div_temp2 = {1'b000, dividend[63:32]} - {1'b0, divisor2};
    assign div_temp3 = {1'b000, dividend[63:32]} - {1'b0, divisor3};
    
    assign div_temp = (div_temp3[34] == 1'b0) ? div_temp3 :
                      (div_temp2[34] == 1'b0) ? div_temp2 : div_temp1;
                      
    assign mul_cnt = (div_temp3[34] == 1'b0) ? 2'b11 :
                     (div_temp2[34] == 1'b0) ? 2'b10 : 2'b01;
                     
    always @ (posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            state       <= `DIV_FREE;
            div_ready   <= `DIV_NOT_READY;
            divres      <= {`ZERO_WORD, `ZERO_WORD};
        end else begin
            case (state)
                `DIV_FREE: begin
                    if (div_start == `DIV_START) begin
                        if (div_opdata2 == `ZERO_WORD) begin
                            state <= `DIV_BY_ZERO;
                        end else begin
                            state <= `DIV_ON;
                            cnt <= 6'b000000;
                            if (signed_div_i & div_opdata1[31] == 1'b1) begin
                                temp_op1 = ~div_opdata1 + 1;
                            end else begin
                                temp_op1 = div_opdata1;
                            end
                            if (signed_div_i & div_opdata2[31] == 1'b1) begin
                                temp_op2 = ~div_opdata2 + 1;
                            end else begin
                                temp_op2 = div_opdata2;
                            end
                            dividend <= {2'b00, `ZERO_WORD, temp_op1};
                        end
                    end else begin
                        div_ready <= `DIV_NOT_READY;
                        divres <= {`ZERO_WORD, `ZERO_WORD};
                    end
                end
                
                `DIV_BY_ZERO: begin
                    dividend <= {`ZERO_WORD, `ZERO_WORD};
                    state <= `DIV_END;
                end
                
                `DIV_ON: begin
                    if (cnt != 6'b100010) begin
                        if (div_temp[34] == 1'b1) begin
                            dividend <= {dividend[63:0], 2'b00};
                        end else begin
                            dividend <= {div_temp[31:0], dividend[31:0], mul_cnt};
                        end
                        cnt <= cnt + 2;
                    end else begin
                        if (signed_div_i & ((div_opdata1[31] ^ div_opdata2[31]) == 1'b1)) begin
                            dividend[31:0] <= (~dividend[31:0] + 1);
                        end
                        if (signed_div_i & ((div_opdata1[31] ^ dividend[65]) == 1'b1)) begin
                            dividend[65:34] <= (~dividend[65:34] + 1);
                        end
                        state <= `DIV_END;
                        cnt <= 6'b000000;
                    end
                end
                
                `DIV_END: begin
                    divres <= {dividend[65:34], dividend[31:0]};
                    div_ready <= `DIV_READY;
                    if (div_start == `DIV_STOP) begin
                        state     <= `DIV_FREE;
                        div_ready <= `DIV_NOT_READY;
                        divres    <= {`ZERO_WORD, `ZERO_WORD};
                    end
                end
            endcase
        end
    end

    // 根据内部操作码aluop进行逻辑运算
    assign logicres = (exe_aluop_i == `MINIMIPS32_AND ) ? (exe_src1_i & exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_ANDI) ? (exe_src1_i & exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_ORI ) ? (exe_src1_i | exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_OR  ) ? (exe_src1_i | exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_XOR ) ? (exe_src1_i ^ exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_XORI) ? (exe_src1_i ^ exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_NOR ) ? (~(exe_src1_i | exe_src2_i)) : 
                      (exe_aluop_i == `MINIMIPS32_LUI ) ? exe_src2_i : `ZERO_WORD ;
    
    // 根据内部操作码aluop进行算术运算                  
    assign arithres = (exe_aluop_i == `MINIMIPS32_ADD  ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_ADDIU) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_ADDI ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_ADDU ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SUBU ) ? exe_src1_i + (~exe_src2_i) + 1 :
                      (exe_aluop_i == `MINIMIPS32_SUB  ) ? exe_src1_i + (~exe_src2_i) + 1 :
                      (exe_aluop_i == `MINIMIPS32_SLT  ) ? ($signed(exe_src1_i) < $signed(exe_src2_i)) ? `ONE_WORD : `ZERO_WORD :
                      (exe_aluop_i == `MINIMIPS32_SLTI ) ? ($signed(exe_src1_i) < $signed(exe_src2_i)) ? `ONE_WORD : `ZERO_WORD :
                      (exe_aluop_i == `MINIMIPS32_SLTIU) ? ($unsigned(exe_src1_i) < $unsigned(exe_src2_i)) ? `ONE_WORD : `ZERO_WORD :
                      (exe_aluop_i == `MINIMIPS32_SLTU ) ? ($unsigned(exe_src1_i) < $unsigned(exe_src2_i)) ? `ONE_WORD : `ZERO_WORD :
                      (exe_aluop_i == `MINIMIPS32_LB   ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_LW   ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_LH   ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_LBU  ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_LHU  ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SB   ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SW   ) ? exe_src1_i + exe_src2_i :
                      (exe_aluop_i == `MINIMIPS32_SH   ) ? exe_src1_i + exe_src2_i : `ZERO_WORD;
    
    assign hi_t     = ((mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[`HI_ADDR] :
                      (wb2exe_whilo  == `WRITE_ENABLE) ? wb2exe_hilo[`HI_ADDR] : exe_hi_i) ;
    assign lo_t     = ((mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[`LO_ADDR] :
                      (wb2exe_whilo  == `WRITE_ENABLE) ? wb2exe_hilo[`LO_ADDR] : exe_lo_i) ;          
    
    assign movres   = (exe_aluop_i == `MINIMIPS32_MFHI) ? hi_t :
                      (exe_aluop_i == `MINIMIPS32_MFLO) ? lo_t : `ZERO_WORD;
    
    // 根据内部操作码aluop进行移位运算
    assign shiftres = (exe_aluop_i == `MINIMIPS32_SLL ) ? (exe_src2_i << exe_src1_i):
                      (exe_aluop_i == `MINIMIPS32_SLLV) ? (exe_src2_i << exe_src1_i):
                      (exe_aluop_i == `MINIMIPS32_SRL ) ? (exe_src2_i >> exe_src1_i) :
                      (exe_aluop_i == `MINIMIPS32_SRLV) ? (exe_src2_i >> exe_src1_i) :
                      (exe_aluop_i == `MINIMIPS32_SRA ) ? ($signed(exe_src2_i) >>> exe_src1_i) :
                      (exe_aluop_i == `MINIMIPS32_SRAV) ? ($signed(exe_src2_i) >>> exe_src1_i) : `ZERO_WORD;

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
                      
    assign exe_hilo_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_DWORD :
                        (exe_aluop_i == `MINIMIPS32_MULT ) ? ($signed(exe_src1_i) * $signed(exe_src2_i)) :
                        (exe_aluop_i == `MINIMIPS32_MULTU) ? ($unsigned(exe_src1_i) * $unsigned(exe_src2_i)) :
                        (exe_aluop_i == `MINIMIPS32_DIV  ) ? divres : 
                        (exe_aluop_i == `MINIMIPS32_DIVU ) ? divres : 
                        (exe_aluop_i == `MINIMIPS32_MTHI ) ? {exe_src1_i, lo_t} : 
                        (exe_aluop_i == `MINIMIPS32_MTLO ) ? {hi_t, exe_src1_i} : `ZERO_WORD;

endmodule