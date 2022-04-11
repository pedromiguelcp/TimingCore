#ifndef THREAD_H
#define THREAD_H

#include <pthread.h>

class Thread {
	private:
		pthread_t _id;
		pthread_attr_t tattr;

		// Prevent copying or assignment
		Thread(const Thread& arg);
		Thread& operator=(const Thread& rhs);

	protected:
		bool started;
		void *arg;

		static void *exec(void *thr);

	public:
		Thread();
		virtual ~Thread();
		unsigned int tid() const;
		void start(void *arg = NULL, int priority = 1);
		void join();
		virtual void run() = 0;
};

#endif
