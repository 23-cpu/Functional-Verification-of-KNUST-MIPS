library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity KNUST_MIPS_VERIFY_tb is
end KNUST_MIPS_VERIFY_tb;

architecture behaviour of KNUST_MIPS_VERIFY_tb is

    component pipeLinedProcessor 
        port(
            clk        : in std_logic;
            reset      : in std_logic;
            instr      : in std_logic_vector(31 downto 0);
            readdata   : in std_logic_vector(31 downto 0);
            aluout     : out std_logic_vector(31 downto 0);
            pc         : out std_logic_vector(31 downto 0);
            writedata  : out std_logic_vector(31 downto 0);
            memwrite   : out std_logic
        );
    end component;

    -- Signals
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal instr       : std_logic_vector(31 downto 0) := (others => '0');
    signal readdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal aluout      : std_logic_vector(31 downto 0);
    signal pc          : std_logic_vector(31 downto 0);
    signal writedata   : std_logic_vector(31 downto 0);
    signal memwrite    : std_logic;

    -- Expected outputs
    signal exp_aluout     : std_logic_vector(31 downto 0);
    signal exp_pc         : std_logic_vector(31 downto 0);
    signal exp_writedata  : std_logic_vector(31 downto 0);
    signal exp_memwrite   : std_logic;

    constant ClkPeriod : time := 10 ns;

begin

    -- DUT
    dut: pipeLinedProcessor
        port map (
            clk       => clk,
            reset     => reset,
            instr     => instr,
            readdata  => readdata,
            aluout    => aluout,
            pc        => pc,
            writedata => writedata,
            memwrite  => memwrite
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '1';
            wait for ClkPeriod / 2;
            clk <= '0';
            wait for ClkPeriod / 2;
        end loop;
    end process;

    -- Reset logic
    reset_process : process
    begin
        reset <= '1';
        wait for 2 * ClkPeriod;
        reset <= '0';
        wait;
    end process;

    -- Stimulus and checker
    stim_proc : process
        file tv : text open read_mode is "Stimulus_Expect.tv";
        variable L        : line;
        variable vec_instr      : std_logic_vector(31 downto 0);
        variable vec_aluout     : std_logic_vector(31 downto 0);
        variable vec_pc         : std_logic_vector(31 downto 0);
        variable vec_writedata  : std_logic_vector(31 downto 0);
        variable vec_memwrite   : std_logic;

        variable vectornum : integer := 0;
        variable errors    : integer := 0;

    begin
        wait until reset = '0';

        while not endfile(tv) loop
            wait until rising_edge(clk);

            -- Read one test vector
            readline(tv, L);
            read(L, vec_instr);
            read(L, vec_aluout);
            read(L, vec_pc);
            read(L, vec_writedata);
            read(L, vec_memwrite);

            -- Drive input and expected outputs
            instr         <= vec_instr after 1 ns;
            exp_aluout    <= vec_aluout after 1 ns;
            exp_pc        <= vec_pc after 1 ns;
            exp_writedata <= vec_writedata after 1 ns;
            exp_memwrite  <= vec_memwrite after 1 ns;

            wait for 3 * ClkPeriod;

            -- Check all outputs
            if aluout /= exp_aluout then
                report "ALU Mismatch @ vector " & integer'image(vectornum) &
                       ": got " & to_hstring(aluout) & 
                       ", expected " & to_hstring(exp_aluout)
                       severity warning;
                errors := errors + 1;
            end if;

            if pc /= exp_pc then
                report "PC Mismatch @ vector " & integer'image(vectornum) &
                       ": got " & to_hstring(pc) &
                       ", expected " & to_hstring(exp_pc)
                       severity warning;
                errors := errors + 1;
            end if;

            if writedata /= exp_writedata then
                report "WRITEDATA Mismatch @ vector " & integer'image(vectornum) &
                       ": got " & to_hstring(writedata) &
                       ", expected " & to_hstring(exp_writedata)
                       severity warning;
                errors := errors + 1;
            end if;

            if memwrite /= exp_memwrite then
                report "MEMWRITE Mismatch @ vector " & integer'image(vectornum) &
                       ": got " & std_logic'image(memwrite) &
                       ", expected " & std_logic'image(exp_memwrite)
                       severity warning;
                errors := errors + 1;
            end if;

            vectornum := vectornum + 1;
        end loop;

        report "===========================================";
        report "Test complete. Vectors tested: " & integer'image(vectornum);
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TOTAL ERRORS: " & integer'image(errors) severity error;
        end if;
        report "===========================================";

        wait;
    end process;

end architecture;
