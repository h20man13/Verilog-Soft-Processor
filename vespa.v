module vespa();
`define TRACE_PC 1
`define TRACE_REGS 1
`define TRACE_CC 1
   parameter WIDTH = 32;
   parameter NUMREGS = 32;
   parameter MEMSIZE = (1 << 13);

   reg [7:0]               MEM[0:MEMSIZE - 1];
   reg [WIDTH - 1:0] 	   R[0:NUMREGS - 1];
   reg [WIDTH - 1:0] 	   PC;
   reg [WIDTH - 1:0] 	   IR;
   reg 			   C;
   reg 			   V;
   reg 			   Z;
   reg 			   N;
   reg 			   RUN;

   reg [WIDTH - 1:0] 	   op1;
   reg [WIDTH - 1:0] 	   op2;
   reg [WIDTH:0] 	   result;

`define NOP 'd0
`define ADD 'd1
`define SUB 'd2
`define OR  'd3
`define NOT 'd4
`define AND 'd5
`define XOR 'd6
`define CMP 'd7
`define BXX 'd8
`define JMP 'd9
`define LD  'd10
`define LDI 'd11
`define LDX 'd12
`define ST  'd13
`define STX 'd14
`define HLT 'd31

`define BRA 'b0000
`define BNV 'b1000
`define BCC 'b0001
`define BCS 'b1001
`define BVC 'b0010
`define BVS 'b1010
`define BEQ 'b0011
`define BNE 'b1011
`define BGE 'b0100
`define BLT 'b1100
`define BGT 'b0101
`define BLE 'b1101
`define BPL 'b0110
`define BMI 'b1110

`define OPCODE IR[31:27]
`define rdst IR[26:22]
`define rsl IR[21:17]
`define IMM_OP IR[16]
`define rs2 IR[15:11]
`define rst IR[26:22]
`define immed23 IR[22:0]
`define immed22 IR[21:0]
`define immed17 IR[16:0]
`define immed16 IR[15:0]
`define COND IR[26:23]

initial begin
   $readmemh("v.out", MEM);

   RUN = 1;
   PC = 0;
   num_instrs = 0;

   while(RUN == 1)
     begin
	num_instrs = num_instrs + 1;
	fetch;
	execute;
	print_trace;
     end

   $display("\nTotal number or instructions executed -> %d\n\n", num_instrs);
   $finish;
