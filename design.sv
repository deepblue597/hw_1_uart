`timescale 1ns/1ns

module baud_controller(reset, clk, baud_select, sample_ENABLE);
  input wire clk,reset;
  input wire [2:0] baud_select;
  output reg sample_ENABLE;
  
  reg [2:0] baudRate;
  reg [15:0] divisor;
  reg [15:0] baudCounter;
  
  
  initial
    begin
          baudCounter<=0;
          sample_ENABLE<=0;
    end
  
  always @(baud_select)
  begin
    case(baud_select)
      3'b000: divisor=16'd10417;
      3'b001: divisor=16'd2604;
      3'b010: divisor=16'd651;
      3'b011: divisor=16'd326;
      3'b100: divisor=16'd163;
      3'b101: divisor=16'd81;
      3'b110: divisor=16'd54;
      3'b111: divisor=16'd27;
    endcase
  end
  
  always @(posedge clk)
    begin
      if(reset)
        begin
          baudCounter<=0;
          sample_ENABLE<=0;
        end
      else
        begin
          baudCounter<=baudCounter+1;
          if(baudCounter==(divisor-1))
            begin
              sample_ENABLE<=~sample_ENABLE;
              baudCounter<=0;
             
            end     
        end
    end
endmodule


//------------------------------------------------------------



module uart_transimitter(reset,clk,Tx_Data,baud_select,Tx_WR,Tx_EN,TxD,Tx_BUSY);
  input wire reset;
  input wire clk;
  input wire [7:0] Tx_Data;
  input wire [2:0] baud_select;
  input wire Tx_WR;
  input wire Tx_EN;
  output reg TxD;
  output reg Tx_BUSY;
  
  wire Tx_sample_ENABLE;
  
  reg [3:0] tx_counter;
  reg parity_bit;

  reg current_state, next_state ; 
  parameter tx_on = 1'b1 ,
  			 tx_off = 1'b0 ; 
  
  			 
  
  baud_controller baud_controller_tx_instance(reset,clk,baud_select,Tx_sample_ENABLE);
  

  initial 
    begin
     Tx_BUSY<=0;
     tx_counter<=0;
     TxD<=1;
     current_state <= tx_off ; 
     next_state <= tx_off ; 
     parity_bit<=0; 
      
      
    end 
  
  always @(posedge Tx_WR) 
    begin 
      Tx_BUSY<=0;
      tx_counter<=0;
      TxD<=1;
      current_state <= tx_off ; 
      next_state <= tx_off ; 
      parity_bit<=0; 
    end 
  
  
  always @(posedge Tx_sample_ENABLE)
    begin
      if(reset)
        begin
          Tx_BUSY<=0;
          tx_counter<=0;
          TxD<=1;
          current_state <= tx_off ; 
          next_state <= tx_off ; 
          parity_bit<=0;
          
          
        end
      else
        begin
          current_state <= next_state ; 
          if(Tx_EN )
            begin
             
                  Tx_BUSY<=1;
                  
                  if(tx_counter==0)
                    TxD<=1'b0; //start bit
                  else if (tx_counter==10)
                   	TxD<=1'b1; //stop bit
                  else if (tx_counter==9)
                    TxD<=parity_bit;
                  else 
                    begin
                      TxD<=Tx_Data[tx_counter-1];
                      
                      if(Tx_Data[tx_counter-1])
                         if(parity_bit)
                            parity_bit<=0;
                        else
                          parity_bit<=1;
                      
                    end
                  
                  
                   tx_counter<= tx_counter+1;
                  if(tx_counter==11)
                    begin
                      	Tx_BUSY<=0;
                      	TxD<=1;

                      
                    end
                  
                end          

                      
        end     
    end
  
  always @(Tx_EN) 
    begin 
      if( Tx_EN == 1) 
        next_state <= tx_on ; 
      else 
        next_state <= tx_off; 
    end 

endmodule
//------------------------------------------------------------

module uart_receiver (reset,clk,Rx_DATA,baud_select,Rx_EN,RxD,Rx_FERROR,Rx_PERROR,Rx_VALID);
  input wire  reset,clk;
  input wire [2:0] baud_select;
  input wire Rx_EN;
  input wire RxD;
  
  output reg [7:0] Rx_DATA;
  output reg Rx_FERROR;
  output reg Rx_PERROR; 
  output reg Rx_VALID;
  
  wire Rx_sample_ENABLE;
  
  reg [3:0] Rx_counter;
  reg Rx_parity_bit;
  reg Tx_parity_bit;
  reg state;
  reg [7:0] Rx_POS_DATA;


  
  integer i;
  
  reg current_state, next_state ; 
  parameter rx_on = 1'b1 ,
  			 rx_off = 1'b0 ; 
  
  baud_controller baud_controller_rx_instance(reset,clk,baud_select,Rx_sample_ENABLE);
  
  initial 
    begin
      
       Rx_counter<=0;
       Rx_FERROR<=0;
       Rx_PERROR<=0; 
       Rx_VALID<=0;
       state<=0;
       Rx_DATA <= 0 ; 
      current_state <= rx_off ; 
      next_state <= rx_off ; 
      Tx_parity_bit<= 0 ;
       Rx_parity_bit <= 0 ; 
    end 
  
 
  
  
  always  @(negedge RxD)
    begin
      if (Rx_sample_ENABLE==0)
        Rx_FERROR=1;
        
    end
  
  always @(posedge Rx_EN) 
    begin 
        Rx_counter<=0;
        state<=0;
        Rx_FERROR<=0;
        Rx_PERROR<=0;
      	Rx_VALID <= 0; 
        Tx_parity_bit<= 0 ;
        Rx_parity_bit <= 0 ; 
      
    end 
  
  
   
  always @(negedge Rx_sample_ENABLE)
  begin
      if(reset)
        begin
          Rx_counter<=0;
          Rx_FERROR<=0;
          Rx_PERROR<=0; 
          Rx_VALID<=0;
          state<=0;
          Rx_DATA <= 0 ;
          current_state <= rx_off ; 
     	  next_state <= rx_off ; 
          Tx_parity_bit<= 0 ;
          Rx_parity_bit <= 0 ; 
          
          

        end
      else
        begin
          current_state <= next_state ; 
          if(Rx_EN)
           begin
            if(!RxD && !state)
              begin
                state<=1;
                Rx_counter<=Rx_counter+1;
                Rx_VALID<=0;
                Rx_parity_bit<=0;
              end
            else if (state)
              begin
                if (Rx_counter<9)
                  begin
                    Rx_POS_DATA[Rx_counter-1]<=RxD;
                    Rx_counter<=Rx_counter+1;
                    
                    if(RxD)
                          if(Rx_parity_bit)
                            Rx_parity_bit<=0;
                        else
                          Rx_parity_bit<=1;
                  end
                else if (Rx_counter==9)
                  begin
                    Tx_parity_bit =RxD;
                    
                    Rx_counter<=Rx_counter+1;
                      
                    
                    if (Rx_parity_bit!=Tx_parity_bit)
                      Rx_PERROR<=1;

                  end
                else if (Rx_counter==10)
                  begin

                    if(!Rx_PERROR && !Rx_FERROR)
                      begin
                        Rx_VALID<=1;
                        Rx_DATA<=Rx_POS_DATA;

                      end



                  end



                  






              end	//state




          end //enable
    	end //else of reset
        
      
    end	//always block
  
  

  always @(Rx_EN) 
    begin 
      if( Rx_EN == 1) 
        next_state <= rx_on ; 
      else 
        next_state <= rx_off; 
    end 


endmodule
//------------------------------------------------------------


module messageDisp(clk,Rx_DATA,Rx_FERROR,Rx_PERROR,Rx_VALID,myChar0,myChar1,myChar2,myChar3,dispReady,setReady,RxReady);
    input wire [7:0] Rx_DATA;
    input wire Rx_FERROR;
    input wire Rx_PERROR;
    input wire Rx_VALID;
  	input wire clk;
  	input wire RxReady;
  
  	output reg [3:0] myChar0;
  	output reg [3:0] myChar1;
  	output reg [3:0] myChar2;
  	output reg [3:0] myChar3;
  	output reg dispReady;
  	output reg setReady;
    
    reg set;
    reg Valid1, Valid2;
  	
  reg [1:0] current_state,next_state;
  	parameter w_idle=2'b00,
  			w_set1=2'b01,
  			w_set2=2'b10;
  

  
  
  
  	initial
      begin

        dispReady=0;
        setReady=0;
        
        set=0;
        Valid1=0;
        Valid2=0;
        current_state= w_idle;
        next_state= w_idle;
        
      end
  
  always @(posedge clk)
    begin
      current_state=next_state;
    end
  
  always @(posedge RxReady) 
    begin
      
      if(set==0)
        begin
          Valid1 =  Rx_VALID ;
          myChar3=Rx_DATA[7:4];
          myChar2=Rx_DATA[3:0];
          setReady=1;
          dispReady=0;
          set=1;
        end
      else
        begin
          Valid2 =  Rx_VALID ;
          myChar1=Rx_DATA[7:4];
          myChar0=Rx_DATA[3:0];
          
          if(Valid1==0 || Valid2==0 ) 
            begin 
              myChar0=4'b1011 ; 
              myChar1=4'b1011 ; 
              myChar2=4'b1011 ; 
              myChar3=4'b1011 ; 
            end
          dispReady=1;
          setReady=0;
          set=0;
          
          
        end
      
      
    end
  
  always @(set)
    begin
      if (set==0)
        next_state=w_set1;
      else
        next_state=w_set2;
      
    end



endmodule

//------------------------------------------------------------
  module LEDcoder( char, LED);
    input wire[3:0] char;
    output reg [7:0] LED;
    
    
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
//------------------------------------------------------------

module anodoi(clk,HEX3,HEX2,HEX1,HEX0,AN3,AN2,AN1,AN0,myHex,readyAnodes);
  input wire clk;
  input wire readyAnodes;
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
      
      if (readyAnodes)
        begin
      
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

    end
  
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
//------------------------------------------------------------

//IMPLIMENTATION OF ENCODER
module nrz_i_coder( input wire[7:0] Data, 
                   input clk ,
                   output reg[7:0] Encoded_Data)  ;
  
  integer counter ;
  reg start  ;  
  
  initial 
    begin
      counter =  0 ; 
      start = 1'b0 ; 

    end 
  
  always @(posedge clk)
    begin 
      if(counter == 0 )
        
        begin 
         
          if(Data[counter] == 1'b1 )
          Encoded_Data[counter] = ~start ; 
        else 
          Encoded_Data[counter] = start ;
       counter <= counter + 1 ;
       end //counter ==0   
      else if(counter < 8 ) 
        begin
          
          if(Data[counter] == 1'b1 )
          Encoded_Data[counter] <= ~Encoded_Data[counter-1] ; 
        else 
          Encoded_Data[counter] <= Encoded_Data[counter-1] ;
        counter <= counter + 1 ;   
          
        end //counter < 8   
      else 
        counter <= 0 ; 
      
    end 
  
endmodule 
//------------------------------------------------------------

//IMPLIMENTATION OF DECODER
module nrz_i_decoder( input wire[7:0] encoded_Data, 
                   input clk ,
                     output reg[7:0] decoded_Data, output reg RxReady,input wire Rx_VALID , input wire Rx_FERROR , input wire Rx_PERROR)  ;
  
  integer counter ;
  reg start  ; 
  
  initial 
    begin
      counter =  0 ; 
      start = 1'b0 ; 
      RxReady=0;
    end 
  
  always @(posedge Rx_VALID , posedge Rx_FERROR , posedge Rx_PERROR ) 
    begin
      start=1;
      
    end
  
  
  
  always @(posedge clk) 
    begin
      if (start==1)
        begin
          if(counter == 0) 
            begin 
              if(encoded_Data[counter] == 1'b1) 
                decoded_Data[counter] <= 1'b1 ; 
              else 
                decoded_Data[counter] <= 1'b0 ; 
              counter <= counter + 1 ;
              RxReady=0;

            end //counter == 0 
          else if (counter < 8 ) 
            begin 

              if(encoded_Data[counter] != encoded_Data[counter-1]) 
                decoded_Data[counter] <= 1'b1 ; 
              else 
                decoded_Data[counter] <= 1'b0 ; 
              counter <= counter + 1 ; 

            end //counter < 8 
          else 
            begin
            	counter <= 0 ; 
              	start=0;
              	RxReady=1;
              
            end
      end 
    end
   
   
 endmodule
