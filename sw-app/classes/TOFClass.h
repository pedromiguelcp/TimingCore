#ifndef TOFCLASS_H
#define TOFCLASS_H

#include <list>
#include <vector>

#include "Condition.h"

// Frame Dimensions
#define FRAME_COLUMNS 360
#define FRAME_ROWS 100


class TOFClass {

	private:
		std::list <std::vector<unsigned int>> ToFQueue;
		Condition * Cnd;

	public:
		TOFClass();
		virtual ~TOFClass();
		void enqueue(std::vector<unsigned int> ToF);
		std::vector <unsigned int> dequeue(void);
		int size(void);

};

#endif
