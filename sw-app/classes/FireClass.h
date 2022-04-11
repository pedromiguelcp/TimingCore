#ifndef FIRECLASS_H
#define FIRECLASS_H

#include <vector>
#include <list>

#include "QueueClass.h"

#define POINTS_PER_LINE 20
#define NUMBER_OF_PASSAGES (FRAME_COLUMNS/POINTS_PER_LINE)
#define MEMCYCLES FRAME_ROWS
#define NUMBER_OF_FRAMES 5
#define PULSE_LENGTH 5
#define QUARTER_MIRROR_CYCLE_DELAY 12500

typedef struct
{
	unsigned int dtMirror;
	bool active;
	unsigned int X;
	unsigned int Y;
	unsigned int frame;
} FireInfo;

class FireClass {

	private:
		std::vector <QueueClass <std::vector <FireInfo>>> FireMemory;
		unsigned int FireMemoryActive;
		unsigned int MemoryOverload;
		unsigned int MemoryEnqueue;
		unsigned int MemoryDequeue;

	public:
		FireClass();
		~FireClass();
		void enqueue(std::vector <FireInfo> Fire);
		std::vector <FireInfo> dequeue(void);
		void changeFrame(void);
};

#endif
