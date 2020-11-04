`include "defines.v"

module MiniMIPS32_SYS(
    input wire sys_clk_100M,
    input wire sys_rst_n
    );

    wire                  cpu_clk_50M;
    wire [`INST_ADDR_BUS] iaddr;
    wire                  ice;
    wire [`INST_BUS     ] inst;
    wire [`DATA_ADDR_BUS] daddr;
    wire                  dce;
    wire [`DATA_WE_BUS  ] we;
    wire [`DATA_BUS     ] din;
    wire [`DATA_BUS     ] dm;

    clk_wiz_0 clocking
    (
        // Clock out ports
        .clk_out1(cpu_clk_50M),     // output clk_out1
        // Clock in ports
        .clk_in1(sys_clk_100M)
    );      // input clk_in1
    
    inst_rom inst_rom0 (
      .clka(cpu_clk_50M),    // input wire clka
      .ena(ice),      // input wire ena
      .addra(iaddr[12:2]),  // input wire [10 : 0] addra
      .douta(inst)  // output wire [31 : 0] douta
    );
    
    data_ram data_ram0 (
        .clka(cpu_clk_50M),
        .ena(dce),
        .wea(we),
        .addra(daddr[12:2]),
        .dina(din),
        .douta(dm)
    );

    MiniMIPS32 minimips32 (
        .cpu_clk_50M(cpu_clk_50M),
        .cpu_rst_n(sys_rst_n),
        .iaddr(iaddr),
        .ice(ice),
        .inst(inst),
        .daddr(daddr),
        .dce(dce),
        .we(we),
        .din(din),
        .dm(dm)
    );

endmodule
