-- Code your testbench here
-- or browse Examples
-- This simple code will verify the KNUST MIPS processor design
-- Eyeball self checking auto TestBench

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

-- Empty Entity Declaration
entity KNUST_MIPS_VERIFY_tb is 
-- port() -- No port declaration
end KNUST_MIPS_VERIFY_tb;

architecture behaviour of KNUST_MIPS_VERIFY_tb is


-- Component declaration
component pipeLinedProcessor 
   port(

        clk : in std_logic;
        reset :in std_logic;
        instr : in std_logic_vector(31 downto 0);
        readdata : in std_logic_vector(31 downto 0);
        aluout : out std_logic_vector(31 downto 0);
	pc : out std_logic_vector(31 downto 0);
        writedata :out std_logic_vector(31 downto 0);
        memwrite : out std_logic
      
       );
end component;


-- Signal Declaration
-- Inputs
        signal clk : std_logic;  
        signal reset : std_logic;
        signal instr : std_logic_vector(31 downto 0);
        signal readdata : std_logic_vector(31 downto 0);

        -- Expected Output Signal
        signal expected_result : std_logic_vector(31 downto 0);
-- Outputs
	signal pc: std_logic_vector(31 downto 0);
        signal aluout : std_logic_vector(31 downto 0);
        signal writedata : std_logic_vector(31 downto 0);
        signal memwrite : std_logic;
       
        


-- Clock Period Definition
constant ClkPeriod : time := 10 ns;

--Instantiate KNUST MIPS Processor

begin 
	dut : pipeLinedProcessor port map(
    	
        clk   => clk,
        reset => reset,
        instr => instr,
        aluout => aluout,
        writedata => writedata,
	pc => pc,
        memwrite => memwrite,
        readdata => readdata
    
    );
 
-- Clock Process Definition

    clk_process : process
    
        begin
          clk <= '1';
        wait for ClkPeriod/2;
          clk <= '0';
        wait for ClkPeriod/2;
        
     end process;

-- at start of test, pulse reset

   -- process begin 

     -- reset <= '1'; 
      --wait for 27 ns ;
     -- reset <= '0';

   -- end process;


 -- run tests and check results

     process is 

	  file tv: text ;
          variable L: line;
          variable vector_in : std_logic_vector(31 downto 0);
          variable dummy : character;
          variable vector_out : std_logic_vector(31 downto 0);
          variable vectornum : integer := 0;
          variable errors: integer :=0;

     begin 
 
     file_open(tv, "Stimulus_Expect.tv", read_mode);
     while not endfile(tv) loop

     -- change vectors on rising edge
     wait until rising_edge(clk);
      
     -- read the next line of testvectors and split into pieces

     readline(tv, L);
     read(L, vector_in);
     read(L, dummy); -- skip over underscore
     
     read(L, vector_out);
     instr <= vector_in(31 downto 0) after 1 ns ;
     expected_result <= vector_out(31 downto 0) after 1 ns;
     

     -- Check results on falling edge
     --wait until falling_edge(clk);
    
     wait for ClkPeriod*5;
     if aluout /= expected_result then

        report "Error: aluout = " & integer'image(to_integer(unsigned(aluout)));
        errors := errors+1;

     end if; 

     vectornum := vectornum+1;

     end loop;

     -- summarize results at the end of simulation
     if(errors = 0) then
        report "No Errors -- " &
                integer'image(vectornum)&
                  "tests completed successfully."
                 severity failure;

      else 
         report integer'image(vectornum) &
                 "test completed, error =" & 
                  integer'image(errors)
                   severity failure;
      end if;

 end process;


end architecture;


          

 


