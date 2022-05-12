#include "TOFClass.h"

#include <iostream>

TOFClass::TOFClass()
{
	this->Cnd = new Condition();
}

TOFClass::~TOFClass()
{
	delete this->Cnd;
}

void TOFClass::enqueue(std::vector<unsigned int> ToF)
{
	this->Cnd->lock();
	this->ToFQueue.push_back(ToF);
	this->Cnd->notify();
	this->Cnd->unlock();
}

std::vector <unsigned int> TOFClass::dequeue(void)
{
	std::vector <unsigned int> ToF(FRAME_COLUMNS);

	this->Cnd->lock();

	if(this->ToFQueue.empty())
		this->Cnd->wait();

	ToF = this->ToFQueue.front();
	this->ToFQueue.pop_front();

	this->Cnd->unlock();

	return ToF;
}

int TOFClass::size(void)
{
	return this->ToFQueue.size();
}
