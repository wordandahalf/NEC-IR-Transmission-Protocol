library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.DE2_115_SEVEN_SEGMENT.ALL;

entity RC_receiver is
    generic (
        g_LEADER_CODE_LENGTH : INTEGER := 450000
    );
    port(
        o_HEX       : out SEG_ARR;
        o_DATA      : out STD_LOGIC;
        i_CLK       : in  STD_LOGIC;
        i_DATA      : in  STD_LOGIC;
        i_RESET     : in  STD_LOGIC
    );
end RC_receiver;

architecture Implementation of RC_receiver is
    constant LEAD_OFF_MAX_LENGTH : INTEGER := g_LEADER_CODE_LENGTH / 2;
    constant c_ONE_LENGTH  : INTEGER := g_LEADER_CODE_LENGTH / 4;
    constant c_ZERO_LENGTH : INTEGER := g_LEADER_CODE_LENGTH / 8;
    constant c_PADDING_LENGTH   : INTEGER := g_LEADER_CODE_LENGTH / 50;
    constant c_MAX_DATA_LENGTH  : INTEGER := 32;

    signal s_READ_LEAD_ON   : STD_LOGIC := '0';
    signal s_LEAD_ON_COUNT  : INTEGER range 0 to g_LEADER_CODE_LENGTH + c_PADDING_LENGTH;

    signal s_READ_LEAD_OFF  : STD_LOGIC := '0';
    signal s_LEAD_OFF_COUNT : INTEGER range 0 to LEAD_OFF_MAX_LENGTH + c_PADDING_LENGTH;

    signal s_READ_DATA  : STD_LOGIC := '0';
    signal s_COUNT      : INTEGER range 0 to c_ONE_LENGTH + c_PADDING_LENGTH;
    signal s_CHECK_DATA : STD_LOGIC := '0';

    signal s_DATA_BIT   : STD_LOGIC := '0';

    signal s_DATA_COUNT : INTEGER range 0 to c_MAX_DATA_LENGTH - 1;

    signal s_DATA : STD_LOGIC;
    signal s_DATA_LEAD, s_DATA_FOLLOW : STD_LOGIC;
    signal s_DATA_EDGE : STD_LOGIC;

    signal s_SHIFT_REG  : STD_LOGIC_VECTOR(c_MAX_DATA_LENGTH - 1 downto 0) := (others => '0');

    type t_STATE is(START, READ_LEAD_ON, CHECK_ON_LENGTH, READ_LEAD_OFF,
                    CHECK_OFF_LENGTH, READ_DATA, CHECK_DATA);
    signal s_CURRENT_STATE, s_NEXT_STATE : t_STATE;

    component hex_to_7_seg is
    port (
        seven_seg   : out STD_LOGIC_VECTOR(6 downto 0);
        hex         : in  STD_LOGIC_VECTOR(3 downto 0)
    );
    end component;
