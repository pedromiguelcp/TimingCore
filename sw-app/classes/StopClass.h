#ifndef STOPCLASS_H
#define STOPCLASS_H

#include "Lock.h"

class StopClass : public Lock {


	private:
		bool stop = 0;

	public:
		void set(void);
		bool get(void);
};

#endif
