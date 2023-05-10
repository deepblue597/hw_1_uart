`timescale 1ns/1ns

//IMPLEMANTION OF BAUD CONTROLLER
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
  
  //finds in clock cycles for our selection
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
  
  //implementation of the sample clock
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


//IMPLEMENTATION OF TRANSIMITTER
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

  //fsm
  reg current_state, next_state ; 
  parameter tx_on = 1'b1 ,
  			 tx_off = 1'b0 ; 
  
  			 
  //creating clock for the tx
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
  
  //when there are new data availiable
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
              //data transmit
             
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
                      
                      //calculates parity
                      if(Tx_Data[tx_counter-1])
                         if(parity_bit)
                            parity_bit<=0;
                        else
                          parity_bit<=1;                    
                    end
                                    
                   tx_counter<= tx_counter+1;
              
              //when transmit ends
                  if(tx_counter==11)
                    begin
                      	Tx_BUSY<=0;
                      	TxD<=1;

                      
                    end
                  
                end          

                      
        end     
    end
  
  //fsm state accordingly Tx_EN signal
  always @(Tx_EN) 
    begin 
      if( Tx_EN == 1) 
        next_state <= tx_on ; 
      else 
        next_state <= tx_off; 
    end 

endmodule
//------------------------------------------------------------

//IMPLEMENTATION OF RECEIVER
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
  
  //FSM
  reg current_state, next_state ; 
  parameter rx_on = 1'b1 ,
  			 rx_off = 1'b0 ; 
  
  //clock for the Rx
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
  
 
  
  //checking for correct clocks between Tx and Rx
  always  @(negedge RxD)
    begin
      if (Rx_sample_ENABLE==0)
        Rx_FERROR=1;
        
    end
  
  //initiation of the signals for start of receiving
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
  
  
  //half period after of transmiting 
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
    //Data Receiving 
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
                    
                    //calculate parity bit
                    if(RxD)
                          if(Rx_parity_bit)
                            Rx_parity_bit<=0;
                        else
                          Rx_parity_bit<=1;
                  end
                else if (Rx_counter==9)
                  begin
                    Tx_parity_bit =RxD;
                    //Tx_parity_bit =0;
                    Rx_counter<=Rx_counter+1;
                      
                    //checking for correct parity
                    if (Rx_parity_bit!=Tx_parity_bit)
                      Rx_PERROR<=1;

                  end
                else if (Rx_counter==10)
                  begin

                    
                    //checking if the receiving is valid
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
  
  
  //fsm state accordingly Rx_EN signal
  always @(Rx_EN) 
    begin 
      if( Rx_EN == 1) 
        next_state <= rx_on ; 
      else 
        next_state <= rx_off; 
    end 


endmodule

