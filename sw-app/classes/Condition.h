#ifndef CONDITION_H
#define CONDITION_H

#include <pthread.h>

#include "Lock.h"

class Condition : public Lock {
	protected:
		pthread_cond_t cond;

		// Prevent copying or assignment
		Condition(const Condition& arg);
		Condition& operator=(const Condition& rhs);

	public:
		Condition();
		virtual ~Condition();
		void wait();
		void notify();
};

#endif
