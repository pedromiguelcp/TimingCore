#include "FireClass.h"

#include <iostream>

#include "TOFClass.h"

FireClass::FireClass()
{
	this->FireMemory.reserve(NUMBER_OF_FRAMES);

	for(int i=0; i<NUMBER_OF_FRAMES; i++) {
		this->FireMemory.emplace_back();
		this->FireMemory.at(i).enqueue(std::vector<FireInfo> (FRAME_COLUMNS, FireInfo {0,true,0,0,i}));
		this->FireMemory.at(i).enqueue(std::vector<FireInfo> (FRAME_COLUMNS, FireInfo {0,true,0,0,i}));
	}

	this->FireMemoryActive = 0;
	this->MemoryOverload = 0;
	this->MemoryEnqueue = 0;
	this->MemoryDequeue = 0;
}

FireClass::~FireClass()
{
	for(int i=0; i<NUMBER_OF_FRAMES; i++) {
		this->FireMemory.pop_back();
	}

	std::cout << "MemoryOverload" << this->MemoryOverload << std::endl;
	std::cout << "MemoryEnqueue" << this->MemoryEnqueue << std::endl;
	std::cout << "MemoryDequeue" << this->MemoryDequeue << std::endl;
}

void FireClass::enqueue(std::vector <FireInfo> Fire)
{
	if(this->FireMemory.at(Fire.at(0).frame).size() > 2) {
		std::cout << "MemoryOverload -> " << Fire.at(0).frame << std::endl;
		this->MemoryOverload++;
	}

	this->FireMemory.at(Fire.at(0).frame).enqueue(Fire);
	this->MemoryEnqueue++;
}

std::vector <FireInfo> FireClass::dequeue(void)
{
	for(int i=0; i< NUMBER_OF_FRAMES; i++)
		if(i != this->FireMemoryActive)
			this->FireMemory.at(i).dequeue();

	this->MemoryDequeue++;

	return this->FireMemory.at(this->FireMemoryActive).dequeue();
}

void FireClass::changeFrame(void)
{
	//this->FireMemoryActive = this->FireMemoryActive < (NUMBER_OF_FRAMES-1) ? this->FireMemoryActive + 1 : 0;

	if(++this->FireMemoryActive == NUMBER_OF_FRAMES) this->FireMemoryActive = 0;

	//std::cout << "MemoryActive" << this->FireMemoryActive << std::endl;
}
