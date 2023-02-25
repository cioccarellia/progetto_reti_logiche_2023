----------------------------------------------------------------------------------
-- Students: Alberto Cantele (10766393), Andrea Cioccarelli (10713858)
-- Create Date: 02/20/2023 11:36:44 AM
----------------------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity project_reti_logiche is
    port(
        i_clk:          in  std_logic;
        i_rst:          in  std_logic;
        i_start:        in  std_logic;
        i_w:            in  std_logic;
        
        o_z0:           out std_logic_vector(7  downto 0);
        o_z1:           out std_logic_vector(7  downto 0);
        o_z2:           out std_logic_vector(7  downto 0);
        o_z3:           out std_logic_vector(7  downto 0);
        o_done:         out std_logic;
        
        o_mem_addr:     out std_logic_vector(15 downto 0);
        i_mem_data:     in  std_logic_vector(7  downto 0);
        o_mem_we:       out std_logic;
        o_mem_en:       out std_logic
    );
end project_reti_logiche;


architecture proj_impl of project_reti_logiche is
        

    type fsm_main_state is (
        RESET,
        WAIT_START,
        ACQUIRE_SEL_BIT_1, ACQUIRE_SEL_BIT_2, ACQUIRE_ADDR_BIT_N,
        ASK_MEM, 
        OUTPUT_Z
    );
    signal fsm_next_state, fsm_current_state: fsm_main_state;


    signal control_output:          std_logic_vector(1  downto 0);
    signal control_address:         std_logic_vector(15 downto 0);


    signal r_z0: std_logic_vector(7 downto 0);
    signal r_z1: std_logic_vector(7 downto 0);
    signal r_z2: std_logic_vector(7 downto 0);
    signal r_z3: std_logic_vector(7 downto 0);
    
    signal has_read_1_sel_bit: std_logic := '0';
    signal has_read_2_sel_bit: std_logic := '0';
    
begin
    
    sync_fsm: process(i_clk, i_rst, fsm_next_state)
    begin
        if (i_rst = '1') then
            fsm_current_state <= RESET;
        elsif (i_clk'event and i_clk = '1') then
            fsm_current_state <= fsm_next_state;
        end if;
    end process sync_fsm;
    


    comb_fsm: process(fsm_current_state, i_start, i_w, i_mem_data)
    begin
        -- pre-setting outputs
        o_z0 <= "00000000";
        o_z1 <= "00000000";
        o_z2 <= "00000000";
        o_z3 <= "00000000";

        o_done <= '0';

        o_mem_addr <= "0000000000000000";
        o_mem_en <= '0';
        o_mem_we <= '0';


        case fsm_current_state is
            when WAIT_START =>
                if i_start='1' then
                    -- init control output sel
                    control_output <= "00";
                    control_address <= (others => '0');
                    
                    control_output(1) <= i_w;
                    has_read_1_sel_bit <= '1';
                    fsm_next_state <= ACQUIRE_SEL_BIT_2;
                end if;
    
            when ACQUIRE_SEL_BIT_1 =>
                control_output(1) <= i_w;
                has_read_1_sel_bit <= '1';
                fsm_next_state <= ACQUIRE_SEL_BIT_2;

            when ACQUIRE_SEL_BIT_2 =>
                if (has_read_2_sel_bit = '0') then
                    has_read_2_sel_bit <= '1';
                    control_output(0) <= i_w;
                    fsm_next_state <= ACQUIRE_ADDR_BIT_N;
                end if;

            when ACQUIRE_ADDR_BIT_N =>
                if (i_start = '0') then
                    fsm_next_state <= ASK_MEM;
                else
                    control_address <= control_address(14 downto 0) & i_w; -- & concatena, and è logica
                    control_address(0) <= i_w;
                    fsm_next_state <= ACQUIRE_ADDR_BIT_N;
                
                end if;
            when ASK_MEM =>
                -- la RAM ci mette 1cc per recuperare il valore, e poi assumo di avere il dato su i_mem_data
                o_mem_en <= '1';
                fsm_next_state <= OUTPUT_Z;
    
            when OUTPUT_Z =>
                o_done <= '1';

                case (control_output) is
                    when "00" =>
                        o_z0 <= i_mem_data;
                        o_z1 <= r_z1;
                        o_z2 <= r_z2;
                        o_z3 <= r_z3;
                    when "01" =>
                        o_z0 <= r_z0;
                        o_z1 <= i_mem_data;
                        o_z2 <= r_z2;
                        o_z3 <= r_z3;
                    when "10" =>
                        o_z0 <= r_z0;
                        o_z1 <= r_z1;
                        o_z2 <= i_mem_data;
                        o_z3 <= r_z3;
                    when others =>          -- "11" =>
                        o_z0 <= r_z0;
                        o_z1 <= r_z1;
                        o_z2 <= r_z2;
                        o_z3 <= i_mem_data;
                end case;

                -- o_z0 <= r_z0;
                -- o_z1 <= r_z1;
                -- o_z2 <= r_z2;
                -- o_z3 <= r_z3;

                -- loop back
                fsm_next_state <= WAIT_START;

            when OTHERS =>
                r_z0 <= "00000000";
                r_z1 <= "00000000";
                r_z2 <= "00000000";
                r_z3 <= "00000000";
                
                has_read_1_sel_bit <= '0';
                has_read_2_sel_bit <= '0';
                
                control_output <= "00";
                control_address <= (others => '0');

                fsm_next_state <= WAIT_START;
        end case;
    end process comb_fsm;
    

end proj_impl;
