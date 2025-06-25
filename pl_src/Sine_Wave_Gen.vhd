-- Company: Taksun
-- Engineer: Hosseinali 
-- Description: Sine_Wave_Gen is a synthesizable VHDL module that generates an 8-bit sine wave using 
-- a precomputed lookup table. The frequency of the output signal is configurable through a 32-bit input vector. 
-- This module is designed to be compatible with AXI Stream (AXIS) interfaces. The Phase width is 8 so there are 
-- 2^8 samples in one sine wave cycle. 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Sine_Wave_Gen is
generic (
    Dynamic_Fs          : boolean := false; 
    IP_INPUT_FREQUENCY  : integer := 100000000; --- in Hz
    DEFAULT_Fs          : integer := 100000000;  --- in Hz
    Dynamic_Phase_Step  : boolean := false;
    DEFAULT_PHASE_STEP  : integer range 1 to 255 := 1
);
Port (
    M_AXIS_ACLK             : in STD_LOGIC;
    M_AXIS_ARESETN          : in STD_LOGIC; 
    M_AXIS_tDATA            : out std_logic_vector(7 downto 0);
    M_AXIS_tVALID           : out std_logic;
    PHASE_STEP_CONF         : in std_logic_vector(31 downto 0); 
    Config                  : in std_logic_vector(31 downto 0) -- (31) valid_flag, (30:0) IP_INPUT_FREQUENCY/Fs-1
);
end Sine_Wave_Gen;

architecture Behavioral of Sine_Wave_Gen is

constant SIN_TABLE_Length          : integer := 256; --- This is the Phase width
constant SIN_DATA_WIDTH            : integer := 8;
type SIN_TABLEType is array(0 to SIN_TABLE_Length-1) of integer;
constant SIN_TABLE : SIN_TABLEType :=(0,3,6,9,12,15,18,21,24,28,31,34,37,40,43,46,48,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88,90,92,94,96,98,100,102,104,106,108,109,111,112,114,115,117,118,119,120,121,122,123,124,124,125,126,126,127,127,127,127,127,127,127,127,127,127,127,126,126,125,124,124,123,122,121,120,119,118,117,115,114,112,111,109,108,106,104,102,100,98,96,94,92,90,88,85,83,81,78,76,73,71,68,65,63,60,57,54,51,48,46,43,40,37,34,31,28,24,21,18,15,12,9,6,3,0,-3,-6,-9,-12,-15,-18,-21,-24,-28,-31,-34,-37,-40,-43,-46,-48,-51,-54,-57,-60,-63,-65,-68,-71,-73,-76,-78,-81,-83,-85,-88,-90,-92,-94,-96,-98,-100,-102,-104,-106,-108,-109,-111,-112,-114,-115,-117,-118,-119,-120,-121,-122,-123,-124,-124,-125,-126,-126,-127,-127,-127,-127,-127,-127,-127,-127,-127,-127,-127,-126,-126,-125,-124,-124,-123,-122,-121,-120,-119,-118,-117,-115,-114,-112,-111,-109,-108,-106,-104,-102,-100,-98,-96,-94,-92,-90,-88,-85,-83,-81,-78,-76,-73,-71,-68,-65,-63,-60,-57,-54,-51,-48,-46,-43,-40,-37,-34,-31,-28,-24,-21,-18,-15,-12,-9,-6,-3);
attribute ram_style : string;
attribute ram_style of SIN_TABLE : constant is "block";
constant def_indx_cycle            : integer := IP_INPUT_FREQUENCY/DEFAULT_Fs-1;
signal indx_cycle                  : unsigned(30 downto 0) := to_unsigned(def_indx_cycle,31);
signal sin_indx                    : unsigned(7 downto 0) := (others=>'0');
signal cnt                         : unsigned(31 downto 0) := (others=>'0');
signal valid_flag_int              : std_logic := '0';  
signal Config_int                  : std_logic_vector(31 downto 0) := (others=>'0');
signal Phase_Step                  : integer := DEFAULT_PHASE_STEP; 

begin

process(M_AXIS_ACLK)
begin
    if rising_edge(M_AXIS_ACLK) then
        if (M_AXIS_ARESETN='0') then
            cnt             <= (others=>'0');
            sin_indx        <= (others=>'0');
            M_AXIS_tVALID   <= '0';
            indx_cycle      <= to_unsigned(def_indx_cycle,31);
            Phase_Step      <= DEFAULT_PHASE_STEP;
        else
            cnt             <= cnt+1;
            M_AXIS_tVALID   <= '0';
            
            --- Dynamic Fs implementation --- 
            if(Dynamic_Fs = true) then 
                Config_int         <= Config;
                indx_cycle  <= to_unsigned(def_indx_cycle,31);
                if(Config(31) = '1') then
                    indx_cycle  <= unsigned(Config_int(30 downto 0)); 
                end if;
                if((Config_int(31) = '0' and Config(31) = '1') or (Config_int(31) = '1' and Config(31) = '0')) then 
                    cnt        <= (others=>'0');
                end if;
            end if; 

            --- Dynamic Phase Step implementation --- 
            if(Dynamic_Phase_Step = true) then 
                if(PHASE_STEP_CONF(31) = '1') then 
                    Phase_Step      <= to_integer(unsigned(PHASE_STEP_CONF(7 downto 0))); 
                end if; 
            end if; 

            --- LUT indexing --- 
            if(cnt=indx_cycle)then
                cnt        <= (others=>'0');
                sin_indx   <= sin_indx + to_unsigned(Phase_Step,8);
                M_AXIS_tVALID  <= '1';
                M_AXIS_tDATA   <= std_logic_vector(to_signed(SIN_TABLE(to_integer(sin_indx)),SIN_DATA_WIDTH));
            end if;
       end if;
    end if;
end process;
end Behavioral;
