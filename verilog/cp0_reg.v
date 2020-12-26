`include "defines.v"

module cp0_reg(
    input  wire 				 cpu_clk_50M,
	input  wire 				 cpu_rst_n,
	
	input  wire 				 we,
	input  wire 				 re,
	input  wire [`REG_ADDR_BUS ] raddr,
	input  wire [`REG_ADDR_BUS ] waddr,
	input  wire [`REG_BUS      ] wdata,
	input  wire [`CP0_INT_BUS  ] int_i,
	
	input  wire [`INST_ADDR_BUS] pc_i,
	input  wire                  in_delay_i,
	input  wire [`EXC_CODE_BUS ] exccode_i,
	 
	output wire 				 flush,
	output reg                   flush_im,
	output wire [`INST_ADDR_BUS] cp0_excaddr,

	output wire	[`REG_BUS      ] data_o,
	output wire [`REG_BUS 	   ] status_o,
	output wire [`REG_BUS 	   ] cause_o
    );

	reg [`REG_BUS] badvaddr;	// CP0的badvaddr寄存器
	reg [`REG_BUS] status;		// CP0的status寄存器
	reg [`REG_BUS] cause;		// CP0的cause寄存器
	reg [`REG_BUS] epc;			// CP0的epc寄存器

	assign status_o = status;
	assign cause_o = cause;

    // 根据异常信息生成清空流水线信号flush
    assign flush = (cpu_rst_n == `RST_ENABLE) ? `NOFLUSH : 
                   (exccode_i != `EXC_NONE ) ? `FLUSH : `NOFLUSH;

    //生成清空从指令存储器IM中取出的指令的信号flush_im
    always @(posedge cpu_clk_50M) begin
        if(cpu_rst_n == `RST_ENABLE) begin
        flush_im <= `NOFLUSH;
        end
        else begin
            flush_im <= flush;
        end
    end

    // 处理异常
    task do_exc; begin
		if (status[1] == 0) begin
			if(in_delay_i) begin        // 判断异常发生指令是否为延迟槽指令
				cause[31] <= 1;   		// 若为延迟槽指令，cause[31]置为1
				epc       <= pc_i - 4;
			end else begin	
				cause[31] <= 0;
				epc       <= pc_i;
			end
		end
		status[1]  <= 1'b1;
		cause[6:2] <= exccode_i;
	end
	endtask

    // 处理ERET指令
	task do_eret; begin
		status[1]   <= 0;
	end
	endtask

	// 产生异常处理程序入口地址
	assign cp0_excaddr = (cpu_rst_n == `RST_ENABLE) ? `PC_INIT :
						 (exccode_i == `EXC_INT   ) ? `EXC_INT_ADDR :
						 (exccode_i == `EXC_ERET && waddr == `CP0_EPC && we == `WRITE_ENABLE) ? wdata :
						 (exccode_i == `EXC_ERET  ) ? epc :
						 (exccode_i != `EXC_NONE  ) ? `EXC_ADDR : `ZERO_WORD;

    // 更新CP0寄存器数据
    always @ (posedge cpu_clk_50M) begin
		if(cpu_rst_n == `RST_ENABLE) begin
            badvaddr 	  <= `ZERO_WORD;
            status 	      <= 32'h10000000;              // status[28]为1，表示使能CP0协处理器
            cause 	      <= {25'b0, `EXC_NONE, 2'b0};
            epc 		  <= `ZERO_WORD;
		end 
        else begin
			cause[15:10] <= int_i;
			case (exccode_i)
				`EXC_NONE:                              // 无异常发生时，判断是否为写寄存器指令，写入数据
					if (we == `WRITE_ENABLE) begin
						case(waddr)
						 	`CP0_BADVADDR: badvaddr <= wdata;
						 	`CP0_STATUS:   status   <= wdata; 
						 	`CP0_CAUSE:    cause    <= wdata;
                            `CP0_EPC:      epc      <= wdata;
						endcase
					end
				`EXC_ERET:       // ERET指令
					do_eret();
				default:        // 异常发生时，处理对应异常
					do_exc();
			endcase
		end
	end

	// 读CP0中的寄存器
    assign data_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                    (re != `READ_ENABLE      ) ? `ZERO_WORD :
                    (raddr == `CP0_BADVADDR  ) ? badvaddr :
				    (raddr == `CP0_STATUS    ) ? status :
				    (raddr == `CP0_CAUSE     ) ? cause :
				    (raddr == `CP0_EPC       ) ? epc : `ZERO_WORD;

endmodule
