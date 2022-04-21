#ifndef LOCK_H
#define LOCK_H

#include <pthread.h>

class Lock {
	protected:
		pthread_mutex_t mutex;

		// Prevent copying or assignment
		Lock(const Lock& arg);
		Lock& operator=(const Lock& rhs);

	public:
		Lock();
		virtual ~Lock();
		void lock();
		void unlock();
};

#endif
