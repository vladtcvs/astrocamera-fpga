module ccd_controller(clk, width, height,
                      num_vertical_phases, num_horizontal_phases,
                      start_exposure, complete_exposure, start_read,
                      vertical_phases, horizontal_phases, read_completed, read_sample);

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
    output reg read_completed = 1'b0;
    output reg read_sample = 1'b0;
endmodule
