--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
-- ONLY CHANGE: Top_Basys3, ALU, controller
	-- declare components and signals
	
    signal w_register_A : STD_LOGIC_VECTOR (7 downto 0);
    signal w_register_B : STD_LOGIC_VECTOR (7 downto 0);
    signal w_alu_mux : STD_LOGIC_VECTOR (7 downto 0);
    signal w_alu_result : STD_LOGIC_VECTOR (7 downto 0);
    signal w_out_decoder : STD_LOGIC_VECTOR (6 downto 0);
    signal w_alu_flags : STD_LOGIC_VECTOR (3 downto 0);
    signal w_tdm_data : STD_LOGIC_VECTOR (3 downto 0);
    signal w_data : STD_LOGIC_VECTOR (3 downto 0);
    signal w_cycle : STD_LOGIC_VECTOR (3 downto 0);
    signal w_sel : STD_LOGIC_VECTOR (3 downto 0);
    signal w_an : STD_LOGIC_VECTOR (3 downto 0);
    signal w_op : STD_LOGIC_VECTOR (2 downto 0);
    signal w_clk : std_logic;
    signal w_buttonC : std_logic;
    signal w_tdm_clk : std_logic;
    signal w_fsm : std_logic;
    signal w_sign : std_logic;
    signal w_sign_4bit : std_logic_vector (3 downto 0);
    signal w_hund : std_logic_vector (3 downto 0);
    signal w_tens : std_logic_vector (3 downto 0);
    signal w_ones : std_logic_vector (3 downto 0);
    
-- component 1: ALU
component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end component ALU;
-- component 2: clock divider
component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
-- component 3: controller
component controller_fsm is
    Port ( i_clk   : in STD_LOGIC;
           i_reset : in STD_LOGIC;
           i_adv   : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end component controller_fsm;
-- component 4: twos_comp
component twoscomp_decimal is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component twoscomp_decimal;
-- component 5: TDM4
component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
-- component 6: sevenseg_decoder
component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
-- component 7: button debouncer
component button_debounce is
	Port(	clk: in  STD_LOGIC;
			reset : in  STD_LOGIC;
			button: in STD_LOGIC;
			action: out STD_LOGIC);
end component button_debounce;
begin
	-- PORT MAPS ----------------------------------------
u_button_debouce : button_debounce
    port map (
                clk => clk,
                reset => btnU,
                button => btnC,
                action => w_buttonC
    );	
	
u_TDM4 : TDM4
	port map (
	            i_clk => w_tdm_clk,
	            i_reset => btnU,
	            i_D3 => w_sign_4bit,
	            i_D2 => w_hund,
	            i_D1 => w_tens,
	            i_D0 => w_ones,
	            o_data => w_tdm_data,
	            o_sel => w_an
	);

u_sevenseg_decoder : sevenseg_decoder
    port map (
                i_Hex => w_tdm_data,
                o_seg_n => w_out_decoder
    );

clkdiv_inst_tdm : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 50000 ) 
        port map (						  
            i_clk   => clk,
            i_reset => btnU,
            o_clk   => w_tdm_clk
        );

u_alu : ALU
	port map (
	           i_A => w_register_A,
	           i_B => w_register_B,
	           i_op => w_op,
	           o_result => w_alu_result,
	           o_flags => w_alu_flags
	           
	);
	
u_controller_fsm : controller_fsm
    port map (  i_clk => clk,
                i_reset => btnU,
                i_adv => w_buttonC,
                o_cycle => w_cycle
	);

u_twoscomp_decimal : twoscomp_decimal
    port map (
               i_bin => w_alu_mux,
               o_sign => w_sign,
               o_hund => w_hund,
               o_tens => w_tens,
               o_ones => w_ones
    );
	-- CONCURRENT STATEMENTS ----------------------------
	Register_A_process : process(w_cycle(1),btnU)
	begin
	   if btnU = '1' then
	       w_register_A <= (others => '0');
	   elsif rising_edge(w_cycle(1)) then
	       w_register_A <= sw(7 downto 0);
	   end if;
	end process;
	
	Register_B_process : process(w_cycle(2),btnU)
	begin
	   if btnU = '1' then
	       w_register_B <= (others => '0');
	   elsif rising_edge(w_cycle(2)) then
	       w_register_B <= sw(7 downto 0);
	   end if;
	end process;
	
	w_alu_mux <= "00000000"   when w_cycle = "0001" else
	             w_register_A when w_cycle = "0010" else
	             w_register_B when w_cycle = "0100" else
	             w_alu_result when w_cycle = "1000" else
	             "00000000";
	
	an <= w_an;
	w_sign_4bit <= "1010" when w_sign = '1' else "1111";
	             
    led (15 downto 12) <= w_alu_flags;
	led (3 downto 0) <= w_cycle;
	led (11 downto 4) <= (others => '0');
	w_op <= sw(2 downto 0);
	
	seg <= w_out_decoder;
	
end top_basys3_arch;