end // initial begin

   task fetch;
      begin
	 IR = read_mem(PC);
	 PC = PC + 4;
      end
   endtask // fetch

   function [WIDTH - 1:0] read_mem;
      input [WIDTH - 1:0] addr;
      read_mem = {MEM[addr],MEM[addr + 1], MEM[addr + 2], MEM[addr + 3]};
   endfunction // read_mem

   task execute;
      begin

	 case (`OPCODE)
	   `ADD: begin
	      if(`IMM_OP == 0)
		op2 = R[`rs2];
	      else
		op2 = sext16(`immed16);
	      op1 = R[`rs1];
	      result = op1 + op2;
	      R[`rdst] = result[WIDTH-1:0];
	      setcc(op1, op2, result, 0);
	   end
	   `AND: begin
	      if(`IMM_OP == 0)
		op2 = R[`rs2];
	      else
		op2 = sext16(`immed16);
	      op1 = R[`rs1];
	      result = op1 & op2;
	      R[`rdst] = result[WIDTH-1:0];
	   end
	   `XOR: begin
              if(`IMM_OP == 0)
                op2 = R[`rs2];
              else
                op2 = sext16(`immed16);
	      op1 = R[`rs1];
	      result = op1 ^ op2;
              R[`rdst] = result[WIDTH-1:0];
	   end
	   `BXX: begin
              if(checkcc(Z,C,N,V) == 1)
		PC = PC + sext23(`immed23);
	      
	   end

	   `CMP: begin
	      if(`IMM_OP == 0)
		op2 = R[`rs2];
	      else
		op2 = sext16(`immed16);
	      op1 = R[`rs1];
	      result = op1 - op2;
	      setcc(op1, op2, result, 1);
	   end

	   `HLT: begin
	      RUN = 0;
	   end

	   `JMP: begin
	      if(`IMM_OP == 1)
		R[`rdst] = PC;
	      PC = R[`rsl] + sext16(`immed16);
	   end

	   `LD: begin
	      R[`rdst] = read_mem(sext22(`immed22));
	   end

	   `LDI: begin
	      R[`rdst] = sext22(`immed22);
	   end

	   `LDX: begin
              R[`rdst] = read_mem(R[`rsl] + sext17(`immed22));
           end

	   `NOP: begin
	   end

	   `NOT: begin
	      `opl = R[`rsl];
	      result = `opl;
	      R['rdst] = result[WIDTH - 1 : 0];
	   end

	   `OR: begin
	      if(`IMM_OP == 0)
		op2 = R[`rs2];
	      else
		op2 = sext16(`immed16);
	      op1 = R[`rs1];
	      result = op1 | op2;
	      R[`rdst] = result[WIDTH - 1 : 0];
	   end

	   `ST: begin
	      write_mem(sext22(`immed22), R[`rst]);
	   end

	   `SUB: begin
	      if(`IMM_OP == 0)
		op2 = R[`rs2];
	      else
		op2 = sext16(`immed16);
	      op1 = R[`rsl];
	      result = op1 - op2;
	      R['rdst] = result[WIDTH - 1 : 0];
	      setcc(op1, op2, result, 1);
	   end

	   default: begin
	      $display("Error: undefined opcode: %d", OPCODE);
	   end

	 endcase // case (`OPCODE)
      end
   endtask // execute

   function [WIDTH - 1: 0] sext16;
      input [15 : 0] d_in;
      sext16[WIDTH - 1: 0] = {{(WIDTH - 16){d_in[15]}}, d_in};
   endfunction // sext16

   task write_mem;
      input [WIDTH - 1 : 0] addr;
      input [WIDTH - 1 : 0] data;

      begin
	 {MEM[addr], MEM[addr + 1], MEM[addr + 2], MEM[addr + 3]} = data;
      end
      
   endtask // write_mem

   task setcc;
      input [WIDTH - 1: 0] op1;
      input [WIDTH - 1 : 0] op2;
      input [WIDTH : 0]     result;
      input 		    subt;

      begin
	 C = result[WIDTH];
	 Z = ~(|result[WIDTH - 1: 0]);
	 N = result[WIDTH - 1];

	 V = (result[WIDTH - 1] & ~op1[WIDTH - 1] & ~op2[WIDTH - 1]) | (~result[WIDTH - 1] & op1[WIDTH - 1] & op2[WIDTH - 1]);
      end
   endtask // setcc

   function checkcc;
      input Z;
      input C;
      input N;
      input V;

      begin
	 case(`COND)

	   `BRA: begin
	      checkcc = 1;
	   end

	   `BNV: begin
	      checkcc = 0;
	   end

	   `BCC: begin
	      checkcc = ~C;

	   `BCS: begin
	      checkcc = C;
	   end

	   `BVC: begin
	      checkcc = ~V;
	   end

	   `BVS: begin
	      checkcc = V;
	   end

	   `BEQ: begin
	      checkcc = Z;
	   end

	   `BNE: begin
	      checkcc = ~Z;
	   end

	   `BGE: begin
	      checkcc = (~N & ~V) | (N & V);
	   end

	   `BLT: begin
	      checkcc = (N & ~V) | (~N & V);
	   end

	   `BGT: begin
	      checkcc = ~Z & ((~N & ~V) | (N & V));
	   end

	   `BLE: begin
	      checkcc = Z | ((N & ~V) | (~N & V));
	   end

	   `BMI: begin
	      checkcc = N;
	   end

	 endcase // case (`COND)
      end
   endfunction // checkcc

   task print_trace;
      integer i;
      integer j;
      integer k;

      begin
`ifdef TRACE_PC
	 begin
	    $display("Instruction #: %d\tPC=%h\tOPCODE=%d", num_instrs, PC,`OPCODE);
	 end // UNMATCHED !!
`endif
`ifdef TRACE_CC
	 begin
	    $display("Condition codes: C=%b V=%b Z=%d N=%b",C,V,Z,N);
	 end // UNMATCHED !!
`endif
`ifdef TRACE_REGS
	 begin
	    k = 0;
	    for(i = 0; i < NUMREGS; i = i + 4)
	      begin
		 $write("R[%d]: ", k);
		 for(j = 0; j <= 3; j = j + 1)
		   begin
		      $write(" %h", R[k]);  
		      k = k + 1;
		   end
		 $write("\n");
	      end
	    $write("\n");
	 end // UNMATCHED !!
`endif //  `ifdef TRACE_REGS
      end
   endtask // print_trace
   
endmodule // vespa

	 
