module AMBA_APB_protocol
#(
parameter ADDR_WIDTH = 4,//can be 1 ~ 32bits 
parameter DATA_WIDTH = 4 //can be 1 ~ 32bits 
)
(
	pclk,
	presetn,
	apb_pwrite,//Read or Write
	apb_paddr,
	apb_pwdata,
	apb_prdata,
	//APB signal
	apb_pready
);


input pclk, presetn, apb_pwrite;
input [ADDR_WIDTH - 1 : 0] apb_paddr;
input [DATA_WIDTH - 1 : 0] apb_pwdata;

output [DATA_WIDTH - 1 : 0] apb_prdata;
output apb_pready;

//================================================================
//  variables
//================================================================
wire pwrite;
wire [ADDR_WIDTH - 1 : 0] paddr;
wire [DATA_WIDTH - 1 : 0] pwdata;
wire psel1, psel2, penable;

wire pready, pready_slave1, pready_slave2;
wire [DATA_WIDTH -1 : 0] prdata, prdata_slave1, prdata_slave2;

//================================================================
//  APB Master
//================================================================

assign pready = apb_paddr[ADDR_WIDTH - 1] ? pready_slave2 : pready_slave1;
assign prdata = apb_paddr[ADDR_WIDTH - 1] ? prdata_slave2 : prdata_slave1;


APB_MASTER
#(
	.ADDR_WIDTH(ADDR_WIDTH),//can be 1 ~ 32bits 
	.DATA_WIDTH(DATA_WIDTH) //can be 1 ~ 32bits 
)
APB_MASTER_inst
(
	.pclk(pclk),
	.presetn(presetn),
	//Top moudle signal
	.apb_pwrite(apb_pwrite),
	.apb_paddr(apb_paddr),
	.apb_pwdata(apb_pwdata),
	.apb_prdata(apb_prdata),
	.apb_pready(apb_pready),
	
	//master
	.pwrite(pwrite),
	.paddr(paddr),
	.pwdata(pwdata),
	.psel1(psel1),
	.psel2(psel2),
	.penable(penable),
	
	//slave
	.prdata(prdata),
	.pready(pready)
);


//================================================================
//  APB Slave
//================================================================
APB_SLAVE_MEM
#(
	.ADDR_WIDTH(ADDR_WIDTH-1),//can be 1 ~ 32bits 
	.DATA_WIDTH(DATA_WIDTH), //can be 1 ~ 32bits 
	.MEM_DELAY_CYCLE(0)
)
APB_SLAVE_MEM_slave1
(
	.pclk(pclk),
	.presetn(presetn),
	
	//master
	.pwrite(pwrite),
	.paddr(paddr[ADDR_WIDTH - 2 : 0]),
	.pwdata(pwdata),
	.psel(psel1),
	.penable(penable),
	
	//slave
	.prdata(prdata_slave1),
	.pready(pready_slave1)
);


APB_SLAVE_MEM
#(
	.ADDR_WIDTH(ADDR_WIDTH-1),//can be 1 ~ 32bits 
	.DATA_WIDTH(DATA_WIDTH), //can be 1 ~ 32bits 
	.MEM_DELAY_CYCLE(3)
)
APB_SLAVE_MEM_slave2
(
	.pclk(pclk),
	.presetn(presetn),
	
	//master
	.pwrite(pwrite),
	.paddr(paddr[ADDR_WIDTH - 2 : 0]),
	.pwdata(pwdata),
	.psel(psel2),
	.penable(penable),
	
	//slave
	.prdata(prdata_slave2),
	.pready(pready_slave2)
);


endmodule 



//================================================================
//  Sub Module
//================================================================

module APB_MASTER
#(
parameter ADDR_WIDTH = 4,//can be 1 ~ 32bits 
parameter DATA_WIDTH = 4 //can be 1 ~ 32bits 
)
(
	pclk,
	presetn,
	//Top moudle signal
	apb_pwrite,
	apb_paddr,
	apb_pwdata,
	apb_prdata,
	apb_pready,
	
	//master
	pwrite,
	paddr,
	pwdata,
	psel1,
	psel2,
	penable,
	
	//slave
	prdata,
	pready
);

//================================================================
//  input output declaration
//================================================================
input pclk, presetn;
//write
input apb_pwrite;
output pwrite;
//addr
input [ADDR_WIDTH - 1 : 0] apb_paddr;
output [ADDR_WIDTH - 1 : 0] paddr;
//data
input [DATA_WIDTH - 1 : 0] prdata, apb_pwdata;
output [DATA_WIDTH - 1 : 0] pwdata, apb_prdata;
//ready
input pready;
output apb_pready;
//To slave signal
output psel1, psel2;
output reg penable;

//================================================================
//  variables
//================================================================
//determine transfer switching
reg [ADDR_WIDTH - 1 : 0] apb_paddr_r;
reg [DATA_WIDTH - 1 : 0] pwdata_r;
reg apb_pwrite_r;
wire transfer;
reg transfer_r;
reg pready_r;
wire psel;

//determine transfer switching
always@(posedge pclk, negedge presetn)begin
	if(~presetn) begin
		apb_paddr_r <= 0;
		pwdata_r <= 0;
		apb_pwrite_r <= 0;
	end
	else begin
		apb_paddr_r <= apb_paddr;
		apb_pwrite_r <= pwrite;
		
		if(apb_pwrite) //if there is read mode, don't care pwdata
			pwdata_r <= pwdata;
	end
end

assign transfer = (apb_paddr != apb_paddr_r | apb_pwrite != apb_pwrite_r | pwdata != pwdata_r);//if any input changes

always@(posedge pclk, negedge presetn)begin
	if(~presetn) 
		transfer_r <= 0;
	else begin
		if(~pready)
			transfer_r <= transfer_r ^ transfer;
		else
			transfer_r <= 0;
	end
end

always@(posedge pclk, negedge presetn)begin
	if(~presetn) 
		pready_r <= 0;
	else begin
		pready_r <= pready;
	end
end


//================================================================
//  output
//================================================================
//output psel1, psel2;
assign psel = (transfer | transfer_r); //pready 1 > 0, psel = 0; but if transfer = 1, psel = 1
assign psel1 = psel & (~paddr[ADDR_WIDTH - 1]);//my define, If the addr exceeds half of the total MEM size, select MEM 1.
assign psel2 = psel & (paddr[ADDR_WIDTH - 1]);//my define, otherwize, select MEM 2.

//output penable;
always@(posedge pclk, negedge presetn)begin
	if(~presetn) 
		penable <= 0;
	else begin
		if(pready)
			penable <= 0;
		else
			penable <= psel;
	end
end

//by pass data
//addr
assign paddr = apb_paddr;
//data
assign pwdata = apb_pwdata;
assign apb_prdata = prdata;
//ready
assign apb_pready = pready;
//write
assign pwrite = apb_pwrite;

endmodule 