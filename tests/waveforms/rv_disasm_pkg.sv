// ============================================================
// Minimal RV32I + Zicsr disassembler for waveform annotation.
//
// Simulation only. Used by wave_probe to show each pipeline
// stage's instruction as text in GTKWave (Data Format: ASCII).
// ============================================================

`timescale 1ns / 1ps

package rv_disasm_pkg;

  localparam int ASM_CHARS = 24;

  function automatic string reg_name(input logic [4:0] r);
    return $sformatf("x%0d", r);
  endfunction

  function automatic string csr_name(input logic [11:0] a);
    case (a)
      12'h300: return "mstatus";
      12'h304: return "mie";
      12'h305: return "mtvec";
      12'h340: return "mscratch";
      12'h341: return "mepc";
      12'h342: return "mcause";
      12'h343: return "mtval";
      12'h344: return "mip";
      default: return $sformatf("0x%03h", a);
    endcase
  endfunction

  // PC-relative offsets are shown with an explicit sign (+12, -8).
  function automatic string rel(input int off);
    return (off >= 0) ? $sformatf("+%0d", off) : $sformatf("%0d", off);
  endfunction

  function automatic string rv_disasm(input logic [31:0] i);
    logic [6:0]  op;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  f3;
    logic [6:0]  f7;
    int          imm_i, imm_s, imm_b, imm_j;
    string       m;

    op  = i[6:0];
    rd  = i[11:7];
    f3  = i[14:12];
    rs1 = i[19:15];
    rs2 = i[24:20];
    f7  = i[31:25];

    imm_i = int'($signed(i[31:20]));
    imm_s = int'($signed({i[31:25], i[11:7]}));
    imm_b = int'($signed({i[31], i[7], i[30:25], i[11:8], 1'b0}));
    imm_j = int'($signed({i[31], i[19:12], i[20], i[30:21], 1'b0}));

    if (i == 32'h0000_0000) return "unimp";   // empty IMEM
    if (i == 32'h0000_0013) return "nop";
    if (i == 32'h0000_006f) return "j . (halt)";
    if (i == 32'h0000_0073) return "ecall";
    if (i == 32'h3020_0073) return "mret";

    case (op)
      7'b0110111:
        return $sformatf("lui %s,0x%0h", reg_name(rd), i[31:12]);

      7'b0010111:
        return $sformatf("auipc %s,0x%0h", reg_name(rd), i[31:12]);

      7'b1101111:
        return $sformatf("jal %s,%s", reg_name(rd), rel(imm_j));

      7'b1100111:
        return $sformatf("jalr %s,%0d(%s)", reg_name(rd), imm_i,
                         reg_name(rs1));

      7'b1100011: begin
        case (f3)
          3'b000: m = "beq";
          3'b001: m = "bne";
          3'b100: m = "blt";
          3'b101: m = "bge";
          3'b110: m = "bltu";
          3'b111: m = "bgeu";
          default: return "illegal";
        endcase
        return $sformatf("%s %s,%s,%s", m, reg_name(rs1),
                         reg_name(rs2), rel(imm_b));
      end

      7'b0000011: begin
        case (f3)
          3'b000: m = "lb";
          3'b001: m = "lh";
          3'b010: m = "lw";
          3'b100: m = "lbu";
          3'b101: m = "lhu";
          default: return "illegal";
        endcase
        return $sformatf("%s %s,%0d(%s)", m, reg_name(rd), imm_i,
                         reg_name(rs1));
      end

      7'b0100011: begin
        case (f3)
          3'b000: m = "sb";
          3'b001: m = "sh";
          3'b010: m = "sw";
          default: return "illegal";
        endcase
        return $sformatf("%s %s,%0d(%s)", m, reg_name(rs2), imm_s,
                         reg_name(rs1));
      end

      7'b0010011: begin
        case (f3)
          3'b000: m = "addi";
          3'b010: m = "slti";
          3'b011: m = "sltiu";
          3'b100: m = "xori";
          3'b110: m = "ori";
          3'b111: m = "andi";
          3'b001:
            return $sformatf("slli %s,%s,%0d", reg_name(rd),
                             reg_name(rs1), rs2);
          3'b101:
            return $sformatf("%s %s,%s,%0d",
                             f7[5] ? "srai" : "srli",
                             reg_name(rd), reg_name(rs1), rs2);
        endcase
        return $sformatf("%s %s,%s,%0d", m, reg_name(rd),
                         reg_name(rs1), imm_i);
      end

      7'b0110011: begin
        case (f3)
          3'b000: m = f7[5] ? "sub" : "add";
          3'b001: m = "sll";
          3'b010: m = "slt";
          3'b011: m = "sltu";
          3'b100: m = "xor";
          3'b101: m = f7[5] ? "sra" : "srl";
          3'b110: m = "or";
          3'b111: m = "and";
        endcase
        return $sformatf("%s %s,%s,%s", m, reg_name(rd),
                         reg_name(rs1), reg_name(rs2));
      end

      7'b1110011: begin
        case (f3)
          3'b001: m = "csrrw";
          3'b010: m = "csrrs";
          3'b011: m = "csrrc";
          3'b101: m = "csrrwi";
          3'b110: m = "csrrsi";
          3'b111: m = "csrrci";
          default: return "illegal";
        endcase
        if (f3[2])
          return $sformatf("%s %s,%s,%0d", m, reg_name(rd),
                           csr_name(i[31:20]), rs1);
        return $sformatf("%s %s,%s,%s", m, reg_name(rd),
                         csr_name(i[31:20]), reg_name(rs1));
      end

      default:
        return "illegal";
    endcase
  endfunction

endpackage
