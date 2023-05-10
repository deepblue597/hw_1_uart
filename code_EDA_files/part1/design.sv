`timescale 1ns / 1ns 
  
  module LEDcoder( char, LED);
    input wire[3:0] char;
    output reg [7:0] LED;
    
    //translates binary value in char to value for LED in HEX
    always @ (char)
      begin
 
        case(char) 
          4'b0000 : LED[7:0] <= 8'b00000011 ; 
          4'b0001 : LED[7:0] <= 8'b10011111 ; 
          4'b0010 : LED[7:0] <= 8'b00100101 ; 
          4'b0011 : LED[7:0] <= 8'b00001101 ; 
          4'b0100 : LED[7:0] <= 8'b10011001 ; 
          4'b0101 : LED[7:0] <= 8'b01001001 ; 
          4'b0110 : LED[7:0] <= 8'b01000001 ; 
          4'b0111 : LED[7:0] <= 8'b00011111 ; 
          4'b1000 : LED[7:0] <= 8'b00000001 ; 
          4'b1001 : LED[7:0] <= 8'b00001001 ; 
          4'b1010 : LED[7:0] <= 8'b11111101 ; 
          4'b1011 : LED[7:0] <= 8'b01110001 ; 
          4'b1100 : LED[7:0] <= 8'b11111111 ; 
        
        endcase 
    	      
	      
      end
      
  endmodule


module anodoi(clk,HEX3,HEX2,HEX1,HEX0,AN3,AN2,AN1,AN0,myHex);
  input wire clk;
  input wire [7:0] HEX3,HEX2,HEX1,HEX0;
  
  output reg [7:0] myHex;
  output reg AN3,AN2,AN1,AN0;
  
  integer cycles;
  
  //inmplement of fsm
  reg [2:0] current_state, next_state;
  parameter w_closed=3'b100,
  			w_openAN3=3'b011,
  			w_openAN2=3'b010, 
  			w_openAN1=3'b001,
  			w_openAN0=3'b000;
  

    initial
    begin
      AN0=1;
      AN1=1;
      AN2=1;
      AN3=1;
      myHex=0;
      cycles=15;
      current_state=w_closed;
      next_state=w_closed;
    end
  
  
  always @(posedge clk)
    begin
      current_state=next_state;
      
      
       if (cycles==15)
        begin
          cycles=0;
        end
      else
        cycles=cycles+1;
      
      //operation for anodes
       case (cycles)
            4'h2: AN3=0;
            4'h3: AN3=1;
            4'h6: AN2=0;
            4'h7: AN2=1;
            4'hA: AN1=0;
            4'hB: AN1=1;
            4'hE: AN0=0;
            4'hF: AN0=1;

            4'h0:myHex=HEX3;
            4'h4:myHex=HEX2;
            4'h8:myHex=HEX1;
            4'hC:myHex=HEX0;


          endcase

    end
  
  //operation for fsm
  always @(AN3,AN2,AN1,AN0)
    begin
      if (AN3==0)
        next_state=w_openAN3;
      else if (AN2==0)
        next_state=w_openAN2;
      else if (AN1==0)
        next_state=w_openAN1;
      else if (AN0==0)
        next_state=w_openAN0;
      else
        next_state=w_closed;
      
    end
 
endmodule