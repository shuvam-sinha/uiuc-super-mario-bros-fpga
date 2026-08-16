//-------------------------------------------------------------------------
//    mb_usb_hdmi_top.sv                                                 --
//    Zuofu Cheng                                                        --
//    2-29-24                                                            --
//    10-14-25                                                           --
//                                                                       --
//    Fall 2025 Distribution                                           --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,
    
    // USB SPI Signals
    output logic usb_spi_sclk,
    output logic usb_spi_mosi,
    input  logic usb_spi_miso,
    output logic usb_spi_ss,
    
    // USB GPIO Control
    input  logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    
    // UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    // HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    // HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB,
    
    output logic audio_left,
    output logic audio_right
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    
    // Instantiating the MicroBlaze Block Design
    mb_block mb_block_i (
        .clk_100MHz(Clk),
        .reset_rtl_0(~reset_rtl_0),
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .HDMI_0_tmds_clk_n(hdmi_tmds_clk_n),
        .HDMI_0_tmds_clk_p(hdmi_tmds_clk_p),
        .HDMI_0_tmds_data_n(hdmi_tmds_data_n),
        .HDMI_0_tmds_data_p(hdmi_tmds_data_p),
        
        // USB SPI Connection
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk), // Matches top-level port
        .usb_spi_ss(usb_spi_ss),
        
        // USB GPIO Connection
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        
        // Internal Keycodes
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .audio_left(audio_left),
        .audio_right(audio_right)
    );

endmodule
