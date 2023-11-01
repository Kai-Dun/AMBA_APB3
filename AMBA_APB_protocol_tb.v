`timescale 1ns/10ps
`define CYCLE_TIME 10.0

parameter ADDR_WIDTH = 8;//can be 1 ~ 32bits 
parameter DATA_WIDTH = 32;//can be 1 ~ 32bits 


module AMBA_APB_protocol_tb();


reg pclk, presetn, apb_pwrite;
reg [ADDR_WIDTH - 1 : 0] apb_paddr;
reg [DATA_WIDTH - 1 : 0] apb_pwdata;

wire [DATA_WIDTH - 1 : 0] apb_prdata;
wire apb_pready;


always #(`CYCLE_TIME/2) pclk = ~pclk ;

integer i, cnt;
initial begin
	pclk = 0;
	presetn = 0;
	
	#20
	
	reset_task;
	
	write_task;
	
	read_task;
	
	$display("finish");
end

AMBA_APB_protocol
#(
	.ADDR_WIDTH(ADDR_WIDTH),//can be 1 ~ 32bits 
	.DATA_WIDTH (DATA_WIDTH) //can be 1 ~ 32bits 
)
AMBA_APB_protocol_inst
(
		.pclk(pclk),
		.presetn(presetn),
		.apb_pwrite(apb_pwrite),//Read or Write
		.apb_paddr(apb_paddr),
		.apb_pwdata(apb_pwdata),
		.apb_prdata(apb_prdata),
		//APB signal
		.apb_pready(apb_pready)
	);
	
	
	
task reset_task;
	apb_pwrite = 0;
	apb_paddr = 0;
	apb_pwdata = 0;
	
	@(negedge pclk);
	presetn = 0;
	@(negedge pclk);
	presetn = 1;
	
endtask


task write_task;
	@(negedge pclk);
	apb_pwrite = 1;
	
	for(i=0; i < 4;i=i+1)begin
		apb_paddr = i;
		apb_pwdata = i;
		wait_ready;
	end
	
	for(i=(1 << ADDR_WIDTH - 1); i < (1 << ADDR_WIDTH - 1) + 4 ;i=i+1)begin
		apb_paddr = i;
		apb_pwdata = i;
		wait_ready;
	end
	
endtask
	

task read_task;
	@(negedge pclk);
	apb_pwrite = 0;
	
	for(i=0; i < 4;i=i+1)begin
		apb_paddr = i;
		apb_pwdata = i;
		wait_ready;
	end
	
	for(i=(1 << ADDR_WIDTH - 1); i < (1 << ADDR_WIDTH - 1) + 4;i=i+1)begin
		apb_paddr = i;
		apb_pwdata = i;
		wait_ready;
	end
endtask	

task wait_ready;
	cnt = 0;
	while(~apb_pready)begin
		@(negedge pclk);
		cnt = cnt + 1;
		
		if(cnt>8) begin
			   $display ("---------------------------------------------------------------------------------------");
            $display ("                                         FAIL!                                         ");
            $display ("                    apb_paddr = %d, apb_pwdata = %d                      ",apb_paddr,apb_pwdata);
            $display ("---------------------------------------------------------------------------------------");
				break;
		end
	end
	
	@(negedge pclk);
endtask

endmodule 

	