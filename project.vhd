----------------------------------------------------------------------------------
-- Students: Alberto Cantele (10766393), Andrea Cioccarelli (10713858)
-- Create Date: 02/20/2023 11:36:44 AM
----------------------------------------------------------------------------------


----------------------------------------------------------------------------------
--|
--|  project_reti_logiche
--|
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

   


    --| Stato della FSM che modella l'esecuzione del processo.
    --| Ci sono 4 stati possibili: 
    --| - WAIT_START: Stato di idle
    --| - READ_ADDR: Si legge bit per bit l'ingresso w e si salva il valore
    --| - ASK_MEM: Si inviano i segnali alla RAM e si aspetta perche processi la richiesta, 1cc
    --| - OUTPUT: Fase di output, 1cc
    type MAIN_FSM_S is (WAIT_START, READ_ADDR, ASK_MEM, OUTPUT);
    signal MAIN_FSM_next_state, MAIN_FSM_current_state: MAIN_FSM_S;



    --| Stato della FSM che modella la lettura del segnale di controllo output e dell'indirizzo di memoria.
    --| - S0: Lettura del primo bit di controllo uscita
    --| - S1: Lettura del secondo bit di controllo uscita
    --| - S_READ: Lettura dei singoli bit dell'indirizzo
    type ACQUIRINIG_FSM_S is (S0, S1, S_READ);
    signal ACQUIRING_FSM_current_state, ACQUIRING_FSM_next_state: ACQUIRINIG_FSM_S;



    --| Segnali di supporto alla lettura dell indirizzo di ingresso
    signal control_output:          std_logic_vector(1  downto 0);
    signal control_address:         std_logic_vector(15 downto 0);
  

begin

 
    


    --| FSM per gestire lo stato del programma al variare dei segnali di clock (i_clk) e reset (i_rst)
    --| Si occupa di ricevere il segnale di reset (i_rst) ed impostare i valori allo stato iniziale
    --| Inoltre, fa commutare gli stati
    sync_MAIN_FSM: process(i_clk, i_rst, MAIN_FSM_next_state)
    begin 
        if (i_rst='1') then
            --------| reset di tutti i segnali al loro vaalore iniziale
            --| impostiamo i segnali e gli stati
            MAIN_FSM_current_state <= WAIT_START;                -- stato iniziale di wait for start

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
            MAIN_FSM_current_state <= MAIN_FSM_next_state;
         end if;
     end process;
     
     
     
     
    comb_MAIN_FSM: process(MAIN_FSM_current_state)
        begin
        --------| Inizialmente imposto i valori di uscita a default
        --o_mem_addr <= (others => '0');              
        o_mem_en <= '0';
        o_mem_we <= '0';

        o_done <= '0';
        o_z0 <= "00000000";
        o_z1 <= "00000000";
        o_z2 <= "00000000";
        o_z3 <= "00000000";
        
        
         case MAIN_FSM_current_state is
            when WAIT_START =>
                if i_start='1' then
                    MAIN_FSM_next_state <= READ_ADDR;
                end if;
    
            when READ_ADDR =>
                if i_start='0' then
                    MAIN_FSM_next_state <= ASK_MEM;
                end if;
    
            when ASK_MEM =>
                -- la RAM ci mette 1cc per recuperare il valore, e poi assumo di avere il dato su i_mem_data
                o_mem_en <= '1';
                MAIN_FSM_next_state <= OUTPUT;
    
            when OUTPUT =>
                --!!FIXME!! probabilmente è meglio impostare questo direttamente in fsm_output, e non qui, perchè non ci metto solo 1cc
                MAIN_FSM_next_state <= WAIT_START;
        end case;
    end process;
             







    ---- FSM per scansione dell'input e letura in memoria
    sync_ACQUIRING_FSM: process(i_clk,i_rst,ACQUIRING_FSM_next_state)
        begin 
        if (i_rst='1') then
            --------| reset di tutti i segnali al loro vaalore iniziale
            --| impostiamo i segnali e gli stati
            ACQUIRING_FSM_current_state <= S0;                -- stato iniziale di wait for start

        elsif (rising_edge(i_clk)) then  
            ACQUIRING_FSM_current_state <= ACQUIRING_FSM_next_state;
         end if;
     end process;
    
    
    
    comb_acquiring_FSM: process(ACQUIRING_FSM_current_state)
    begin
        case main_fsm_current_state is
            when WAIT_START =>
                control_address <= (others => '0');

            when READ_ADDR =>
                case acquiring_fsm_current_state is
                    when S0 =>
                        control_output(1) <= i_w;
                        acquiring_fsm_next_state <= S1;

                    when S1 =>    
                        control_output(0) <= i_w;
                        acquiring_fsm_next_state <= S_READ;

                    when S_READ =>
                        -- Estensione del vettore a 16 bit: shifto a sx 15 bit in and con i_w
                        control_address <= control_address(14 downto 0) & i_w; -- & concatena, and è logica
                        control_address(0) <= i_w;
                        
                        acquiring_fsm_next_state <= S_READ;
                end case;
                
            when ASK_MEM =>
                -- setto l'indirizzo di ingrsso alla RAM
                o_mem_addr <= control_address;
            when OUTPUT =>
        end case;
    end process;   
    
    
    
    
    
    
    
    
    
    
    
    
  



    ---- FSM per gestire i valori di uscita
    ---- dipende solo dallo stato corrente (current_state) e si occupa di 
    output_process: process(main_fsm_current_state, i_rst)

        variable reg_z0_contents : std_logic_vector(7 downto 0);
        variable reg_z1_contents : std_logic_vector(7 downto 0);
        variable reg_z2_contents : std_logic_vector(7 downto 0);
        variable reg_z3_contents : std_logic_vector(7 downto 0);
    begin
        if (i_rst = '1') then
            reg_z0_contents := "00000000";
            reg_z1_contents := "00000000";
            reg_z2_contents := "00000000";
            reg_z3_contents := "00000000";
        else
            case main_fsm_current_state is
                when WAIT_START | READ_ADDR | ASK_MEM =>
                    o_done <= '0';
    
                    o_z0 <= "00000000";
                    o_z1 <= "00000000";
                    o_z2 <= "00000000";
                    o_z3 <= "00000000";
    
                when OUTPUT =>
                    -- output
                    o_done <= '1';
                    
                     case (control_output) is
                            when "00" =>
                                reg_z0_contents := i_mem_data;
                            when "01" =>
                                reg_z1_contents := i_mem_data;
                            when "10" =>
                                reg_z2_contents := i_mem_data;
                            when "11" =>
                                reg_z3_contents := i_mem_data;
                     end case;

                    
                    o_z0 <= reg_z0_contents;
                    o_z1 <= reg_z1_contents;
                    o_z2 <= reg_z2_contents;
                    o_z3 <= reg_z3_contents;
            end case;
        end if;
    end process;






    
    
    
end proj_impl;






-- COSE DA SISTEMARE
-- 1 RINOMINARE TUTTI GLI STATI 
--2 IDENTARE
--3 CAMBIARE I COMMENTI IN INGLESE
--SISTEMAZIONE DEI NOMI DELLE VARIABILI IN GENERALE
