#ifndef INTERFACETHREAD_H
#define INTERFACETHREAD_H

#include "StopClass.h"
#include "AXIInterfaceClass.h"
#include "Thread.h"

typedef struct
{
	StopClass * stop;
	AXIInterfaceClass * axi;
} Interfaceargs;

class InterfaceThread : public Thread {

	private:
		void printMenu(void);

	public:
		/*
		 * This method will be executed by the Thread::exec method,
		 * which is executed in the thread of execution
		 */
		void run();
};

#endif
