----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/20/2023 11:36:44 AM
-- Design Name: 
-- Module Name: 10766393_10713858 - Behavioral
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

entity project_reti_logiche is
--  Port ( );
    Port(
    i_clk: in std_logic;
    i_rst: in std_logic;
    i_start: in std_logic;
    i_w:in std_logic;
    
    o_z0: out std_logic_vector(7 downto 0);
    o_z1: out std_logic_vector(7 downto 0);
    o_z2: out std_logic_vector(7 downto 0);
    o_z3: out std_logic_vector(7 downto 0);
    o_done: out std_logic;
    
    o_mem_addr: out std_logic_vector(15 downto 0);
    i_mem_data: in std_logic_vector(7 downto 0);
    o_mem_we: out std_logic;
    o_mem_en: out std_logic
    );
end  project_reti_logiche;

architecture Behavioral of  project_reti_logiche is
    type S is (WAIT_START, READ_ADDR,ASK_MEM,OUTPUT);
    
    signal current_state: S;
    signal Current_out_z0: std_logic_vector(7 downto 0);
    signal Current_out_z1: std_logic_vector(7 downto 0);
    signal Current_out_z2: std_logic_vector(7 downto 0);
    signal Current_out_z3: std_logic_vector(7 downto 0);
    signal Control: std_logic_vector(1 downto 0);
  

begin
--/////////////////////////////////////////////////Finite State Machine per Regolare lo stato del programma al variare di reset, clock e start
  fsm: process(i_clk, i_rst)
  begin
    if i_rst='1' then
        current_state <= WAIT_START;
        Current_out_z0<="00000000";
        Current_out_z1<="00000000";
        Current_out_z2<="00000000";
        Current_out_z3<="00000000";
        o_done <= '0';
        o_z0 <= "00000000";
        o_z1 <= "00000000";
        o_z2 <= "00000000";
        o_z3 <= "00000000";
        
    elsif i_clk'event and i_clk='1' then
        case current_state is
            when WAIT_START =>
                if i_start='1' then
                    current_state <= READ_ADDR;
                end if;
            when READ_ADDR =>
                if i_start='0' then
                    current_state <= ASK_MEM;
                end if;
            when ASK_MEM =>
                current_state <= OUTPUT;
            when OUTPUT =>
                current_state <= WAIT_START;
        end case;
    end if;
  end process;
  --/////////////////////////////////////////////////Finite State Machine per OUTPUT
    fsm_output: process(current_state)
    begin
        case current_state is
            when WAIT_START | READ_ADDR | ASK_MEM =>
                o_done <= '0';
                o_z0 <= "00000000";
                o_z1 <= "00000000";
                o_z2 <= "00000000";
                o_z3 <= "00000000";
            when OUTPUT =>
                o_done<='1';
                        o_z0 <= current_out_z0;
                        o_z1 <= current_out_z1;
                        o_z2 <= current_out_z2;
                        o_z3 <= current_out_z3;
           end case;
    end process;
 --/////////////////////////////////////////////////Finite State Machine per scansione dell'input e letura in memoria
    fsm_scan_read: process(current_state)
    begin
        case current_state is
            when WAIT_START =>
            when READ_ADDR =>
--implementazione multiplexer scelta del canale di uscita 
                if i_clk'event and i_clk='1' then
                    Control(1) <= i_w;
                end if;
                
                if i_clk'event and i_clk='1' then
                    Control(0) <= i_w;
                end if;
                
--estensione del vettore a 16 bit


                

-- abilitazione lettura in memoria

--lettura in memoria e acquisizione dato               
            when ASK_MEM =>
            when OUTPUT =>
           end case;
    end process;   
end Behavioral;
