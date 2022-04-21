#ifndef MATHTHREAD_H
#define MATHTHREAD_H

#include "StopClass.h"
#include "AXIInterfaceClass.h"
#include "FireClass.h"
#include "Thread.h"

typedef struct
{
	StopClass * stop;
	AXIInterfaceClass * axi;
	FireClass * fire;
} Mathargs;

class MathThread : public Thread {

	public:
		/*
		 * This method will be executed by the Thread::exec method,
		 * which is executed in the thread of execution
		 */
		void run();
};

#endif
