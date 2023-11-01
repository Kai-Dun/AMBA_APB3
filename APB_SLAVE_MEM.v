module APB_SLAVE_MEM
#(
parameter ADDR_WIDTH = 4,//can be 1 ~ 32bits 
parameter DATA_WIDTH = 4, //can be 1 ~ 32bits 
parameter MEM_DELAY_CYCLE = 0
)
(
	pclk,
	presetn,
	
	//master
	pwrite,
	paddr,
	pwdata,
	psel,
	penable,
	
	//slave
	prdata,
	pready
);
//================================================================
//  input output declaration
//================================================================
input pclk, presetn;
input pwrite;
input [ADDR_WIDTH - 1 : 0] paddr;
input [DATA_WIDTH - 1 : 0] pwdata;
output reg [DATA_WIDTH - 1 : 0] prdata;
output reg pready;

//To slave signal
input psel, penable;

//================================================================
//  variables
//================================================================
integer i;

reg [DATA_WIDTH - 1 : 0] MEM[ (1<<ADDR_WIDTH) -1 : 0];
wire [DATA_WIDTH - 1 : 0] MEM_w[ (1<<ADDR_WIDTH) -1 : 0];

reg [1+$clog2(MEM_DELAY_CYCLE) : 0] cnt;

assign MEM_w = MEM;

always@(posedge pclk, negedge presetn)begin
	if(~presetn)
			cnt <= 0;	
	else begin
		if (cnt == MEM_DELAY_CYCLE)
			cnt <= 0;
		else if(psel & penable)begin
			cnt = cnt + 1;
		end
	end
end

//MEM write data
always@(posedge pclk, negedge presetn)begin
	if(~presetn)begin
		for(i=0;i< (1 << ADDR_WIDTH); i=i+1)
			MEM[i] <= 0;	
	end
	else begin
		if(pwrite & psel & penable)
			MEM[paddr] <= pwdata;
	end
end


//================================================================
//  output
//================================================================
//MEM read data
always@(posedge pclk, negedge presetn)begin
	if(~presetn)begin
		prdata <= 0;
	end
	else begin
		if(~pwrite & psel & penable)
			prdata <= MEM[paddr];
	end
end

//ready
always@(posedge pclk, negedge presetn)begin
	if(~presetn)begin
		pready <= 0;
	end
	else begin
		if(pready == 1'b1)//pulse
			pready <= 0;
		else if(psel & penable & (cnt == MEM_DELAY_CYCLE))//if MEM access needs more than 1 cycle, than & mem_ready signal
			pready <= 1;
	end
end

endmodule 