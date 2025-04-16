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
    port (  clk : in std_logic;
            btnU : in std_logic;
            btnC : in std_logic;
            sw : in std_logic_vector (15 downto 0);
            led : out std_logic_vector (15 downto 0);
            seg : out std_logic_vector (6 downto 0);
            an : out std_logic_vector (3 downto 0)
    );        
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components
	component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component ALU is
        Port (  i_A : in std_logic_vector (7 downto 0);
                i_B : in std_logic_vector (7 downto 0);
                i_op : in std_logic_vector (2 downto 0);
                o_result : out std_logic_vector (7 downto 0);
                o_flags : out std_logic_vector (2 downto 0)
        );
    end component ALU;
    
    component twoscomp_decimal is
        port (
            i_binary: in std_logic_vector(7 downto 0);
            o_negative: out std_logic;
            o_hundreds: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twoscomp_decimal;
    
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
    
    component sevenseg_decoder is
        Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
               o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenseg_decoder;
	
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    
	-- declare signals
    signal w_cycle : std_logic_vector (3 downto 0);
    signal w_reg_A : std_logic_vector (7 downto 0);
    signal w_reg_B : std_logic_vector (7 downto 0);
    signal w_result : std_logic_vector (7 downto 0);
    signal w_display_mux : std_logic_vector (7 downto 0);
    signal w_negative : std_logic (3 downto 0);
    signal w_hundreds : std_logic_vector (3 downto 0);
    signal w_tens : std_logic_vector (3 downto 0);
    signal w_ones : std_logic_vector (3 downto 0);
    signal w_slow_clock : std_logic;
    signal w_TDM_out : std_logic_vector (3 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
	controller_fsm_inst : controller_fsm
        Port Map (  i_reset => btnU,
                    i_adv => btnC,
                    o_cycle => w_cycle
        );
    
    ALU_inst : ALU
        Port Map (  i_A => w_reg_A,
                    i_B => w_reg_B,
                    i_op(0) => sw(13),
                    i_op(1) => sw(14),
                    i_op(2) => sw(15),
                    o_result => w_result,
                    o_flags(0) => led(13),      -- CPU Cout
                    o_flags(1) => led(14),      -- CPU zero
                    o_flags(2) => led(15)       -- CPU sign
        );
    
    twoscomp_decimal_inst : twoscomp_decimal
        Port Map (  i_binary => w_display_mux,
                    o_negative => w_negative,
                    o_hundreds => w_hundreds,
                    o_tens => w_tens,
                    o_ones => w_ones
        );
        
    TDM4_inst : TDM4
	   generic map (k_WIDTH => 4) -- bits in input and output
       Port Map (   i_clk => w_slow_clock,
                    i_reset => '0', 
                    i_D3 => w_negative,
                    i_D2 => w_hundreds,
                    i_D1 => w_tens,
                    i_D0 => w_ones,
                    o_data => w_TDM_out,
                    o_sel => an	-- selected data line (one-cold)
        );
    
    sevenseg_decoder_inst : sevenseg_decoder    
        Port Map (  i_Hex => w_TDM_out,
                    o_seg_n => seg
        );
	
	clk_div_inst : clock_divider
        generic map (k_DIV => 12500)     -- set TDM clk to 4KHz
                                         -- system clock is 100MHz 
                                         -- k_DIV := 12500 --> clock divider of 25000)
        port map (  i_clk => clk,
                    i_reset => btnU,
                    o_clk => w_slow_clock  -- divided (slow) clock
        );
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	
	
end top_basys3_arch;
