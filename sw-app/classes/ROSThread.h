#ifndef ROSTHREAD_H
#define ROSTHREAD_H

#include "StopClass.h"
#include "TOFClass.h"
#include "FireClass.h"
#include "Thread.h"

typedef struct
{
	StopClass * stop;
	TOFClass * tof;
	FireClass * fire;
	int argc;
	char ** argv;
} ROSargs;

class ROSThread : public Thread {

	private:

	public:
		/*
		 * This method will be executed by the Thread::exec method,
		 * which is executed in the thread of execution
		 */
		void run();
};

#endif
