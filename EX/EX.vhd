--contains exec unit, mux for RegDst
--Exec unit contains ALU and branch adder
library ieee;
use ieee.std_logic_1164.all;

entity EX_unit is
port
(	
	Immediate32_in : in std_logic_vector(31 downto 0); --from ID_EX reg, fed to extender
	
	Ra_in, Rb_in : in std_logic_vector(31 downto 0); --from ID_EX reg
	
	Rt_in, Rd_in : in std_logic_vector(4 downto 0); --from ID_EX reg, into a mux selected by RegDst
	Rw_out : out std_logic_vector(4 downto 0); --fed to EX_MEM reg and then MEM_WR for writeback
	
	shamt_in : in std_logic_vector(4 downto 0);
	Func_in : in std_logic_vector(5 downto 0);
	
	ALUout_out : out std_logic_vector(31 downto 0);
	
	JumpReg : out std_logic;
	
	--Control signals
	ExtOp : in std_logic;
	ALUop : in std_logic_vector(2 downto 0); --selects aluop for ALUcontrol with func_in
	ALUSrc : in std_logic; --selects immediate or Rt
	RegDst : in std_logic; --destination register selector
	JAL_in : in std_logic
);
end EX_unit;

architecture arch of EX_unit is

signal ALU_control : std_logic_vector(3 downto 0);
signal input_b : std_logic_vector(31 downto 0);
signal shamt : std_logic_vector(4 downto 0);
signal LUI : std_logic;
signal shdir : std_logic;
signal Immediate32 : std_logic_vector(31 downto 0);
signal Rw_Sel : std_logic_vector(1 downto 0);

begin
	ALU_CONTROL_U: entity work.alu32control --alu control
	port map
	(
		 func    => func_in,
	     ALUop   => ALUop,
	     control => ALU_control,
	     LUI	 => LUI,
	     shdir   => shdir,
	     JumpReg => JumpReg
	);
	
	process(Immediate32_in,ExtOp) --zero extend or sign extend, this is a giant and gate with extop on the upper 16 bits of immediate
	variable input_b_upper : std_logic_vector(31 downto 16);
	begin
		for i in 31 downto 16 loop
			input_b_upper(i) := Immediate32_in(i) and ExtOp;
		end loop;
		Immediate32 <= input_b_upper & Immediate32_in(15 downto 0);
	end process;
	
	input_b <= Rb_in when ALUSrc = '0' else --alu input b selection mux for immediates
			   immediate32;		
			   
	shamt <= shamt_in when LUI = '0' else --shamt input selection mux (for LUI)
			 "10000"; --shift by 16 for lui
	
	ALU: entity work.alu32 --the 32 bit alu
	generic map(WIDTH => 32)
	port map
	(
		 ia      => Ra_in,
	     ib      => input_b,
	     control => ALU_control,
	     shamt   => shamt,
	     shdir   => shdir,
	     o       => ALUout_out
	);
	
	Rw_Sel <= RegDst & JAL_in;
	
	with Rw_Sel select --select where Rw is, Rt/Rd/31
	Rw_out <= Rd_in when "10",
		      Rt_in when "00",
		      "11111" when others;
end architecture arch;
