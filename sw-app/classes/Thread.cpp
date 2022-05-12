#include "Thread.h"

#include <iostream>
#include <cstring>

Thread::Thread() : started(false) {
	std::cout << "Thread::Thread()" << std::endl;
}

Thread::~Thread() {
	std::cout << "Thread::~Thread()" << std::endl;
}

unsigned int Thread::tid() const {
	return _id;
}

// Uses default argument: arg = NULL
void Thread::start(void *arg, int priority) {
	int ret;
	sched_param param;

	if (!started) {
		started = true;
		this->arg = arg;

		/* initialized with default attributes */
		ret = pthread_attr_init (&tattr);

		/* safe to get existing scheduling param */
		ret = pthread_attr_getschedparam (&tattr, &param);

		/* set the priority; others are unchanged */
		param.sched_priority = priority;

		/* setting the new scheduling param */
		ret = pthread_attr_setschedparam (&tattr, &param);

		/*
		 * Since pthread_create is a C library function, the 3rd
		 * argument is a global function that will be executed by
		 * the thread. In C++, we emulate the global function using
		 * the static member function that is called exec. The 4th
		 * argument is the actual argument passed to the function
		 * exec. Here we use this pointer, which is an instance of
		 * the Thread class.
		 */
		if ((ret = pthread_create(&_id, &tattr, &Thread::exec, this)) != 0) {
			std::cout << std::strerror(ret) << std::endl;
			throw "Error";
		}
	}
}

void Thread::join() {
	// Allow the thread to wait for the termination status
	pthread_join(_id, NULL);
}

// Function that is to be executed by the thread
void *Thread::exec(void *thr) {
	reinterpret_cast<Thread *> (thr)->run();
}
