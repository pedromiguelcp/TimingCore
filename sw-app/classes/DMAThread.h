#ifndef DMATHREAD_H
#define DMATHREAD_H

#include "StopClass.h"
#include "AXIInterfaceClass.h"
#include "TOFClass.h"
#include "Thread.h"

#include <stdint.h>

typedef struct
{
	StopClass * stop;
	AXIInterfaceClass * axi;
	TOFClass * tof;
} DMAargs;

class DMAThread : public Thread {

	private:
		struct channel_buffer * rx_proxy_buffer_p;

		uint64_t get_posix_clock_time_usec(void);

	public:
		/*
		 * This method will be executed by the Thread::exec method,
		 * which is executed in the thread of execution
		 */
		void run();
};

#endif
