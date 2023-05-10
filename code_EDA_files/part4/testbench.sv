`timescale 1ns/1ns

module HW;
  
  wire setReady;
  wire dispReady;

  reg clk;
  reg [2:0] baud_select;
  reg [2:0] wrong_baud_select;
  reg reset;
  reg [7:0] Tx_Data;
  reg Tx_WR;
  reg Tx_EN;
  reg Rx_EN;
  reg [15:0] dataToSend;
  
  //new encoded-decoded data
  wire [7:0] Tx_Data_Encoded;
  wire [7:0] Rx_DATA_Encoded;
  wire RxReady;

  wire TxD;
  wire Tx_BUSY;
  
  wire [7:0] Rx_DATA;
  wire Rx_FERROR;
  wire Rx_PERROR; 
  wire Rx_VALID;
  
  integer data_counter ; 
  
  
  wire sample_ENABLE;
  

  integer cycles;

  
  wire AN3;
  wire AN2;
  wire AN1;
  wire AN0;
 
  
  wire [3:0] myChar0;
  wire [3:0] myChar1;
  wire [3:0] myChar2;
  wire [3:0] myChar3;
  
  wire [7:0] HEX0 ; 
  wire [7:0] HEX1 ; 
  wire [7:0] HEX2 ; 
  wire [7:0] HEX3 ; 
  
  wire [7:0] myHex;

  
  
   
   
  LEDcoder disp0(myChar0, HEX0);
  LEDcoder disp1(myChar1, HEX1);
  LEDcoder disp2(myChar2, HEX2);
  LEDcoder disp3(myChar3, HEX3);
  anodoi Uo(clk,HEX3,HEX2,HEX1,HEX0,AN3,AN2,AN1,AN0,myHex,dispReady);
  
  messageDisp mess(clk,Rx_DATA,Rx_FERROR,Rx_PERROR,Rx_VALID,myChar0,myChar1,myChar2,myChar3,dispReady,setReady,RxReady);
  
  	//input encoded data
  uart_transimitter Ut(reset,clk,Tx_Data_Encoded,baud_select,Tx_WR,Tx_EN,TxD,Tx_BUSY);
  
  //output encoded data
  uart_receiver Ur (reset,clk,Rx_DATA_Encoded,baud_select,Rx_EN,TxD,Rx_FERROR,Rx_PERROR,Rx_VALID);
  
  //input original data - output encoded data
  nrz_i_coder test0(Tx_Data, clk, Tx_Data_Encoded) ; 
  //input encoded data - outout encoded data
  nrz_i_decoder test1(Rx_DATA_Encoded, clk , Rx_DATA,RxReady, Rx_VALID , Rx_FERROR , Rx_PERROR) ; 
  

  
  initial
    begin
      dataToSend=16'b1010000110010100;
      //dataToSend=16'b1100110010111011;

      baud_select=3'b111;
      wrong_baud_select=3'b100;
      Tx_WR=1;
      Rx_EN=1;
      Tx_EN=1;
      Tx_Data=dataToSend[15:8];
      reset=0;
      
      #5 Tx_WR = 0 ; 
    end

  
  initial
    begin
       $dumpfile("dump.vcd"); $dumpvars;
     
    end

  initial begin
    forever begin
      clk<=1;
      #10
      clk<=0;
      #10
      clk <=1;
    end
  end
  initial begin
    #40000 $finish;
  end
  
  always @(posedge setReady) 
    begin 
      Rx_EN <= 0 ; 
      Tx_EN <= 0 ; 
          
      Tx_Data=dataToSend[7:0];
      #10
      Tx_EN<=1;
      Tx_WR<=1;
      Rx_EN<=1;
          
      #5 
      Tx_WR <= 0 ;
      
    end 

  always @(posedge dispReady) 
    begin 
      Rx_EN <= 0 ; 
      Tx_EN <= 0 ;     
      
    end 

  
    endmodule






