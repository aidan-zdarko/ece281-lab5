----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_clk   : in STD_LOGIC;
           i_reset : in STD_LOGIC;
           i_adv   : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    type stage is (resetStage, LoadRA, LoadRB, Display);
    
    signal currentStage, nextStage, resetS: stage;
    
begin
    
    nextStage <= currentStage   when (i_adv = '0') else
                 LoadRA         when (currentStage = resetStage) else
                 LoadRB         when (currentStage = LoadRA) else
                 Display        when (currentStage = LoadRB) else
                 resetStage     when (currentStage = Display) else
                 resetStage;
               
    with currentStage select
    o_cycle <= "0001" when resetStage,
               "0010" when LoadRA,
               "0100" when LoadRB,
               "1000" when Display,
               "0001" when others;
    
    state_register : process(i_clk)
	begin
        if rising_edge(i_clk) then
           if i_reset = '1' then
               currentStage <= resetStage;
           else
                currentStage <= nextStage;
            end if;
        end if;
	end process state_register;
	
end FSM;
