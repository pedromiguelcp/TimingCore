#ifndef CONFIGURATIONTHREAD_H
#define CONFIGURATIONTHREAD_H

#include "AXIInterfaceClass.h"
#include "Thread.h"

typedef struct
{
	AXIInterfaceClass * axi;
} Configargs;

class ConfigurationThread : public Thread {

	public:
		/*
		 * This method will be executed by the Thread::exec method,
		 * which is executed in the thread of execution
		 */
		void run();
};

#endif
