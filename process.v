`timescale 1ns / 1ps

module process (
        input                clk,		    	// clock 
        input  [23:0]        in_pix,	        // valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
        input  [8*512-1:0]   hiding_string,     // sirul care trebuie codat
        output [6-1:0]       row, col, 	        // selecteaza un rand si o coloana din imagine
        output               out_we, 		    // activeaza scrierea pentru imaginea de iesire (write enable)
        output [23:0]        out_pix,	        // valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
        output               gray_done,		    // semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
        output          compress_done,		// semnaleaza terminarea actiunii de compresie (activ pe 1)
        output          encode_done        // semnaleaza terminarea actiunii de codare (activ pe 1)
    );	
		  reg [4:0] state=0, next_state;
		  
		  //variabilele pentru task1 
        reg [6-1:0] r=0, c=0;  			//row si col, la finalul automatului am o instructiune assign
		  reg done=1;           		   //semnalul done despre care am mentionat in precizari initiale
        reg  out_we_c=0; 				   //out_we, la finalull automatului am o instructiune assign  
        reg [23:0] out_pix_c;	 			//out_pix, la finalul automatului am o instructiune assign      
        reg g_done=0;		    			//grey_done
        reg c_done=0;		    			//compress_done
        reg e_done=0;  			 			//encode_done
		  reg [7:0] max,min;	    			// minim si maxim, folosite pentru determinarea mediei corespunzatoare task1
		  
		  //variabile pentru task 2
		  reg [23:0] matrix [3:0][3:0]; 	//o matrice secundara in care copii pe rand blocuri de 4x4 elemente din matricea de pixeli
		  reg [4:0] r_m,c_m;				  	//row_matrice, col_matrice, folosite in partea de citire si scriere pentru a retine la ce element al matricii am ajuns					
		  reg [4:0] i=0,j=0;				  	// folosite in buclele for
		  reg [24:0]sum;                	// suma elemenetelor pentru calcularea AVG
		  reg [24:0] avg;  				  	//AVG
		  reg [24:0] var;					  	//var
		  reg [24:0]sum2;  				  	//suma elemnetlor pentru calcularea var
		  reg[4:0]counter;				   //numara aparitia de 1 intr-o matrice secundara, beta
		  reg[23:0] lm; 					   //Lm	
		  reg[23:0]hm;                   //Hm
		  
		  //variabile pentru task3
		  reg [23:0] matrix2 [3:0][3:0];  //o matrice secundara, identica cu cea de la task2, avand aceeleasi atributii
		  reg [23:0]aux;                  //variabila auxiliara prin care interschimb Lm si Hm
		  reg  [50:0]  index_string=0;	 //un pointer prin care sunt citite, pe rand, cate 16 biti din	hiding_string, imi retine pozitia de unde incepe citirea si se incrementeaza
		  reg lm_found =0;                //devine 1 in momentul in care Lm a fost identificat in matrix2
		  reg hm_found =0;					 //devine 1 in momentul in care Hm a fost identificat in matrix2
		  reg [15:0] i_lm,j_lm,i_hm,j_hm; //variabile care retin pozitiile pe care am identificat Lm si Hm
		  reg [31:0] base3_index;			 //un pointer prin care sunt citite, pe rand, cate 2 biti din base3_aux, retine pozitia de inceput a citirii si se incrementeaza	
		  reg [31:0] base3_aux;				 //variabila auxiliara in care este citita valoare in baza3 de la iesirea modulului base2_to_base3
		
//instantierea modulului base2_to_base3
			wire [31:0] base3; 				 //numarul in baza3 care este rezultate din transformare
			wire ok;          				 //semnalul care ne arata daca transformarea a fost cu succes
			reg [15:0] base2;  				 //numarul in baza2 care trebuie transformat
			reg en=0;			             //semnalul care porneste modulul base2_to_base3
			base2_to_base3 b2_to_b3(base3,ok,base2,en,clk);
		  
always @(posedge clk) begin
		state <= next_state;
end


always@(*) begin 

	case(state)
	
	//TASK1
	
	0: begin
		
		max=0;
		min=0;
		done=1;
		
		next_state=1;
	end
	1: begin
	
		max=(in_pix[23:16]>in_pix[15:8])?in_pix[23:16]:in_pix[15:8];
		max=(max>in_pix[7:0])?max:in_pix[7:0];
		min=(in_pix[23:16]<in_pix[15:8])?in_pix[23:16]:in_pix[15:8];
		min=(min<in_pix[7:0])?min:in_pix[7:0];
		out_we_c=1;
		
		next_state=2;
		
		
	end
	
	2: begin
		
		out_pix_c[23:16]=8'b0;
		out_pix_c[7:0]=8'b0;
		out_pix_c[15:8]=(min+max)/2;
		
		next_state=3;
		
	end
	
	3: begin
		out_we_c=0;
		if(c==63 && r!=63 && done==1)
			begin
				c=0;
				r=r+1;
				done=0;
				
				next_state=0;
				
			end
		if(c!=63 && done==1)
		begin
			c=c+1;
			done=0;
			
			next_state=0;
		end
		if(c==63 && r==63 && done==1)
		begin
			done=0;
			
			next_state=4;
		end
		
	end
	
	//TASK2
	
	4: begin
		g_done=1;
		r=0;
		c=0;
		r_m=0;
		c_m=0;
		done=1;
		
		next_state=5;
		
	end
	5: begin
		if(done==1)
		begin
			matrix[r_m][c_m]=in_pix;
			done=0;
		end
		
		next_state=6;
		
	
	end
	
	6: begin
			if(r_m==3 && c_m==3 && done==0) //s-a finalizat citirea matricei de 4x4
			begin 
				done=1;
				sum=0;
				sum2=0;
				avg=0;
				
				next_state=7; //mergem la efectuarea calculelor
			end
			
			if(c_m==3 && r_m!=3 && done==0) //nu s-a finalizatat citirea matricei de 4x4
			begin 
				done=1;
				
				//incrementarea matricei de 4x4
				c_m=0;
				r_m=r_m+1;
				
				//incrementarea matricei de pixeli mare
				c=c-3;
				r=r+1;
				
				next_state=5;
			end
			
			if(c_m!=3 && done==0) 
			begin
			   done=1;
				c_m=c_m+1;
				c=c+1;
				
				next_state=5;
				
			end
			
			
	end
	
	7:begin //AVG
	
	
	//se calculeaza media aritmetica
	for(i=0;i<4;i=i+1) begin
		for(j=0;j<4;j=j+1) begin
			sum=sum+matrix[i][j][15:8];
		end
	end
	avg=sum/16;
	
	next_state=8;
	
	end
	
	8: begin //se calculeaza deviata var
	for(i=0;i<4;i=i+1) begin
		for(j=0;j<4;j=j+1) begin
			if(matrix[i][j][15:8]>avg)  //pentru a face modulul
			begin
				sum2=sum2+(matrix[i][j][15:8]-avg);
			end else
			begin
				sum2=sum2+(avg-matrix[i][j][15:8]);
			end	
		end
	end
	var=sum2/16;	
	counter=0;
	
	next_state=9;
	end
	9: begin //mapare cu 0 si 1
	for(i=0;i<4;i=i+1) begin
		for(j=0;j<4;j=j+1) begin
			if(matrix[i][j][15:8]<avg) 
			begin
				matrix[i][j]=0;
			end else
			begin
				matrix[i][j]=1;
				counter=counter+1;
			end
		end
	end
	lm=0;
	hm=0;
	
	next_state=10;
	end
	
	10: begin //calculare lm si hm
		lm=avg-((16*var)/(32-2*counter));
		hm=avg+8*var/counter;
		done=1;
		
		next_state=11;
	end
		
	11:begin //refacere matrice
		for(i=0;i<4;i=i+1) begin
		  for(j=0;j<4;j=j+1) begin
			if(matrix[i][j]==23'b0)
			begin
				matrix[i][j][15:8]=lm;
			end else
			begin
				matrix[i][j][15:8]=hm;
				matrix[i][j][7:0]=0;
				
			end
		end

		end
		done=1;
		
		next_state=16;

		end	
	//aici incepe partea de scriere pe matricea mare
	16: begin
	if(done==1) 
	begin
		out_we_c=1;
		r=r-3;
		c=c-3;
		r_m=0;
		done=0;
		c_m=0;
	end
	
	next_state=12;
	
	
	end	
	
	12:begin
		out_pix_c=matrix[r_m][c_m];
		done=1;
		
		next_state=13;
	end
	
   13:begin
			if(r_m==3 && c_m==3 && done==1) //s-a finalizat de scris matricea de 4x4
			begin 
				done=0;
				
				next_state=14; //incep implementarea unei noi matrice
			end
			
			if(c_m==3 && r_m!=3 && done==1) begin //nu s-a finalizat de scri matricea de 4x4
				done=0;
				//incrementarea matricei de 4x4 
				c_m=0;
				r_m=r_m+1;
				
				//incrementarea matricei de pixeli mare
				c=c-3;
				r=r+1;
				
				next_state=12;
			end
			
			if(c_m!=3 && done==1) begin
			   done=0;
				c_m=c_m+1;
				c=c+1;
				
				next_state=12;
				
			end
			
			
	end
	14: begin
		if(c==63 && r==63 && done==0) //cum nu am vrut o stare auxiliara doar ca sa fac done=1, am decis ca pentru acest set de if-uri sa il folosesc ca 0
		begin
			done=1;
			
			next_state=15; //s-a completat toata matricea
		
		end
		
		if(c==63 && r!=63 && done==0)
		begin
			c=0;
			r=r+1;
			done=1;		
			r_m=0;
			c_m=0;
			done=1;
			next_state=5;
		end
		
		if(c!=63  && done==0)
		begin
			r=r-3;
			c=c+1;
			r_m=0;
			c_m=0;
			done=1;
			next_state=5;
		end
	end
	
	15:begin
	
	c_done=1;
	
	next_state=17;
	
	end


	//TASK3
	
	17: begin //starea de start a task3
	
		lm=0;
		hm=0;
		r=0;
		c=0;
		lm=0;
		hm=0;
		r_m=0;
		c_m=0;
		done=1;
		
		next_state=18;
		
	end
	18: begin
	
		if(done==1)
		begin
			matrix2[r_m][c_m]=in_pix;
			done=0;
		end
		
		next_state=19;
	end
	
	19: begin
			if(r_m==3 && c_m==3 && done==0) //s-a finalizat citirea matricei matrix2
			begin 
				done=1;
				lm=matrix2[0][0]; //nota --> pentru a rezolva cazurile in care matrix2 are toate elementele egale, atat hm cat si lm vor fi initializate cu prima valoare din matrice
				hm=matrix2[0][0];
				
				next_state=20; 
				
			end
			
			if(c_m==3 && r_m!=3 && done==0) 
			begin
				done=1;
				//incrementarea matricei de 4x4
				c_m=0;
				r_m=r_m+1;
				
				//incrementarea matricei de pixeli mare
				c=c-3;
				r=r+1;
				
				next_state=18;
			end
			
			if(c_m!=3 && done==0) 
			begin
			   done=1;
				c_m=c_m+1;
				c=c+1;
				
				next_state=18;
				
			end
			
		end
	20: begin  //identificam lm si hm			
	
		for(i=0;i<4;i=i+1)
		begin
			for(j=0;j<4;j=j+1)
			begin
				if(done==1 && matrix2[i][j]!=lm) 
				begin
					hm=matrix2[i][j];
					i=3;
					j=3;
					done=0;
				end
			end
		end
		next_state=21;
	end
	21:begin 
		if(lm>hm && done==0) begin
		aux=lm;
		lm=hm;
		hm=aux;
		done=1;
		end
		 
		next_state=22;
		end
	22:begin 
		base2=hiding_string[index_string+:16];
		en=1;
		
		next_state=23;
		end
	
	23: begin
		if(ok==1) 
		begin
			base3_aux=base3;
			lm_found=0;
			hm_found=0;
			i_lm=0;
			j_lm=0;
			i_hm=0;
			j_hm=0;
			base3_index=0;
			
			next_state=24;
		end
	end
	24:begin
		en=0;
		for(i=0;i<4;i=i+1) 
		begin
			for(j=0;j<4;j=j+1)
			begin
				if(matrix2[i][j]==lm && lm_found==0)
				begin
					i_lm=i;
					j_lm=j;
					lm_found=1;
				end
				if(matrix2[i][j]==hm && hm_found==0)
				begin
					i_hm=i;
					j_hm=j;
					hm_found=1;
				end
			end
		end
		
		next_state=31;
	end
	31:begin //stare adaugata ulterior 
		if(lm==hm) 
		begin
			i_hm=0;
			j_hm=1;
		end
		done=1;
		
		next_state=25;
	end

	25:begin
		
		for(i=0;i<4;i=i+1) 
		begin
			for(j=0;j<4;j=j+1) 
			begin
				if(( i==i_hm && j==j_hm) || ( i==i_lm && j==j_lm)) begin //aici clarificam ca pentru pozitiile lui Lm si Hm nu se executa nici o modificare
				base3_index=base3_index;
				end else begin
					if(base3_aux[base3_index+:2]==2) 
						begin
							matrix2[i][j][15:8]=matrix2[i][j][15:8]-1;
							base3_index=base3_index+2;
					end else 
						begin
							if(base3_aux[base3_index+:2]==1 ) begin
								matrix2[i][j][15:8]=matrix2[i][j][15:8]+1;
								base3_index=base3_index+2;
							end else begin
								base3_index=base3_index+2;
							end
						end
				end	
			end	
		end
		if(i==4 && j==4) 
		begin
			done=1;
			
			next_state=26;
		end
	end
	26: begin
	if(done==1) begin
		out_we_c=1;
		r=r-3;
		c=c-3;
		r_m=0;
		done=0;
		c_m=0;
	end
	
		next_state=27;
	end	
	
	27:begin //12
		out_pix_c=matrix2[r_m][c_m];
		done=1;
		next_state=28;
	
	end
	
   28:begin //13
			if(r_m==3 && c_m==3 && done==1)begin //s-a finalizat scrierea matricei de 4x4
				done=0;
				
				next_state=29; //continui cu initializarea unei noi matrice 
				
			end
			
			if(c_m==3 && r_m!=3 && done==1) begin
				done=0;
				
				//incrementarea matricei de 4x4
				c_m=0;
				r_m=r_m+1;
				
				//incrementarea matricei de pixeli mare
				c=c-3;
				r=r+1;
				
				next_state=27;
			end
			
			if(c_m!=3 && done==1) begin
			   done=0;
				c_m=c_m+1;
				c=c+1;
				
				next_state=27;
				
			end
			
			
	end
	29: begin //14
		if(c==63 && r==63 && done==0) //cum nu am vrut o stare auxiliara doar ca sa fac done=1, am decis ca pentru acest set de if-uri sa il folosesc ca 0
		begin
			done=1;
			
			next_state=30; //s-a completat toata matricea de pixeli mare
		end
		
		if(c==63 && r!=63 && done==0)
		begin
			c=0;
			r=r+1;
			done=1;		
			r_m=0;
			c_m=0;
			done=1;
			index_string=index_string+16;
			
			next_state=18;
		end
		
		if(c!=63  && done==0)
		begin
			r=r-3;
			c=c+1;
			r_m=0;
			c_m=0;
			done=1;
			index_string=index_string+16;
			
			next_state=18;
		end
	end
	30:begin //15
	
	e_done=1;
	
	end


	endcase
end
assign row=r;
assign col=c;
assign out_we=out_we_c;
assign out_pix=out_pix_c;
assign gray_done=g_done;
assign compress_done=c_done;
assign encode_done=e_done;
endmodule