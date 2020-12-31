----------------------------------------------------------------------------------
-- Company:        Atomic Development Studio
-- Engineer:       Roland Leurs
-- 
-- Create Date:    21:14 12/20/2020 
-- Design Name: 
-- Module Name:    SystemY - Behavioral 
-- Project Name:   SystemY
-- Target Devices: XC95288XL
-- Tool versions:  
-- Description:    A CPLD configuration to make the Yarrb2
--                 board to behave like an Acorn System 1 computer.
--
-- Dependencies: 
--
-- Revision: 288v0.1
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity decoder is
    Port ( 
		DD:		inout	STD_LOGIC_VECTOR (7 downto 0);
      leds:		out	STD_LOGIC_VECTOR (7 downto 0);

		RW: 		in		STD_LOGIC;
		Phi2:		in		STD_LOGIC;
		Osc:	   in		STD_LOGIC;
		Button:	in		STD_LOGIC;
		A15:		in		STD_LOGIC;
		A14:		in		STD_LOGIC;
		A13:		in		STD_LOGIC;
		A12:		in		STD_LOGIC;
		A11:		in		STD_LOGIC;
		A10:		in		STD_LOGIC;
		A9:		in		STD_LOGIC;
		A8:		in		STD_LOGIC;
		A7:		in		STD_LOGIC;
		A6:		in		STD_LOGIC;
		A5:		in		STD_LOGIC;
		A4:		in		STD_LOGIC;
		A3:		in		STD_LOGIC;
		A2:		in		STD_LOGIC;
		A1:		in		STD_LOGIC;
		A0:		in		STD_LOGIC;
		
		RA16: 	out	STD_LOGIC;
		RA15: 	out	STD_LOGIC;
		RA14: 	out	STD_LOGIC;
		RA13: 	out	STD_LOGIC;
		RA12: 	out	STD_LOGIC;
		CSRAM: 	out	STD_LOGIC;
		CSROM: 	out	STD_LOGIC;
		NWDS:		out	STD_LOGIC;
		NRDS:		out	STD_LOGIC;
		ClkOut: 	out	STD_LOGIC;
      
      CASOUT:  out   STD_LOGIC;
      CASIN:   in    STD_LOGIC;
      ROWSEL:  out   STD_LOGIC_VECTOR(2 downto 0);
      COLUMN:  in    STD_LOGIC_VECTOR(2 downto 0);
      DISPLAY: OUT   STD_LOGIC_VECTOR(7 downto 0);
      
      RST_OUT: OUT   STD_LOGIC;
      NMI_OUT: OUT   STD_LOGIC;
      IRQ_OUT: OUT   STD_LOGIC
		);
end decoder;

-- Configuration register (cgf) is:
-- Bit    Description      Set         Clear
-- Bit 0: button action    Interrupt   Reset          
-- Bit 1: interrupt type   NMI         IRQ 
-- Bit 2: extra RAM        on          off
-- Bit 3: extra ROM        on          off
-- Bit 4: write protect    on          off
-- Bit 5: cassette out     audio       tape
-- Bit 6: turbo mode       on          off
-- Bit 7: cpu clock        2 MHz       1 MHz

