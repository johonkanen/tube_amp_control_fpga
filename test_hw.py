
import os
import sys
import time

this_file_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(this_file_path + '/source/fpga_communication/fpga_uart_pc_software/')
comport = sys.argv[1]

from uart_communication_functions import *

uart = uart_link(comport, 128e6/24)

print("data from test address: " + str(uart.request_data_from_address(1)))
print("data from test address 2 : " + str(uart.request_data_from_address(2)))
print("data from test address 2 : " + str(uart.request_data_from_address(2)))
print("data from test address 2 : " + str(uart.request_data_from_address(2)))

uart.plot_data_from_address(2, 50000)
