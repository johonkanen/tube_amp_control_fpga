
import os
import sys
import time

this_file_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(this_file_path + '/source/fpga_communication/fpga_uart_pc_software/')
comport = sys.argv[1]

from uart_communication_functions import *

initial_duty = 500

uart = uart_link(comport, 200e6/40)
uart.write_data_to_address(12,initial_duty)

# print("data from test address: " + str(uart.request_data_from_address(1)))
# print("data from test address 2 : " + str(uart.request_data_from_address(2)))
# print("data from test address 2 : " + str(uart.request_data_from_address(2)))
# print("data from test address 2 : " + str(uart.request_data_from_address(2)))

uart.write_data_to_address(3, 0)
uart.plot_data_from_address(2, 50000)

def plot_channel(channel_num, number_of_points):
    uart.write_data_to_address(3, channel_num)
    uart.request_data_stream_from_address(2,number_of_points)
    time.sleep(0.03)
    uart.write_data_to_address(12,4000)
    time.sleep(0.03)
    uart.write_data_to_address(12,initial_duty)
    data = uart.get_streamed_data(number_of_points)
    return data

# data=[plot_channel(5)]


# for i in range(1):
# data.append(plot_channel(4))


# pyplot.plot(plot_channel(0))
# pyplot.plot(plot_channel(1))
pyplot.plot(plot_channel(2, 100000))
# pyplot.plot(plot_channel(3, 100000))
# pyplot.plot(plot_channel(4))
# pyplot.plot(plot_channel(5))
# pyplot.plot(plot_channel(6))
# pyplot.plot(plot_channel(7))

pyplot.show()