architecture Behavioral of decoder is
	signal ClkDiv: 				STD_LOGIC_VECTOR(1 downto 0);
   signal port_a:	            STD_LOGIC_VECTOR(7 downto 0);    -- E20
	signal port_b:             STD_LOGIC_VECTOR(7 downto 0);    -- E21
   signal led:                STD_LOGIC_VECTOR(7 downto 0);    -- E24
   signal cfg:                STD_LOGIC_VECTOR(7 downto 0);    -- E25
   signal E2X:                STD_LOGIC;
	signal RD, WR, WP:			STD_LOGIC;
	signal ClkSel, TurboMode:	STD_LOGIC;
   signal Reset, irq, nmi:    STD_LOGIC;
   signal hz2400, hz1200:     STD_LOGIC;
   signal freqCnt:            STD_LOGIC_VECTOR(9 downto 0);
   signal CASIN2, freqDet:    STD_LOGIC;
	type CasCounter is range 0 to 1000;
   
	begin	
      process (A15, A14, A13, A12, A11, A10, A9, A8, A7, A6, A5, A4, A3, A2)
      begin
      -- select #E2x
         if (A15='0' and A14='0' and A13='0' and A12='0' and A11='1' and A10='1' and A9='1' and A8='0' and A7='0' and A6='0' and A5='1' and A4='0' and A3='0') then
            E2X <= '1';
         else
            E2X <= '0';
         end if;
      end process;
     
      process(Phi2, Button)
      begin
         -- Handle the (reset) button. Depending on config it will
         -- generate a reset to the CPU or an interrupt.
         if rising_edge(Phi2) then
            if cfg(0) = '0' then
               Reset <= Button;
            else 
               Reset <= '0';
            end if;
         end if;
      end process;
     
		process(Phi2, E2X, A2, A1, A0, RW, cfg, Reset, Button)
		begin
			-- write E20 (display data register)
			if falling_edge(Phi2) then
				if Reset = '1' then
					port_a(7 downto 0) <= "00000000";
				else
					if E2X = '1' and A2 = '0' and A1 = '0' and A0 = '0' and RW = '0' then
                  port_a(6) <= DD(6);
                  port_a(2 downto 0) <= DD(2 downto 0);
					end if;
				end if;
            port_a(7) <= freqDet;
            port_a(5 downto 3) <= COLUMN(2 downto 0);
			end if;

			-- write E21 (display/keyboard control register)
			if falling_edge(Phi2) then
				if Reset = '1' then
					port_b(7 downto 0) <= "00000000";
				else
					if E2X = '1' and A2 = '0' and A1 = '0' and A0 = '1' and RW = '0' then
						port_b <= DD;
					end if;
				end if;
			end if;

			-- write E24 (led register)
			if falling_edge(Phi2) then
				if Reset = '1' then
					led(7 downto 0) <= "00000000";
				else
					if E2X = '1' and A2 = '1' and A1 = '0' and A0 = '0' and RW = '0' then
						led <= DD;
					end if;
				end if;
			end if;

			-- write E25 (control register)
			if falling_edge(Phi2) then
            if Button = '1' and cfg(0) = '1' and cfg(1) = '0' then
               irq <= '1';
            end if;
            if Button = '1' and cfg(0) = '1' and cfg(1) = '1' then
               nmi <= '1';
            end if;

				if Reset = '1' then
               cfg(7 downto 0) <= "00000000";
               nmi <= '0';
               irq <= '0';
				else
					if E2X = '1' and A2 = '1' and A1 = '0' and A0 = '1' then
                  if (RW = '0') then
                     cfg <= DD;
                  end if;
                  -- reading or writing this register clears all interrupts
                  nmi <= '0';
                  irq <= '0';                  
					end if;
				end if;
			end if;
         
	end process;

   -- Write strobe. If WP=1 then the RAM area #8000 - #EFFF is write protected.
	process (Phi2, RW, WP, A15)
	begin
		if (Phi2 = '1' and RW = '1') 
		then
			RD <= '0';
		else 
			RD <= '1';
		end if;

		if (Phi2 = '1' and RW = '0' and WP = '0')
			or (Phi2 = '1' and RW = '0' and WP = '1' and A15 = '0')
		then 
			WR <= '0';
		else 
			WR <= '1';
		end if;
	end process;

	process(Osc, TurboMode, ClkSel, ClkDiv)
	begin
		if falling_edge(Osc) then
			ClkDiv <= STD_LOGIC_VECTOR(unsigned(ClkDiv) + 1);
			-- read clock select bits from #E25 when counter is zero,
			-- that way we can garantee that the PHI0 pin is low
			if ClkDiv = b"00" then
				TurboMode <= cfg(6);
				ClkSel <= cfg(7);
			end if;
		end if;
	
		-- Clock divider to 1, 2 and 4 MHz clock signals
		if (TurboMode = '0') then
			if (ClkSel = '0') then
				ClkOut <= ClkDiv(1);
			else
				ClkOut <= ClkDiv(0);
			end if;
		else
			ClkOut <= Osc;
		end if;      
	end process;
   
   process (Osc)
   variable casClkCnt : casCounter := 0;
   begin
      -- Clock diverder to 2400 Hz clock signal
      -- If the input clock is not 4MHz then the 831 must be adjusted
      if falling_edge(Osc) then
         if casClkCnt = 831 then
            hz2400 <= not hz2400;
            if (hz2400 = '1') then
               hz1200 <= not hz1200;
            end if;
            casClkCnt := 0;
         else
            casClkCnt := casClkCnt + 1;
         end if;
      end if;
   end process;

   process (cfg, port_a, hz2400, hz1200)
   begin
      if cfg(5) = '0' then
         if port_a(6) = '0' then
            CASOUT <= hz1200;
         else
            CASOUT <= hz2400;
         end if;
      else
         CASOUT <= port_a(6);
      end if;
   end process;
   
   process (Osc, CASIN)
   begin
      if rising_edge(osc) then
         CASIN2 <= CASIN;
         if CASIN2 = '0' AND CASIN = '1' then
            freqDet <= freqCnt(9);
            freqCnt <= "0000000000";
         else 
            freqCnt <= STD_LOGIC_VECTOR(unsigned(freqCnt) + 1);
         end if;
      end if;
   end process;
   
	process (A15, A14, A13, A12, A11, A10, A9, A8, A7, cfg, E2X)
	begin

      -- CS ROM enabled when:
      -- address = FE00 - #FFFF
      -- address = F000 - #FDFF and extra rom is on
      
      -- IMPORTANT: the chip select of the ROM is active low.
      if (A15 = '1' and A14 = '1' and A13 = '1' and A12 = '1' and A11 = '1' and A10 = '1' and A9 = '1')
         or (A15 = '1' and A14 = '1' and A13 = '1' and A12 = '1' and cfg(3) = '1')
      then 
         CSROM <= '0';
      else
         CSROM <= '1';
      end if;
   
      -- CS RAM enabled when:
      -- address = 0000 - 03FF   0000 00xx xxxx xxxx
      -- address = 0E80 - 0EFF
      -- address = 0400 - 0DFF and extra ram is on
      -- address = 0F00 - EFFF and extra ram is on
      
      -- IMPORTANT: On the YARRB2 board the chip enable is on pin 30
      -- of the RAM chip and this is an active high input !!!
      if (A15 = '0' and A14 = '0' and A13 = '0' and A12 = '0' and A11 = '0' and A10 = '0')
         or (A15 = '0' and A14 = '0' and A13 = '0' and A12 = '0' and A11 = '1' and A10 = '1' and A9 = '1' and A8 = '0' and A7 = '1')
         or (cfg(2) = '1' and NOT (A15 = '1' and A14 = '1' AND A13 = '1' and A12 = '1') and E2X = '0')
      then 
         CSRAM <= '1';
      else 
         CSRAM <= '0';
      end if;      
	end process;

   -- external address lines
   RA16 <= '0';      -- always zero (unused)
   RA15 <= A15;      -- other address lines just follow the
   RA14 <= A14;      -- cpu address lines (no bank switching)
   RA13 <= A13;
   RA12 <= A12;
	
   -- Signals to output
   NRDS <= RD;
   NWDS <= WR;
   WP   <= cfg(4);
   leds <= led;
   
   ROWSEL(2 downto 0) <= port_a(2 downto 0);
   DISPLAY <= port_b;
   
   RST_OUT <= not Reset;
   -- Interrupt lines are inverted by an open collector transistor
   -- so setting to '1' generates an interrupt.
   NMI_OUT <= nmi;
   IRQ_OUT <= irq;
   
	-- read registers
   DD <= (others => 'Z') when E2X = '0' or RW = '0' else
         led         when A2 = '1' and A1 = '0' and A0 = '0'  else
         cfg         when A2 = '1' and A1 = '0' and A0 = '1'  else
         port_a      when A2 = '0' and A1 = '0' and A0 = '0'  else
         port_b      when A2 = '0' and A1 = '0' and A0 = '1'  else
         (others => '0');

end Behavioral;
