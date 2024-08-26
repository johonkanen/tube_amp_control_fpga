
import os
import sys
import time

this_file_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(this_file_path + '/source/fpga_communication/fpga_uart_pc_software/')
comport = sys.argv[1]

from uart_communication_functions import *

uart = uart_link(comport, 200e6/40)

print("data from test address: " + str(uart.request_data_from_address(1)))
print("data from test address 2 : " + str(uart.request_data_from_address(2)))
print("data from test address 2 : " + str(uart.request_data_from_address(2)))
print("data from test address 2 : " + str(uart.request_data_from_address(2)))

uart.write_data_to_address(3, 0)
uart.plot_data_from_address(2, 50000)

def plot_channel(channel_num):
    print("0")
    # time.sleep(1.1)
    uart.write_data_to_address(3, channel_num)
    print("1")
    # time.sleep(0.1)
    uart.request_data_stream_from_address(2,50000)
    # time.sleep(1.1)
    print("2")
    time.sleep(0.1)
    print("3")
    uart.write_data_to_address(12,1000)
    print("4")
    # time.sleep(0.1)
    print("5")
    uart.write_data_to_address(12,4000)
    print("6")
    # time.sleep(0.1)
    print("7")
    data = uart.get_streamed_data(50000)
    print("8")
    print("9")
    uart.write_data_to_address(12,1000)
    print("10")
    return data

# data=[plot_channel(5)]


# for i in range(1):
# data.append(plot_channel(4))


pyplot.plot(plot_channel(0))
pyplot.plot(plot_channel(1))
pyplot.plot(plot_channel(2))
pyplot.plot(plot_channel(4))
pyplot.plot(plot_channel(4))
pyplot.plot(plot_channel(5))
pyplot.plot(plot_channel(6))
pyplot.plot(plot_channel(7))

pyplot.show()
