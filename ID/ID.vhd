--contains regfile and jump/jumpReg feedback to IF stage
library ieee;
use ieee.std_logic_1164.all;

entity ID_unit is
port
(
	clk,rst : in std_logic;
	Rs,Rt : in std_logic_vector(4 downto 0); --from IF_ID reg
	
	Rw : in std_logic_vector(4 downto 0); --from WR stage
	Di : in std_logic_vector(31 downto 0);
	
	opcode : in std_logic_vector(5 downto 0); --from IF_ID register
	
	Reg_Wr : in std_logic; --control signal sent back from MEM_WR register
	
	Ra_out,Rb_out : out std_logic_vector(31 downto 0);
	
	Immediate26_in : in std_logic_vector(25 downto 0);
	Immediate32_out : out std_logic_vector(31 downto 0);
	
	PC_inc_in : in std_logic_vector(29 downto 0);
	PC_inc_Branch_out : out std_logic_vector(31 downto 0);
	
	Branch_and_Zero_out : out std_logic;
	
	--signals output from controller to ID_EX_REG
	ALUsrc : out std_logic;
	MemWr : out std_logic;
	byte_enable : out std_logic_vector(3 downto 0);
	MemtoReg : out std_logic;
	RegWr : out std_logic;
	RegDst : out std_logic;
	JAL : out std_logic;
	ALUop : out std_logic_vector(2 downto 0);
	ExtOp : out std_logic;
	
	--signals output directly to IF stage
	Jump : out std_logic
);
end ID_unit;

architecture arch of ID_unit is
	
signal immediate_branch_add : std_logic_vector(29 downto 0);
signal immediate16 : std_logic_vector(15 downto 0);
signal immediate32 : std_logic_vector(31 downto 0);
signal Ra,Rb : std_logic_vector(31 downto 0);
signal Zero_Invert : std_logic;
signal Zero : std_logic;
signal Branch : std_logic;
signal PC_inc_Branch : std_logic_vector(29 downto 0);
	
begin
	REGISTER_FILE: entity work.registerFile
	generic map
	(
		WIDTH        => 32,
        NUMREGISTERS => 32
    )
	port map
	(
		 rr0 => Rs,
	     rr1 => Rt,
	     rw  => Rw,
	     q0  => Ra,
	     q1  => Rb,
	     d   => Di,
	     wr  => Reg_Wr,
	     clk => clk,
	     clr => rst
	);
	
	CONTROLLER_U: entity work.controller
	port map
	(
		 opcode      => opcode,
	     RegDst      => RegDst,
	     ExtOp       => ExtOp,
	     ALUSrc      => ALUSrc,
	     MemtoReg    => MemtoReg,
	     RegWr       => RegWr,
	     MemWr       => MemWr,
	     Branch      => Branch,
	     Jump        => Jump,
	     Z_Invert    => Zero_Invert,
	     JAL         => JAL,
	     ALUop		 => ALUop,
	     byteena     => byte_enable
	);
	
	immediate16 <= Immediate26_in(15 downto 0);
	
	SIGNED_IMMEDIATE_EXTENDER: entity work.signext --signed immediate extender for branches
	generic map
	(
		WIDTH_IN  => 16,
        WIDTH_OUT => 32
    )
	port map
	(
		 in0  => immediate16,
	     out0 => immediate32
	);
	
	
	immediate_branch_add <= immediate32(29 downto 0); --MS 30 bits
	
	BRANCH_ADDER: entity work.adder_gen(numeric_std) --add them to PC_inc for branching
	generic map(WIDTH => 30)
	port map
	(
		 a      => PC_inc_in,
	     b      => immediate_branch_add,
	     cin    => '0',
	     output => PC_inc_Branch
	);
	
	XNOR_A_B: process(Ra,Rb,Zero_Invert) --equivalence check for Zero and inversion if necessary
	variable temp : std_logic;	
	begin
		temp := '1';
		for i in Ra'range loop
			temp := temp and (Ra(i) xnor Rb(i));
		end loop;
		
		if(Zero_Invert = '0') then
			Zero <= temp;
		else 
			Zero <= not temp;
		end if;
	end process;	
	
	Immediate32_out <= immediate32;
	Ra_out <= Ra;
	Rb_out <= Rb;
	
	Branch_and_Zero_out <= Branch and Zero;
	PC_inc_Branch_out <= PC_inc_Branch & "00";
end architecture arch;
