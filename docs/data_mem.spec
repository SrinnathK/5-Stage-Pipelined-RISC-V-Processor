reg [31:0] mem [0:255];

256 words of 32-bit memory, i.e. a total of
256 × 32 = 8192bits (1 KB of memory).

Each location stores one 32-bit word.

The indices 0 through 255 correspond to word addresses.

memory is word addressable. one word = 4 bytes 
means each memory location stores 32 bits = 4 bytes = 1 word. so total 256 words (256 * 4 = 1024 bytes = 1kB of data memory) 
input [31:0] addr;
word_index = byte_address / 4 is same as dropping the lower 2 bits (addr[1:0])
bits [1:0] (the byte offset).
bits [9:2] as the word address to index into the 256-word memory.

Read is asynchronous, not clocked.
Write is in synchronous with clock, only happens on the positive edge of the clock.

