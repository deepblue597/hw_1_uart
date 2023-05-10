`timescale 1ns / 1ns 

module sys ;

  reg clk;
  integer cycles;
  integer theChar;
  
  wire AN3;
  wire AN2;
  wire AN1;
  wire AN0;
 
  
  reg [3:0] myChar0;
  reg [3:0] myChar1;
  reg [3:0] myChar2;
  reg [3:0] myChar3;
  
  wire [7:0] HEX0 ; 
  wire [7:0] HEX1 ; 
  wire [7:0] HEX2 ; 
  wire [7:0] HEX3 ; 
  
  wire [7:0] myHex;  
   
  //explicit port mapping
  LEDcoder disp0(myChar0, HEX0);
  LEDcoder disp1(myChar1, HEX1);
  LEDcoder disp2(myChar2, HEX2);
  LEDcoder disp3(myChar3, HEX3);
  anodoi Uo(clk,HEX3,HEX2,HEX1,HEX0,AN3,AN2,AN1,AN0,myHex);
  
  initial
    begin
      theChar=0;
      
      //number -194
      myChar3=4'b1010;
      myChar2=4'b0001;
      myChar1=4'b1001;
      myChar0=4'b0100;
      
    end
  
  
  //code for clock implementation
   initial begin
    forever begin
      clk<=1;
      #10
      clk<=0;
      #10
      clk <=1;
    end
  end
  
  //run time for our simulation
  initial begin
    #1280 $finish;
  end
  
  initial
        begin
         $dumpfile("dump.vcd"); $dumpvars;
        end
  
  initial
    begin
      cycles=15;
    end
  
  //code for data change
  always @(posedge clk)
    begin
      if (cycles==15)
        cycles=0;
      else
        cycles=cycles+1;
      
      if (cycles==15)
        begin
           theChar=theChar+1;
          
          case(theChar)
            4'h1:	//number __10
              begin
                myChar3=4'b1100;
      			myChar2=4'b1100;
      			myChar1=4'b0001;
      			myChar0=4'b0000;
              end
             4'h2:	//number _-32
              begin
                myChar3=4'b1100;
      			myChar2=4'b1010;
      			myChar1=4'b0011;
      			myChar0=4'b0010;
              end
             4'h3:	//number FFFF
              begin
                myChar3=4'b1011;
      			myChar2=4'b1011;
      			myChar1=4'b1011;
      			myChar0=4'b1011;
              end
          endcase
        end
    end
  
endmodule
