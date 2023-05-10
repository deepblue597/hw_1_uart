`timescale 1ns/1ns

module HW2;

  reg clk;
  reg [2:0] baud_select;
  reg [2:0] wrong_baud_select;
  reg reset;
  reg [7:0] Tx_Data;
  reg Tx_WR;
  reg Tx_EN;
  reg Rx_EN;
  reg [15:0] dataToSend;

  wire TxD;
  wire Tx_BUSY;
  
  wire [7:0] Rx_DATA;
  wire Rx_FERROR;
  wire Rx_PERROR; 
  wire Rx_VALID;
  
  integer data_counter ; 
  
  
  wire sample_ENABLE;
  
  initial
    begin
      dataToSend=16'b1010100010001000;
      baud_select=3'b111;
      wrong_baud_select=3'b100;
      Tx_WR=1;
      Rx_EN=1;
      Tx_EN=1;
      Tx_Data=dataToSend[15:8];
      reset=0;
      data_counter = 0 ; 
      
      #5 Tx_WR = 0 ; 
    end
  
  
//explicit port mapping for transmitter and receiver
  uart_transimitter Ut(reset,clk,Tx_Data,wrong_baud_select,Tx_WR,Tx_EN,TxD,Tx_BUSY);
  
  uart_receiver Ur (reset,clk,Rx_DATA,baud_select,Rx_EN,TxD,Rx_FERROR,Rx_PERROR,Rx_VALID);
  
  //clock
  initial begin
    forever begin
      clk<=1;
      #10
      clk<=0;
      #10
      clk <=1;
    end
  end
  
  //system
  initial begin
    #27000 $finish;
  end
    initial
    begin
       $dumpfile("dump.vcd"); $dumpvars;
     
    end
  

  // closing the enable signals after communication
  always #1@(posedge Rx_VALID , posedge Rx_FERROR , posedge Rx_PERROR ) 
    begin 
      Rx_EN <= 0 ; 
      Tx_EN <= 0 ; 
    end
  
  //loading the second data set and starting again the communication
  always @(negedge Rx_EN ) 
    begin 
      data_counter = data_counter + 1; 
      if(data_counter == 1) 
        begin 
          Tx_Data=dataToSend[7:0];
          
          #1000
          
          Tx_EN=1;
           Tx_WR=1;
      	   Rx_EN=1;
           
      	   
      	   reset=0;
          
       		#5 Tx_WR = 0 ; 
          
        end
      
    end 
  
endmodule