begin    
    HEX7: hex_to_7_seg port map(o_HEX(7), s_SHIFT_REG(c_MAX_DATA_LENGTH - 1  downto c_MAX_DATA_LENGTH - 4));
    HEX6: hex_to_7_seg port map(o_HEX(6), s_SHIFT_REG(c_MAX_DATA_LENGTH - 5  downto c_MAX_DATA_LENGTH - 8));
    HEX5: hex_to_7_seg port map(o_HEX(5), s_SHIFT_REG(c_MAX_DATA_LENGTH - 9  downto c_MAX_DATA_LENGTH - 12));
    HEX4: hex_to_7_seg port map(o_HEX(4), s_SHIFT_REG(c_MAX_DATA_LENGTH - 13 downto c_MAX_DATA_LENGTH - 16));
    HEX3: hex_to_7_seg port map(o_HEX(3), s_SHIFT_REG(c_MAX_DATA_LENGTH - 17 downto c_MAX_DATA_LENGTH - 20));
    HEX2: hex_to_7_seg port map(o_HEX(2), s_SHIFT_REG(c_MAX_DATA_LENGTH - 21 downto c_MAX_DATA_LENGTH - 24));
    HEX1: hex_to_7_seg port map(o_HEX(1), s_SHIFT_REG(c_MAX_DATA_LENGTH - 25 downto c_MAX_DATA_LENGTH - 28));
    HEX0: hex_to_7_seg port map(o_HEX(0), s_SHIFT_REG(c_MAX_DATA_LENGTH - 29 downto c_MAX_DATA_LENGTH - 32));

    s_DATA <= not i_DATA;
    o_DATA <= s_READ_DATA;

    process(i_CLK) 
    begin
        if rising_edge(i_CLK) then
            if i_RESET = '0' then
                s_CURRENT_STATE <= START;
            else
                s_CURRENT_STATE <= s_NEXT_STATE;
            end if;
        end if;
    end process;

    process(s_CURRENT_STATE, s_LEAD_ON_COUNT, s_LEAD_OFF_COUNT, s_COUNT, 
            s_DATA_COUNT, s_DATA, s_DATA_EDGE)
    begin
        s_NEXT_STATE <= s_CURRENT_STATE;
        s_READ_LEAD_OFF <= '0';
        s_READ_LEAD_ON <= '0';
        s_READ_DATA <= '0';
        s_CHECK_DATA <= '0';

        case s_CURRENT_STATE is
            when START =>
                if s_DATA_EDGE = '1' then
                    s_NEXT_STATE <= READ_LEAD_ON;
                end if;
            when READ_LEAD_ON =>
                s_READ_LEAD_ON <= '1';
                s_NEXT_STATE <= CHECK_ON_LENGTH when s_DATA = '0' else READ_LEAD_ON;
            when CHECK_ON_LENGTH =>
                s_NEXT_STATE <= READ_LEAD_OFF when s_LEAD_ON_COUNT < g_LEADER_CODE_LENGTH + c_PADDING_LENGTH else START;
            when READ_LEAD_OFF =>
                s_READ_LEAD_OFF <= '1';
                s_NEXT_STATE <= CHECK_OFF_LENGTH when s_DATA_EDGE = '1' else READ_LEAD_OFF;
            when CHECK_OFF_LENGTH =>
                s_NEXT_STATE <= READ_DATA when s_LEAD_OFF_COUNT < LEAD_OFF_MAX_LENGTH + c_PADDING_LENGTH else START;
            when READ_DATA =>
                s_READ_DATA <= '1';
                s_NEXT_STATE <= CHECK_DATA when s_DATA_EDGE = '1' else READ_DATA;
            when CHECK_DATA=>
                s_CHECK_DATA <= '1';
                s_NEXT_STATE <= READ_DATA when s_DATA_COUNT /= 31 else START;
            when others => s_NEXT_STATE <= START;
        end case;
    end process;

    s_DATA_EDGE <= s_DATA_LEAD and (not s_DATA_FOLLOW);
    process(i_CLK)
    begin
        if rising_edge(i_CLK) then
            if i_RESET = '0' then
                s_DATA_LEAD <= '0';
                s_DATA_FOLLOW <= '0';
            else    
                s_DATA_LEAD <= i_DATA;
                s_DATA_FOLLOW <= s_DATA_LEAD;
            end if;
        end if;
    end process;

    process(i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (s_READ_LEAD_ON = '1' and i_RESET = '1') then
                s_LEAD_ON_COUNT <= s_LEAD_ON_COUNT + 1;
            else
                s_LEAD_ON_COUNT <= 0;
            end if;
        end if;
    end process;

    process(i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (s_READ_LEAD_OFF = '1' and i_RESET = '1') then
                s_LEAD_OFF_COUNT <= s_LEAD_OFF_COUNT + 1;
            else
                s_LEAD_OFF_COUNT <= 0;
            end if;
        end if;
    end process;

    process(i_CLK, s_READ_DATA, s_COUNT)
    begin
        if rising_edge(i_CLK) then
            if s_CURRENT_STATE = READ_DATA and i_RESET = '1' then
                s_COUNT <= s_COUNT + 1;
            else
                s_COUNT <= 0;
            end if;

            if s_COUNT = c_ONE_LENGTH - c_PADDING_LENGTH then
                s_DATA_BIT <= '0';
            elsif(s_COUNT = c_ONE_LENGTH + c_PADDING_LENGTH) then
                s_DATA_BIT <= '0';
            elsif(s_COUNT = c_ZERO_LENGTH - c_PADDING_LENGTH) then
                s_DATA_BIT <= '1';
            elsif(s_COUNT = c_ZERO_LENGTH + c_PADDING_LENGTH) then
                s_DATA_BIT <= '1';
            end if;
        end if;
    end process;

    process(i_CLK, s_READ_DATA, s_DATA_COUNT)
    begin
        if rising_edge(i_CLK) then
            if s_READ_DATA = '1' and i_RESET = '1' then
                s_DATA_COUNT <= s_DATA_COUNT + 1;
            else
                s_DATA_COUNT <= 0;
            end if;
        end if;
    end process;

    process(s_READ_DATA)
    begin
        if rising_edge(s_READ_DATA) then
            s_SHIFT_REG <= s_SHIFT_REG(c_MAX_DATA_LENGTH - 1 - 1 downto 0) & s_DATA_BIT;
        end if;
    end process;
end Implementation;    
