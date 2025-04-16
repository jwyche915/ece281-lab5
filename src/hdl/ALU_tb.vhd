----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/15/2025 02:34:54 PM
-- Design Name: 
-- Module Name: ALU_tb - Behavioral
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

entity ALU_tb is
end ALU_tb;

architecture Behavioral of ALU_tb is
    -- declare component to be tested
    component ALU is
    Port (  i_A : in std_logic_vector (7 downto 0);
            i_B : in std_logic_vector (7 downto 0);
            i_op : in std_logic_vector (2 downto 0);
            o_result : out std_logic_vector (7 downto 0);
            o_flags : out std_logic_vector (2 downto 0)
    );
    end component ALU;
    
    -- test signals
    signal w_A : std_logic_vector (7 downto 0);
    signal w_B : std_logic_vector (7 downto 0);
    signal w_op : std_logic_vector (2 downto 0);
    signal w_result : std_logic_vector (7 downto 0);
    signal w_flags : std_logic_vector (2 downto 0);

begin
    -- PORT MAP --------------------------------------------
    ALU_inst : ALU
    port map (
        i_A => w_A,
        i_B => w_B,
        i_op => w_op,
        o_result => w_result,
        o_flags => w_flags
    );
    
    test_process : process
    begin
        w_A <= x"05";
        w_B <= x"04";
        w_op <= "000";  -- add operation
        wait for 20 ns;
        
        w_op <= "001";  -- subtract operation
        wait for 20 ns;
        
        wait; 
    end process test_process;


end Behavioral;
