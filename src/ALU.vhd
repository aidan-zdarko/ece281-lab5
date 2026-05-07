----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    
    signal result               : unsigned(8 downto 0) := (others => '0'); -- need the extra bit for any carry if necessary
    signal RegisterA, RegisterB : unsigned(8 downto 0) := (others => '0');
    signal result_output        : std_logic_vector(7 downto 0);
    
begin

    -- make the numbers signed from register
    RegisterA <= unsigned('0' & i_A); -- the and with the 0 makes the 8 bits into 9 bits
    RegisterB <= unsigned('0' & i_B); -- this is needed for taking the unsigned for flag then taking
                                      -- the signed version
    
    with i_op select
    -- Doc statement: used *blank* for the ('0' and R), says this expands the bit by one bit which is waht i need for the flags
        result <= (RegisterA) + (RegisterB)     when "000",
                  (RegisterA) - (RegisterB)     when "001",
                  ('0' & unsigned(i_A and i_B))   when "010", -- expand these to 9 bit AFTER
                  ('0' & unsigned(i_A or i_B))    when "011", -- the operation with unsigned
                  (others => '0')           when others;
    
    -- make the result the 8 bit result, drop the carry bit (Used https://fpgatutorial.com/vhdl-types-and-conversions/)
    -- Doc statement: used FPGA Tutorial on vectors to see how to take the 8 bit vector of a 9 bit number              
    o_result <= std_logic_vector(result(7 downto 0)); 
    
    
    o_flags(3) <= result(7); -- negative sign
    o_flags(2) <= '1' when result(7 downto 0) = 0 else '0'; -- zero (at all bits)
    o_flags(1) <= result(8) when (i_op = "000") else 
                  not result(8) when (i_op = "001") else
                  '0'; -- carry
    -- overflow is whether the signs are the same and get a different signed answer. different for addition/subtraction           
    o_flags(0) <= ((i_A(7) xnor i_B(7)) and (i_A(7) xor result(7))) when i_op = "000" else
                  ((i_A(7) xor i_B(7)) and (i_A(7) xor result(7))) when i_op = "001" else 
                  '0';           
end Behavioral;
