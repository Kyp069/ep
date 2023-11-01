//-------------------------------------------------------------------------------------------------
// SDRAM commands
//-------------------------------------------------------------------------------------------------
//  This file is part of the Elan Enterprise FPGA implementation project.
//  Copyright (C) 2023 Kyp069 <kyp069@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it under the terms 
//  of the GNU General Public License as published by the Free Software Foundation;
//  either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program;
//  if not, If not, see <https://www.gnu.org/licenses/>.

task INHIBIT;
begin
	dramCs  <= 1'b1;
	dramRas <= 1'b1;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= 2'b00;
	dramA   <= 13'd0;
end
endtask

task NOP;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= 2'b00;
	dramA   <= 13'd0;
end
endtask

task REFRESH;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b0;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= 2'b00;
	dramA   <= 13'd0;
end
endtask

task PRECHARGE;
input[ 1:0] ba;
input pca;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b1;
	dramWe  <= 1'b0;
	dramDQM <= 2'b11;
	dramBA  <= ba;
	dramA   <= { 2'b00, pca, 10'd0 };
end
endtask

task LMR;
input[12:0] mode;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b0;
	dramWe  <= 1'b0;
	dramDQM <= 2'b11;
	dramBA  <= 2'b00;
	dramA   <= mode;
end
endtask

task ACTIVE;			// 8192 rows
input[ 1:0] ba;
input[12:0] a;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= ba;
	dramA   <= a;
end
endtask

task WRITE;				// 1024 columns
input[ 1:0] dqm;
input[ 1:0] ba;
input[ 9:0] a;
input pca;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b0;
	dramWe  <= 1'b0;
	dramDQM <= dqm;
	dramBA  <= ba;
	dramA   <= { 2'b00, pca, a };
end
endtask

task READ;				// 1024 columns
input[ 1:0] dqm;
input[ 1:0] ba;
input[ 9:0] a;
input pca;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b0;
	dramWe  <= 1'b1;
	dramDQM <= dqm;
	dramBA  <= ba;
	dramA   <= { 2'b00, pca, a };
end
endtask

//-------------------------------------------------------------------------------------------------
