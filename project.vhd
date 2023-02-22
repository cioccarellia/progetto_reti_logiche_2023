----------------------------------------------------------------------------------
-- Students: Alberto Cantele (10766393), Andrea Cioccarelli (10713858)
-- Create Date: 02/20/2023 11:36:44 AM
----------------------------------------------------------------------------------


----------------------------------------------------------------------------------
--
--  project_reti_logiche
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity project_reti_logiche is
    port(
        i_clk:          in  std_logic;
        i_rst:          in  std_logic;
        i_start:        in  std_logic;
        i_w:            in  std_logic;
        
        o_z0:           out std_logic_vector(7 downto 0);
        o_z1:           out std_logic_vector(7 downto 0);
        o_z2:           out std_logic_vector(7 downto 0);
        o_z3:           out std_logic_vector(7 downto 0);
        o_done:         out std_logic;
        
        o_mem_addr:     out std_logic_vector(15 downto 0);
        i_mem_data:     in  std_logic_vector(7 downto 0);
        o_mem_we:       out std_logic;
        o_mem_en:       out std_logic
    );
end project_reti_logiche;



architecture proj_impl of  project_reti_logiche is

    -- segnali di controllo (da mux a reg)
    signal current_out_z0: std_logic_vector(7 downto 0);
    signal current_out_z1: std_logic_vector(7 downto 0);
    signal current_out_z2: std_logic_vector(7 downto 0);
    signal current_out_z3: std_logic_vector(7 downto 0);
    
    --segnali di controllo (da reg a and)
     signal reg_out_z0: std_logic_vector(7 downto 0);
    signal reg_out_z1: std_logic_vector(7 downto 0);
    signal reg_out_z2: std_logic_vector(7 downto 0);
    signal reg_out_z3: std_logic_vector(7 downto 0);



    -- Stato della FSM che modella l'esecuzione del processo.
    -- Ci sono 4 stati possibili: 
    -- - WAIT_START: Stato di idle
    -- - READ_ADDR: Si legge bit per bit l'ingresso w e si salva il valore
    -- - ASK_MEM: Si inviano i segnali alla RAM e si aspetta perche processi la richiesta, 1cc
    -- - OUTPUT: Fase di output, 1cc
    type FSM_S is (WAIT_START, READ_ADDR, ASK_MEM, OUTPUT);
    signal current_state: FSM_S;



    -- Stato della FSM che modella la lettura del segnale di controllo output e dell'indirizzo di memoria.
    -- - S0: Lettura del primo bit di controllo uscita
    -- - S1: Lettura del secondo bit di controllo uscita
    -- - S_READ: Lettura dei singoli bit dell'indirizzo
    type FSM_S_READ is (S0, S1, S_READ);
    signal current_state_reader: FSM_S_READ;



    -- Segnali di supporto alla lettura dell indirizzo di ingresso
    signal control_output:          std_logic_vector(1 downto 0);
    signal control_address:         std_logic_vector(15 downto 0);
    signal control_done_enable:     std_logic;
    



    -- componente di registro a 8 bit
    component REG_OUT_8_BIT is
        port(
            clk: in std_logic;
            rst: in std_logic;
            x: in std_logic_vector(7 downto 0);
            y: out std_logic_vector(7 downto 0)
        );
    end component;
