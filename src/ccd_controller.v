module ccd_controller(clk, width, height,
                      num_vertical_phases, num_horizontal_phases,
                      start_exposure, complete_exposure, start_read,
                      vertical_phases, horizontal_phases, reset_gate,
                      xsub, vsub,
                      cds_1, cds_2, adc_sample,
                      read_completed, store_sample);

    input wire clk;
    input wire[15:0] width;
    input wire[15:0] height;
    input wire[3:0] num_vertical_phases;
    input wire[2:0] num_horizontal_phases;

    input wire start_exposure;
    input wire complete_exposure;
    input wire start_read;

    output reg[15:0] vertical_phases = 0;
    output reg[7:0] horizontal_phases = 0;
    output reg reset_gate = 1'b0;

    output reg xsub = 1'b0;
    output reg vsub = 1'b0;

    output reg cds_1 = 1'b0;
    output reg cds_2 = 1'b0;
    output reg adc_sample = 1'b0;

    output reg read_completed = 1'b0;
    output reg store_sample = 1'b0;
	
    always @ (posedge clk) begin
        store_sample <= !store_sample;
    end
endmodule
