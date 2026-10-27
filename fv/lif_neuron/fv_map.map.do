
//input ports
add mapped point clk clk -type PI PI
add mapped point rst_n rst_n -type PI PI
add mapped point en en -type PI PI
add mapped point current_in[19] current_in[19] -type PI PI
add mapped point current_in[18] current_in[18] -type PI PI
add mapped point current_in[17] current_in[17] -type PI PI
add mapped point current_in[16] current_in[16] -type PI PI
add mapped point current_in[15] current_in[15] -type PI PI
add mapped point current_in[14] current_in[14] -type PI PI
add mapped point current_in[13] current_in[13] -type PI PI
add mapped point current_in[12] current_in[12] -type PI PI
add mapped point current_in[11] current_in[11] -type PI PI
add mapped point current_in[10] current_in[10] -type PI PI
add mapped point current_in[9] current_in[9] -type PI PI
add mapped point current_in[8] current_in[8] -type PI PI
add mapped point current_in[7] current_in[7] -type PI PI
add mapped point current_in[6] current_in[6] -type PI PI
add mapped point current_in[5] current_in[5] -type PI PI
add mapped point current_in[4] current_in[4] -type PI PI
add mapped point current_in[3] current_in[3] -type PI PI
add mapped point current_in[2] current_in[2] -type PI PI
add mapped point current_in[1] current_in[1] -type PI PI
add mapped point current_in[0] current_in[0] -type PI PI

//output ports
add mapped point spike_out spike_out -type PO PO
add mapped point membrane_out[19] membrane_out[19] -type PO PO
add mapped point membrane_out[18] membrane_out[18] -type PO PO
add mapped point membrane_out[17] membrane_out[17] -type PO PO
add mapped point membrane_out[16] membrane_out[16] -type PO PO
add mapped point membrane_out[15] membrane_out[15] -type PO PO
add mapped point membrane_out[14] membrane_out[14] -type PO PO
add mapped point membrane_out[13] membrane_out[13] -type PO PO
add mapped point membrane_out[12] membrane_out[12] -type PO PO
add mapped point membrane_out[11] membrane_out[11] -type PO PO
add mapped point membrane_out[10] membrane_out[10] -type PO PO
add mapped point membrane_out[9] membrane_out[9] -type PO PO
add mapped point membrane_out[8] membrane_out[8] -type PO PO
add mapped point membrane_out[7] membrane_out[7] -type PO PO
add mapped point membrane_out[6] membrane_out[6] -type PO PO
add mapped point membrane_out[5] membrane_out[5] -type PO PO
add mapped point membrane_out[4] membrane_out[4] -type PO PO
add mapped point membrane_out[3] membrane_out[3] -type PO PO
add mapped point membrane_out[2] membrane_out[2] -type PO PO
add mapped point membrane_out[1] membrane_out[1] -type PO PO
add mapped point membrane_out[0] membrane_out[0] -type PO PO

//inout ports




//Sequential Pins
add mapped point spike_out/q spike_out_reg/Q -type DFF DFF
add mapped point membrane[0]/q membrane_reg[0]/Q -type DFF DFF
add mapped point membrane[4]/q membrane_reg[4]/Q -type DFF DFF
add mapped point membrane[5]/q membrane_reg[5]/Q -type DFF DFF
add mapped point membrane[19]/q membrane_reg[19]/Q -type DFF DFF
add mapped point membrane[6]/q membrane_reg[6]/Q -type DFF DFF
add mapped point membrane[7]/q membrane_reg[7]/Q -type DFF DFF
add mapped point membrane[8]/q membrane_reg[8]/Q -type DFF DFF
add mapped point membrane[9]/q membrane_reg[9]/Q -type DFF DFF
add mapped point membrane[10]/q membrane_reg[10]/Q -type DFF DFF
add mapped point membrane[1]/q membrane_reg[1]/Q -type DFF DFF
add mapped point membrane[11]/q membrane_reg[11]/Q -type DFF DFF
add mapped point membrane[12]/q membrane_reg[12]/Q -type DFF DFF
add mapped point membrane[13]/q membrane_reg[13]/Q -type DFF DFF
add mapped point membrane[14]/q membrane_reg[14]/Q -type DFF DFF
add mapped point membrane[2]/q membrane_reg[2]/Q -type DFF DFF
add mapped point membrane[15]/q membrane_reg[15]/Q -type DFF DFF
add mapped point membrane[16]/q membrane_reg[16]/Q -type DFF DFF
add mapped point membrane[3]/q membrane_reg[3]/Q -type DFF DFF
add mapped point membrane[17]/q membrane_reg[17]/Q -type DFF DFF
add mapped point membrane[18]/q membrane_reg[18]/Q -type DFF DFF



//Black Boxes



//Empty Modules as Blackboxes
