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

    --| Main FSM status definition. 
    --|
    --| There are 4 possible states:
    --| - WAIT_START:   Idling state, we wait for the i_start signal to go high;
    --| - ACQUIRE_ADDR: Reading input i_w and splitting the received data in:
    --|                     - 2 initial  for demux control (output selection);
    --|                     - up to 16 bits for memory address.
    --| - ASK_MEM:      Sending the received address to RAM and waiting for the response on i_mem_data;
    --| - OUTPUT:       Enabling output, relaying the new data and the existing state to z0 through z3.
    type fsm_main_state is (WAIT_START, ACQUIRE_ADDR, ASK_MEM, OUTPUT);
    signal fsm_main_next_state, fsm_main_current_state: fsm_main_state;



    --| Acquisition FSM status definition. This is a sub-fsm that is supposed to run when fsm_main_state = ACQUIRE_ADDR,
    --| Its purpose is to acquire the address, store its components bit by bit and then switch to ASK_MEM, where the
    --| acquired address is passed to memory.
    --|
    --| There are three states:
    --| - S0: Reading first demux-control bit;
    --| - S1: Reading second demux-control bit;
    --| - S_READ: Reading address.
    type fsm_acquiring_state is (S0, S1, S_READ);
    signal fsm_acquiring_current_state, fsm_acquiring_next_state: fsm_acquiring_state;



    --| Support signals for acquisition state
    signal control_output:          std_logic_vector(1  downto 0);
    signal control_address:         std_logic_vector(15 downto 0);
  

begin


    sync_main_fsm: process(i_clk, i_rst, fsm_main_next_state)
    begin 
        if (i_rst='1') then
            --------| reset di tutti i segnali al loro vaalore iniziale
            --| impostiamo i segnali e gli stati
            fsm_main_current_state <= WAIT_START;       -- stato iniziale di wait for start

            control_output <= "00";                     -- 2  bits of zeros
            control_address <= (others => '0');         -- 16 bits of zeros

            --------| impostiamo le uscite al loro valore di default
            o_mem_addr <= (others => '0');              -- 16 bits of zeros
            o_mem_en <= '0';
            o_mem_we <= '0';

            o_done <= '0';
            o_z0 <= "00000000";
            o_z1 <= "00000000";
            o_z2 <= "00000000";
            o_z3 <= "00000000";

        elsif (rising_edge(i_clk)) then  
            fsm_main_current_state <= fsm_main_next_state;
        end if;
     end process;
               
     
     

    comb_main_fsm: process(fsm_main_current_state)
        begin
        -- pre-setting outputs          
        o_mem_en <= '0';
        o_mem_we <= '0';

        o_done <= '0';
        o_z0 <= "00000000";
        o_z1 <= "00000000";
        o_z2 <= "00000000";
        o_z3 <= "00000000";
        
        
        case fsm_main_current_state is
            when WAIT_START =>
                if i_start='1' then
                    fsm_main_next_state <= ACQUIRE_ADDR;
                end if;
    
            when ACQUIRE_ADDR =>
                if i_start='0' then
                    fsm_main_next_state <= ASK_MEM;
                end if;
    
            when ASK_MEM =>
                -- la RAM ci mette 1cc per recuperare il valore, e poi assumo di avere il dato su i_mem_data
                o_mem_en <= '1';
                fsm_main_next_state <= OUTPUT;
    
            when OUTPUT =>
                --!!FIXME!! probabilmente è meglio impostare questo direttamente in fsm_output, e non qui, perchè non ci metto solo 1cc
                fsm_main_next_state <= WAIT_START;
        end case;
    end process;
             







    ---- FSM per scansione dell'input e letura in memoria
    sync_acquiring_fsm: process(i_clk, i_rst, fsm_acquiring_next_state)
        begin 
        if (i_rst='1') then
            --------| reset di tutti i segnali al loro vaalore iniziale
            --| impostiamo i segnali e gli stati
            fsm_acquiring_current_state <= S0;                -- stato iniziale di wait for start

        elsif (rising_edge(i_clk)) then  
            fsm_acquiring_current_state <= fsm_acquiring_next_state;
         end if;
     end process;
    
    
    
    comb_acquiring_fsm: process(fsm_acquiring_current_state)
    begin
        case fsm_main_current_state is
            when WAIT_START =>
                control_address <= (others => '0');

            when ACQUIRE_ADDR =>
                case fsm_acquiring_current_state is
                    when S0 =>
                        control_output(1) <= i_w;
                        fsm_acquiring_next_state <= S1;

                    when S1 =>    
                        control_output(0) <= i_w;
                        fsm_acquiring_next_state <= S_READ;

                    when S_READ =>
                        -- Estensione del vettore a 16 bit: shifto a sx 15 bit in and con i_w
                        control_address <= control_address(14 downto 0) & i_w; -- & concatena, and è logica
                        control_address(0) <= i_w;
                        
                        fsm_acquiring_next_state <= S_READ;
                end case;
                
            when ASK_MEM =>
                -- setto l'indirizzo di ingrsso alla RAM
                o_mem_addr <= control_address;
            when OUTPUT =>
        end case;
    end process;   
    
    
    
    
    
    
    
    
    
    output_process: process(fsm_main_current_state, i_rst)
        variable reg_z0_contents : std_logic_vector(7 downto 0) := "00000000";
        variable reg_z1_contents : std_logic_vector(7 downto 0) := "00000000";
        variable reg_z2_contents : std_logic_vector(7 downto 0) := "00000000";
        variable reg_z3_contents : std_logic_vector(7 downto 0) := "00000000";
    begin
        if (i_rst = '1') then
            reg_z0_contents := "00000000";
            reg_z1_contents := "00000000";
            reg_z2_contents := "00000000";
            reg_z3_contents := "00000000";
        else
            case fsm_main_current_state is
                when WAIT_START | ACQUIRE_ADDR | ASK_MEM =>
                    o_done <= '0';
    
                    o_z0 <= "00000000";
                    o_z1 <= "00000000";
                    o_z2 <= "00000000";
                    o_z3 <= "00000000";
    
                when OUTPUT =>
                    o_done <= '1';
                    
                    -- demux-ing the new data
                    case (control_output) is
                        when "00" =>
                            reg_z0_contents := i_mem_data;
                        when "01" =>
                            reg_z1_contents := i_mem_data;
                        when "10" =>
                            reg_z2_contents := i_mem_data;
                        when others =>
                            reg_z3_contents := i_mem_data;
                    end case;

                    
                    -- register propagation
                    o_z0 <= reg_z0_contents;
                    o_z1 <= reg_z1_contents;
                    o_z2 <= reg_z2_contents;
                    o_z3 <= reg_z3_contents;
            end case;
        end if;
    end process;

    
end proj_impl;
