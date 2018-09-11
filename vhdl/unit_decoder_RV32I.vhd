----------------------------------------------------------------------------------
-- Project Name:  RISC-V CPU
-- Description: decoder unit RV32I
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity decoder_RV32 is
    Port ( 
        I_clk    : in STD_LOGIC;
        I_en : in  STD_LOGIC;
        I_dataInst : in  STD_LOGIC_VECTOR (31 downto 0); -- Instruction to be decoded
        O_selRS1 : out  STD_LOGIC_VECTOR (4 downto 0);   -- Selection out for regrs1
        O_selRS2 : out  STD_LOGIC_VECTOR (4 downto 0);   -- Selection out for regrs2
        O_selD : out  STD_LOGIC_VECTOR (4 downto 0);     -- Selection out for regD
        O_dataIMM : out  STD_LOGIC_VECTOR (31 downto 0); -- Immediate value out
        O_regDwe : out  STD_LOGIC;                       -- RegD wrtite enable
        O_aluOp : out  STD_LOGIC_VECTOR (6 downto 0);    -- ALU opcode
        O_aluFunc : out STD_LOGIC_VECTOR (15 downto 0);  -- ALU function
        O_memOp : out STD_LOGIC_VECTOR(4 downto 0)       -- Memory operation 
    );
end decoder_RV32;

architecture Behavioral of decoder_RV32 is
begin
  -- Register selects for reads are async
	O_selRS1 <= I_dataInst(R1_START downto R1_END);
	O_selRS2 <= I_dataInst(R2_START downto R2_END);
	
	process (I_clk, I_en)
	begin
		if rising_edge(I_clk) and I_en = '1' then
		
      O_selD <= I_dataInst(RD_START downto RD_END);
        
      O_aluOp <= I_dataInst(OPCODE_START downto OPCODE_END);
            
      O_aluFunc <= "000000" & I_dataInst(FUNCT7_START downto FUNCT7_END) 
                       & I_dataInst(FUNCT3_START downto FUNCT3_END);

			case I_dataInst(OPCODE_START downto OPCODE_END_2) is
			  when OPCODE_LUI =>
				 O_regDwe <= '1';
				 O_memOp <= "00000";
				 O_dataIMM <= I_dataInst(IMM_U_START downto IMM_U_END) 
								& "000000000000";
			  when OPCODE_AUIPC =>
				 O_regDwe <= '1';
				 O_memOp <= "00000";
				 O_dataIMM <= I_dataInst(IMM_U_START downto IMM_U_END) 
								& "000000000000";
			  when OPCODE_JAL =>
			    if I_dataInst(RD_START downto RD_END) = "00000" then 
					O_regDwe <= '0';
				 else
					O_regDwe <= '1';
				 end if;
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= "111111111111" & I_dataInst(19 downto 12) & I_dataInst(20) & I_dataInst(30 downto 21) & '0';
				 else
					O_dataIMM <= "000000000000" & I_dataInst(19 downto 12) & I_dataInst(20) & I_dataInst(30 downto 21) & '0';
				 end if;
			  when OPCODE_JALR =>
			    if I_dataInst(RD_START downto RD_END) = "00000" then 
					O_regDwe <= '0';
				 else
					O_regDwe <= '1';
				 end if;
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
				 end if;
			  when OPCODE_OPIMM => 
				 O_regDwe <= '1';
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
				 end if;
			  when OPCODE_LOAD => 
				 O_regDwe <= '1';
			    O_memOp <= "10" & I_dataInst(FUNCT3_START downto FUNCT3_END);
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
				 end if;
			  when OPCODE_STORE => 
				 O_regDwe <= '0';
			    O_memOp <= "11" & I_dataInst(FUNCT3_START downto FUNCT3_END);
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_S_A_START downto IMM_S_A_END) & I_dataInst(IMM_S_B_START downto IMM_S_B_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_S_A_START downto IMM_S_A_END) & I_dataInst(IMM_S_B_START downto IMM_S_B_END);
				 end if;
			  when OPCODE_BRANCH => 
				 O_regDwe <= '0';
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(7) & I_dataInst(30 downto 25) & I_dataInst(11 downto 8) & '0';
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(7) & I_dataInst(30 downto 25) & I_dataInst(11 downto 8) & '0';
				 end if;
				when OPCODE_MISCMEM => 
					O_regDwe <= '0';
				  O_memOp <= "01000";
					O_dataIMM <= I_dataInst;
				when others =>
				   O_memOp <= "00000";
					O_regDwe  <= '1';
				   O_dataIMM <= I_dataInst(IMM_I_START downto IMM_S_B_END) 
									& "0000000";
			end case;
		end if;
	end process;

end Behavioral;