begin

    ----istanza del componente
    R0: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, x=>current_out_z0,y => reg_out_z0 );
    R1: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, x=>current_out_z1,y => reg_out_z1 );
    R2: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, x=>current_out_z2,y => reg_out_z2 );
    R3: REG_OUT_8_BIT 
        port map(clk => i_clk, rst => i_rst, x=>current_out_z3,y => reg_out_z3 );
        
    ---- FSM per gestire lo stato del programma al variare dei segnali di clock (i_clk) e reset (i_rst)
    fsm: process(i_clk, i_rst)
    begin
        if i_rst='1' then
            -- reset di tutti i segnali al loro vaalore iniziale
            current_state <= WAIT_START;

            current_out_z0 <= (others => '0');
            current_out_z1 <= (others => '0');
            current_out_z2 <= (others => '0');
            current_out_z3 <= (others => '0');

            o_done <= '0';
            o_z0 <= (others => '0');
            o_z1 <= (others => '0');
            o_z2 <= (others => '0');
            o_z3 <= (others => '0');

            control_output <= "00";                 -- 2  bits of zeros
            control_address <= (others => '0');     -- 16 bits of zeros

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
                    -- la RAM ci mette 1cc per recuperare il valore
                    current_state <= OUTPUT;

                when OUTPUT =>
                    current_state <= WAIT_START;
            end case;
        end if;
    end process;



    ---- FSM per gestire i valori di uscita
    ---- dipende solo dallo stato corrente (current_state) e si occupa di 
    fsm_output: process(current_state)
    begin
        case current_state is
            when WAIT_START | READ_ADDR | ASK_MEM =>
                o_done <= '0';
                control_done_enable <= '0';
                o_z0 <= (others => '0');
                o_z1 <= (others => '0');
                o_z2 <= (others => '0');
                o_z3 <= (others => '0');

            when OUTPUT =>
                -- sets the current address data to the selected lane
                case control_output is
                    when "00" => current_out_z0 <= i_mem_data;
                    when "01" => current_out_z1 <= i_mem_data;
                    when "10" => current_out_z2 <= i_mem_data;
                    when "11" => current_out_z3 <= i_mem_data; 
                end case;
            
                -- output
                o_done <= '1';
               control_done_enable <= '1';
                o_z0 <= reg_out_z0 and (others => control_done_enable);
                o_z1 <= reg_out_z1 and (others => control_done_enable);
                o_z2 <= reg_out_z2 and (others => control_done_enable);
                o_z3 <= reg_out_z3 and (others => control_done_enable);
           end case;
    end process;





    ---- FSM per scansione dell'input e letura in memoria
    fsm_scan_read: process(current_state, current_state_reader)
    begin
        case current_state is
            when WAIT_START =>
                control_address <= (others => '0');

            when READ_ADDR =>
                -- implementazione multiplexer scelta del canale di uscita 
                case current_state_reader is
                    when S0 =>
                        if i_clk'event and i_clk='1' then
                            control_output(1) <= i_w;
                        end if;
                        current_state_reader<=S1;

                    when S1 =>    
                        if i_clk'event and i_clk='1' then
                            control_output(0) <= i_w;
                        end if;
                        current_state_reader <= S_READ;

                    when S_read =>
                        -- Estensione del vettore a 16 bit: shifto a sx 15 bit e and-o w
                        if i_clk'event and i_clk='1' then
                            control_address(15 downto 0) <= control_address(14 downto 0) & i_w;
                            control_address(0) <= i_w;
                        end if;
                        current_state_reader <= S_READ;
                    
                end case;
            when ASK_MEM =>
                -- abilitazione lettura in memoria
                o_mem_en <= '1';
                o_mem_we <='0';
                o_mem_addr <= control_address;
                
            --lettura in memoria e acquisizione dato
            when OUTPUT =>
           end case;
    end process;   
end proj_impl;






----------------------------------------------------------------------------------
--
--  Registro di supporto a 8 bit
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- register entity
entity REGISTER_Z8 is
    port(
        clk:    in  std_logic;
        rst:    in  std_logic;
        x:      in  std_logic_vector(7 downto 0);
        y:      out std_logic_vector(7 downto 0)
    );
end REGISTER_Z8;


-- register implementaation
architecture REG_impl of REGISTER_Z8 is
    begin
        reg: process(clk,rst)
        begin
            if rst='1' then
                -- reset dello stato del registro
                y <= (others => '0');
            elsif clk'event and clk='1' then
                y <= x;
            end if;
        end process;
end REG_impl;
