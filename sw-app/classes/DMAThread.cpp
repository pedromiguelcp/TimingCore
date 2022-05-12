#include "DMAThread.h"

#include "dma-proxy.h"

#include <iostream>
#include <unistd.h>

#include <sys/mman.h>
#include <fcntl.h>
#include <sys/ioctl.h>

/* RX Buffer Overlap - dma-proxy.h
 */
#define RX_BUFFER_COUNT 1

void DMAThread::run()
{
	StopClass * stop = reinterpret_cast<DMAargs *> (this->arg)->stop;
	AXIInterfaceClass * axiptr = reinterpret_cast<DMAargs *> (this->arg)->axi;
	TOFClass * ToF = reinterpret_cast<DMAargs *> (this->arg)->tof;

	int rx_proxy_fd;
	char dma_proxy_rx [] = "/dev/dma_proxy_rx";

	int bufferRx_id = 0, bufferTx_id = 0;
	int in_progress_count = 0, frame_rows = 0;

	uint64_t start_time, end_time, time_diff;
	int completed, missed;
	int mb_sec;

	std::vector <unsigned int> ToFData;

	/* Open the DMA proxy device for the receive channel, the proxy driver is a character device
	 * that creates these device nodes
	 */
	rx_proxy_fd = open(dma_proxy_rx, O_RDWR);
	if (rx_proxy_fd < 1) {
		printf("Unable to open DMA proxy device file\n");
	}

	/* Map the receive channel memory into user space so it's accessible. Note that each channel
	 * has a set of channel buffers which are offsets from the start of the mapped channel memory.
	 */
	rx_proxy_buffer_p = (struct channel_buffer *) mmap(NULL, sizeof(struct channel_buffer)
							* RX_BUFFER_COUNT, PROT_READ|PROT_WRITE, MAP_SHARED, rx_proxy_fd, 0);
	if (rx_proxy_buffer_p == MAP_FAILED) {
		printf("MMap call failure\n");
	}

	start_time = get_posix_clock_time_usec();

	// Start all buffers being received
	for (bufferRx_id = 0; bufferRx_id < RX_BUFFER_COUNT; bufferRx_id += BUFFER_INCREMENT) {

		/* Setup the size of the transfer for the receive channel
		 */
		rx_proxy_buffer_p[bufferRx_id].length = BUFFER_SIZE;

		/* Start a receive DMA transfer - the status will be checked later.
		 * until then, other processing can be done
		 */
		ioctl(rx_proxy_fd, START_XFER, &bufferRx_id);

		/* Keep track how many transfers are in progress
		 */
		in_progress_count ++;
	}

	axiptr->TDC_Enable();

	/* Start with the 1st receive buffer */
	completed = 0;
	missed = 0;
	bufferRx_id = 0;
	bufferTx_id = 0;

	/* Finish each queued up receive buffer and keep starting the buffer over again
	 * until all the transfers are done
	 */
	while (!stop->get() || (in_progress_count > 0))
	{

		if (in_progress_count > 0) {

			/* Finish the receive DMA transfer - wait until complete */
			ioctl(rx_proxy_fd, FINISH_XFER, &bufferRx_id);

			if (rx_proxy_buffer_p[bufferRx_id].status != channel_buffer::PROXY_NO_ERROR) {	//TIMEOUT-3000ms BUSY ERROR
				//("POSSIBLE DATA LOST ON BUFFER %d: %d\n", bufferTx_id, rx_proxy_buffer_p[bufferTx_id].status);

				/* Keep track of unsuccessful transfers
				 */
				missed ++;

				/* Go to next buffer treating them as a circular list
				 */
				bufferTx_id += BUFFER_INCREMENT;
				bufferTx_id %= RX_BUFFER_COUNT;
			}
			else {
				/* Queue a Frame line
				 */
				std::copy(std::begin(rx_proxy_buffer_p[bufferTx_id].buffer), std::end(rx_proxy_buffer_p[bufferTx_id].buffer), std::back_inserter(ToFData));
				//std::cout << "DMA before Enqueue ->" << ToFData.at(0) << " " << ToFData.at(25) << " " << ToFData.at(103) << " " << ToFData.at(180) << std::endl;
				ToF->enqueue(ToFData);
				ToFData.clear();

				/* Keep track of the frame rows acquired
				 */
				frame_rows ++;
				frame_rows %= FRAME_ROWS;

				/* Keep track how many transfers were successful
				 */
				completed ++;

				/* Go to next buffer treating them as a circular list
				 */
				bufferTx_id += BUFFER_INCREMENT;
				bufferTx_id %= RX_BUFFER_COUNT;
			}

			/* Keep track how many transfers are in progress so that only the specified number
			 * of transfers are attempted
			 */
			in_progress_count --;

		}

		/* If the ones in progress will complete the frame then don't start more
		 * but finish the ones that are already started
		 */
		while ((!stop->get()  || (stop->get() && ((frame_rows + in_progress_count) > 0))) && (in_progress_count < RX_BUFFER_COUNT))
		{

			/* Start the next buffer again with another transfer keeping track of
			 * the number in progress but not finished
			 */
			ioctl(rx_proxy_fd, START_XFER, &bufferRx_id);

			in_progress_count ++;

			/* Go to next buffer treating them as a circular list
			 */
			bufferRx_id += BUFFER_INCREMENT;
			bufferRx_id %= RX_BUFFER_COUNT;

		}
	}

	/* Disable TDC
	 */
	axiptr->TDC_Disable();

	end_time = get_posix_clock_time_usec();
	time_diff = end_time - start_time;
	mb_sec = ((1000000 / (double)time_diff) * (completed * (double)BUFFER_SIZE)) / 1000000;

	std::cout << "DMA Time: " << time_diff << " microseconds\n";
	std::cout << "DMA Transfer size: " << (completed * BUFFER_SIZE) <<" bytes -> buffer size " << (BUFFER_SIZE / sizeof(unsigned int)) << ", transfers: completed  " << completed << ", missed " << missed << "\n";
	std::cout << "DMA Throughput: " << mb_sec << " MB / sec \n";

	/* Unmap the proxy channel interface memory and close the device file before leaving
	 */
	munmap(rx_proxy_buffer_p, sizeof(struct channel_buffer) * RX_BUFFER_COUNT);
	close(rx_proxy_fd);
}

/* Get the clock time in usecs to allow performance testing
 */
uint64_t DMAThread::get_posix_clock_time_usec ()
{
    struct timespec ts;

    if (clock_gettime (CLOCK_MONOTONIC, &ts) == 0)
        return (uint64_t) (ts.tv_sec * 1000000 + ts.tv_nsec / 1000);
    else
        return 0;
}
