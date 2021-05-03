    library ieee;
    use ieee.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use ieee.std_logic_unsigned.all;
    
    entity decoder is
      port (
            Clk     	: in    std_logic;
            Rst     	: in    std_logic; --aktive low
            enable  	: in    std_logic; --switch r2 
            fullcounter : in    std_logic; --signalisiert Speicher ist voll
            ADDR		: in    std_logic_vector(7 downto 0);
            DATOUT_DECR : out   std_logic_vector(7 downto 0); 	-- Datenausgang entschlüsselte Daten
            DATOUT_ADDR : inout std_logic_vector(7 downto 0); 	-- Adresse für entschlüsselte Daten
            DATIN_ENCR  : inout std_logic_vector(7 downto 0);		-- Dateneingang verschlüsselte Daten
            DATIN_ADDR  : out   std_logic_vector (7 downto 0)); 	-- Sourceadresse verschlüsselte Daten
    end decoder;
    
    architecture RTL of decoder is
      
      component Random_Number_8
          port(  
         	 	Clk 				: in  std_logic;
        		Rst 				: in  std_logic;
        		KeyIn 				: in  unsigned (7 downto 0);
        		reset_Number 		: in  std_logic;
        		RanNum 				: out unsigned (8 downto 1);
        		RanNum_targetadress : out unsigned (7 downto 0));
      end component Random_Number_8;
      
      component ROMKey
          generic(
              L_BITS : natural;
              M_BITS : natural
          );
          port(
              ADDR : in  std_logic_vector(L_BITS - 1 downto 0);
              DATA : out unsigned(M_BITS - 1 downto 0)
          );
      end component ROMKey;
     	
     component Random_Number_8_mem                                 
        port ( Clk    				: in  std_logic;
               RanNum_targetadress 	: in  unsigned 	(7 downto 0);
               RanNum_In 			: in  unsigned 	(7 downto 0);
               RanNum_sourceadress 	: in  unsigned 	(7 downto 0);
               RanNum_Out 			: out std_logic_vector (7 downto 0)); 
    	end component Random_Number_8_mem;
    	 
      
      signal RanNumber_IN   : unsigned(7 downto 0);
	  signal RanNumber_OUT  : std_logic_vector(7 downto 0);
      signal KeyInInt       : unsigned(7 downto 0);
      signal RanNum_tADDR   : unsigned(7 downto 0):= "00000000";
      signal RanNum_sADDR   : unsigned(7 downto 0):= "00000000";
      signal reset_Number	: std_logic;  
      signal counter        : integer;
      signal ADDRKey        : std_logic_vector(7 downto 0);

  begin 
   
      RanNumber_mem: Random_Number_8_mem 
      port map (
          Clk => Clk,
          RanNum_targetadress => RanNum_tADDR,
          RanNum_In			  => RanNumber_IN,
          RanNum_sourceadress => RanNum_sADDR,
          RanNum_Out 		  => RanNumber_OUT);
      
      RanNumber : Random_Number_8 
      port map(
          Clk => Clk,
          Rst => Rst,
          KeyIn => KeyInInt,
          reset_Number => reset_Number,
          RanNum => RanNumber_IN,
          RanNum_targetadress => RanNum_tADDR );
          
      ROMKey_mem : ROMKey  
      generic map(
          L_BITS => 8, 
          M_BITS => 8) 
      port map (
           ADDR => ADDRKey,
           DATA => KeyInInt); 

AddressKey : process (Clk, enable) begin
  if(enable = '1') then
    if rising_edge(Clk) then
             ADDRKey <= ADDR ;
    end if;
  end if;
end process AddressKey;


decryption : process(Clk,Rst, enable) begin
    if(Rst = '0') then
        DATOUT_ADDR <= "00000000";
        DATIN_ENCR <= "00000000";
        reset_Number <='0';
        counter <= 0;
    end if;                
    
 	if(enable = '1') then
 		if (fullcounter = '1')then
   			if(counter < 63) then
           		if rising_edge(Clk) then
             		DATOUT_DECR <= RanNumber_OUT xor DATIN_ENCR;
             		DATOUT_ADDR <= DATOUT_ADDR + 1;
             		DATIN_ENCR <=  DATIN_ENCR + 1;
             		counter <= counter +1;
            	 end if;
       		end if;
     	end if;   
     end if;
end process decryption;

    end RTL;