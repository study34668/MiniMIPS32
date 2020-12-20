`timescale 1ns / 1ps

/*------------------- 全局参数 -------------------*/
`define RST_ENABLE      1'b0                // 复位信号有效  RST_ENABLE
`define RST_DISABLE     1'b1                // 复位信号无效
`define ZERO_BYTE       8'h00               // 8位的数值0
`define ZERO_HWORD      16'h0000            // 16位的数值0
`define ZERO_WORD       32'h00000000        // 32位的数值0
`define ZERO_DWORD      64'b0               // 64位的数值0
`define ONE_WORD        32'h00000001        // 32位的数值1
`define WRITE_ENABLE    1'b1                // 使能写
`define WRITE_DISABLE   1'b0                // 禁止写
`define READ_ENABLE     1'b1                // 使能读
`define READ_DISABLE    1'b0                // 禁止读
`define ALUOP_BUS       7 : 0               // 译码阶段的输出aluop_o的宽度
`define SHIFT_ENABLE    1'b1                // 移位指令使能 
`define ALUTYPE_BUS     2 : 0               // 译码阶段的输出alutype_o的宽度  
`define TRUE_V          1'b1                // 逻辑"真"  
`define FALSE_V         1'b0                // 逻辑"假"  
`define CHIP_ENABLE     1'b1                // 芯片使能  
`define CHIP_DISABLE    1'b0                // 芯片禁止  
`define WORD_BUS        31: 0               // 32位宽
`define HI_ADDR         63: 32              // hi
`define LO_ADDR         31: 0               // lo
`define RT_ENABLE       1'b1                // rt选择使能
`define SIGNED_EXT      1'b1                // 符号扩展使能
`define IMM_ENABLE      1'b1                // 立即数选择使能
`define UPPER_ENABLE    1'b1                // 立即数移位使能
`define MREG_ENABLE     1'b1                // 写回阶段存储器结果选择信号
`define BSEL_BUS        3 : 0               // 数据存储器字节选择信号宽度
`define PC_INIT         32'h00000000        // PC初始值

/*------------------- 指令字参数 -------------------*/
`define INST_ADDR_BUS   31: 0               // 指令的地址宽度
`define INST_BUS        31: 0               // 指令的数据宽度

/*------------------- 数据字参数 -------------------*/
`define DATA_ADDR_BUS   31: 0               // 数据的地址宽度
`define DATA_BUS        31: 0               // 数据的数据宽度
`define DATA_WE_BUS      3: 0               // 数据的写使能宽度
`define BYTE_BUS         7: 0               // 一个字节的宽度

// 操作类型alutype
`define NOP             3'b000
`define ARITH           3'b001
`define LOGIC           3'b010
`define MOVE            3'b011
`define SHIFT           3'b100
`define JUMP            3'b101
`define PRIVILEGE       3'b110

// 内部操作码aluop
`define MINIMIPS32_LUI             8'h05

`define MINIMIPS32_MFHI            8'h0C
`define MINIMIPS32_MFLO            8'h0D
`define MINIMIPS32_MTHI            8'h0E
`define MINIMIPS32_MTLO            8'h0F

`define MINIMIPS32_SLL             8'h11
`define MINIMIPS32_SRL             8'h12
`define MINIMIPS32_SRA             8'h13

`define MINIMIPS32_MULT            8'h14
`define MINIMIPS32_MULTU           8'h15

`define MINIMIPS32_DIV             8'h16
`define MINIMIPS32_DIVU            8'h17

`define MINIMIPS32_ADD             8'h18
`define MINIMIPS32_ADDIU           8'h19
`define MINIMIPS32_SUBU            8'h1B
`define MINIMIPS32_AND             8'h1C
`define MINIMIPS32_ORI             8'h1D
`define MINIMIPS32_XOR             8'h1E
`define MINIMIPS32_NOR             8'h1F

`define MINIMIPS32_SLT             8'h26
`define MINIMIPS32_SLTIU           8'h27
`define MINIMIPS32_SLTI            8'h28
`define MINIMIPS32_SLTU            8'h29

`define MINIMIPS32_J               8'h2C
`define MINIMIPS32_JR              8'h2D
`define MINIMIPS32_JAL             8'h2E
`define MINIMIPS32_JALR            8'h2F

`define MINIMIPS32_BEQ             8'h30
`define MINIMIPS32_BNE             8'h31
`define MINIMIPS32_BLEZ            8'h32
`define MINIMIPS32_BGTZ            8'h33
`define MINIMIPS32_BLTZ            8'h34
`define MINIMIPS32_BGEZ            8'h35
`define MINIMIPS32_BLTZAL          8'h36
`define MINIMIPS32_BGEZAL          8'h37

`define MINIMIPS32_SLLV            8'h41
`define MINIMIPS32_SRLV            8'h42
`define MINIMIPS32_SRAV            8'h43

`define MINIMIPS32_ADDI            8'h48
`define MINIMIPS32_ADDU            8'h49
`define MINIMIPS32_SUB             8'h4B
`define MINIMIPS32_ANDI            8'h4C
`define MINIMIPS32_OR              8'h4D
`define MINIMIPS32_XORI            8'h4E

`define MINIMIPS32_SYSCALL         8'h86
`define MINIMIPS32_ERET            8'h87
`define MINIMIPS32_MFC0            8'h8C
`define MINIMIPS32_MTC0            8'h8D

`define MINIMIPS32_LB              8'h90
`define MINIMIPS32_LH              8'h91
`define MINIMIPS32_LW              8'h92
`define MINIMIPS32_SB              8'h98
`define MINIMIPS32_SH              8'h99
`define MINIMIPS32_SW              8'h9A
`define MINIMIPS32_LBU             8'h9B
`define MINIMIPS32_LHU             8'h9C

/*------------------- 通用寄存器堆参数 -------------------*/
`define REG_BUS         31: 0               // 寄存器数据宽度
`define DOUBLE_REG_BUS  63: 0               // 两倍的通用寄存器的数据线宽度
`define REG_ADDR_BUS    4 : 0               // 寄存器的地址宽度
`define REG_NUM         32                  // 寄存器数量32个
`define REG_NOP         5'b00000            // 零号寄存器

/*------------------- Branch Target Buffer -------------------*/
//`define BTB_BUS         56: 0
//`define BTB_VALID_BUS   56
//`define BTB_TAG_BUS     55: 34
//`define BTB_BTA_BUS     33: 2
//`define BTB_BHT_BUS     1: 0
//`define BTB_NUM         64

/*------------------- 流水线暂停 -------------------*/
`define STALL_BUS       3:0
`define STOP            1'b1
`define NOSTOP          1'b0

/*------------------- 除法指令 -------------------*/
`define DIV_FREE        2'b00
`define DIV_BY_ZERO     2'b01
`define DIV_ON          2'b10
`define DIV_END         2'b11
`define DIV_READY       1'b1
`define DIV_NOT_READY   1'b0
`define DIV_START       1'b1
`define DIV_STOP        1'b0

/*------------------- 异常处理参数 -------------------*/
//CP0协处理器参数
`define CP0_INT_BUS      7:0
`define CP0_BADVADDR     8
`define CP0_STATUS       12
`define CP0_CAUSE        13
`define CP0_EPC          14

//异常处理参数
`define EXC_CODE_BUS     4:0
`define EXC_INT          5'b00
`define EXC_SYS          5'h08
`define EXC_OV           5'h0c
`define EXC_NONE         5'h10
`define EXC_ERET         5'h11
`define EXC_ADDR         32'h100
`define EXC_INT_ADDR     32'h040

`define NOFLUSH          1'b0
`define FLUSH            1'b1