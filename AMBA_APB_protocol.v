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
