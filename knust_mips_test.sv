`timescale 1ns/1ps

module KNUST_MIPS_VERIFY_tb;

  // Clock period
  localparam time ClkPeriod = 10ns;

  // DUT inputs
  logic         clk;
  logic         reset;
  logic [31:0]  instr;
  logic [31:0]  readdata;

  // DUT outputs
  logic [31:0]  aluout;
  logic [31:0]  pc;
  logic [31:0]  writedata;
  logic         memwrite;

  // Expected output
  logic [31:0]  expected_result;

  // -------------------------
  // DUT instantiation
  // -------------------------
  pipeLinedProcessor dut (
    .clk       (clk),
    .reset     (reset),
    .instr     (instr),
    .readdata  (readdata),
    .aluout    (aluout),
    .pc        (pc),
    .writedata (writedata),
    .memwrite  (memwrite)
  );

  // -------------------------
  // Clock generation
  // -------------------------
  initial begin
    clk = 1'b0;
    forever #(ClkPeriod/2) clk = ~clk;
  end

  // -------------------------
  // Optional reset pulse 
  // -------------------------
  initial begin
    reset = 1'b0;
    // reset = 1'b1;
    // #27ns;
    // reset = 1'b0;
  end

  // You can drive readdata if needed; otherwise keep it 0
  initial begin
    readdata = 32'd0;
  end

  // -------------------------
  // Test runner
  // -------------------------
  initial begin : run_vectors
    int fd;
    int vectornum = 0;
    int errors    = 0;

    string line;
    string in_str, out_str;
    bit dummy_ok;

    // Default values
    instr           = '0;
    expected_result = '0;

    fd = $fopen("Stimulus_Expect.tv", "r");
    if (fd == 0) begin
      $fatal(1, "ERROR: Could not open Stimulus_Expect.tv");
    end

    // Read file line-by-line
    while (!$feof(fd)) begin
      line = "";
      void'($fgets(line, fd));

      // Skip empty lines / comments (optional)
      if (line.len() == 0) continue;
      if (line.tolower().substr(0,0) == "#") continue;

      // Parse: 32 bits, underscore, 32 bits (binary strings)
      // Example line: 000...001_000...100
      dummy_ok = ($sscanf(line, "%32s_%32s", in_str, out_str) == 2);
      if (!dummy_ok) begin
        // If your file has spaces, try a more forgiving parse:
        // dummy_ok = ($sscanf(line, " %32s _ %32s", in_str, out_str) == 2);
        $display("WARNING: Skipping unparseable line: %s", line);
        continue;
      end

      // Apply on rising edge (like your VHDL)
      @(posedge clk);

      // Small 1ns application delay to mimic "after 1 ns"
      #1ns;
      instr           = in_str;   // SystemVerilog can assign 0/1 string to logic vectors
      expected_result = out_str;

      // Wait ClkPeriod*5 then check aluout (like your VHDL)
      #(ClkPeriod*5);

      if (aluout !== expected_result) begin
        $display("Error @ vector %0d: aluout=%0d (0x%08h) expected=%0d (0x%08h)",
                 vectornum,
                 $unsigned(aluout), aluout,
                 $unsigned(expected_result), expected_result);
        errors++;
      end

      vectornum++;
    end

    $fclose(fd);

    // Summary (mirrors your VHDL 'severity failure' termination)
    if (errors == 0) begin
      $display("No Errors -- %0d tests completed successfully.", vectornum);
      $fatal(0); // end sim (similar effect to severity failure)
    end else begin
      $display("%0d tests completed, errors = %0d", vectornum, errors);
      $fatal(1);
    end
  end

endmodule
