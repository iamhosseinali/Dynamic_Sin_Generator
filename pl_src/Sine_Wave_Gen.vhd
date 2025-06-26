-- Company: Taksun
-- Engineer: Hosseinali 
-- Description: Sine_Wave_Gen is a synthesizable VHDL module that generates an 8-bit sine wave using 
-- a precomputed lookup table. The frequency of the output signal is configurable through a 32-bit input vector. 
-- This module is designed to be compatible with AXI Stream (AXIS) interfaces. The Phase width is 8 so there are 
-- 2^8 samples in one sine wave cycle. Use these formulas to caculate the phase_step, f_out = (phase_step × Fs) / 2^8 
-- or phase_step = 2^8 x f_out/Fs
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
    M_AXIS_tDATA            : out std_logic_vector(15 downto 0);
    M_AXIS_tVALID           : out std_logic;
    PHASE_STEP_CONF         : in std_logic_vector(31 downto 0); 
    FS_CONF                 : in std_logic_vector(31 downto 0) -- (31) valid_flag, (30:0) IP_INPUT_FREQUENCY/Fs-1
);
end Sine_Wave_Gen;

architecture Behavioral of Sine_Wave_Gen is

constant SIN_TABLE_Length          : integer := 256; --- This is the Phase width
constant SIN_DATA_WIDTH            : integer := 16;
type SIN_TABLEType is array(0 to SIN_TABLE_Length-1) of integer;
constant SIN_TABLE : SIN_TABLEType :=(0,804,1607,2410,3211,4011,4808,5602,6392,7179,7961,8739,9512,10278,11039,11793,12539,13278,14010,14732,15446,16151,16846,17530,18204,18868,19519,20159,20787,21403,22005,22594,23170,23732,24279,24812,25330,25832,26319,26790,27245,27684,28106,28511,28898,29269,29621,29956,30273,30572,30852,31114,31357,31581,31785,31971,32138,32285,32413,32521,32610,32679,32728,32758,32767,32758,32728,32679,32610,32521,32413,32285,32138,31971,31785,31581,31357,31114,30852,30572,30273,29956,29621,29269,28898,28511,28106,27684,27245,26790,26319,25832,25330,24812,24279,23732,23170,22594,22005,21403,20787,20159,19519,18868,18204,17530,16846,16151,15446,14732,14010,13278,12539,11793,11039,10278,9512,8739,7961,7179,6392,5602,4808,4011,3211,2410,1607,804,0,-804,-1607,-2410,-3211,-4011,-4808,-5602,-6392,-7179,-7962,-8739,-9512,-10278,-11039,-11793,-12539,-13279,-14010,-14732,-15446,-16151,-16846,-17530,-18205,-18868,-19519,-20159,-20787,-21403,-22005,-22594,-23170,-23732,-24279,-24812,-25330,-25832,-26319,-26790,-27245,-27684,-28106,-28511,-28898,-29269,-29621,-29956,-30273,-30572,-30852,-31114,-31357,-31581,-31786,-31971,-32138,-32285,-32413,-32521,-32610,-32679,-32728,-32758,-32767,-32758,-32728,-32679,-32610,-32521,-32413,-32285,-32138,-31971,-31785,-31580,-31356,-31114,-30852,-30572,-30273,-29956,-29621,-29269,-28898,-28510,-28105,-27684,-27245,-26790,-26319,-25832,-25329,-24812,-24279,-23731,-23170,-22594,-22005,-21402,-20787,-20159,-19519,-18867,-18204,-17530,-16845,-16151,-15446,-14732,-14009,-13278,-12539,-11792,-11038,-10278,-9511,-8739,-7961,-7179,-6392,-5601,-4807,-4010,-3211,-2410,-1607,-804);
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
                Config_int         <= FS_CONF;
                indx_cycle  <= to_unsigned(def_indx_cycle,31);
                if(FS_CONF(31) = '1') then
                    indx_cycle  <= unsigned(Config_int(30 downto 0)); 
                end if;
                if((Config_int(31) = '0' and FS_CONF(31) = '1') or (Config_int(31) = '1' and FS_CONF(31) = '0')) then 
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
                cnt             <= (others=>'0');
                sin_indx        <= sin_indx + to_unsigned(Phase_Step,8);
                M_AXIS_tVALID   <= '1';
                M_AXIS_tDATA    <= std_logic_vector(to_signed(SIN_TABLE(to_integer(sin_indx)),SIN_DATA_WIDTH));
            end if;
       end if;
    end if;
end process;
end Behavioral;
