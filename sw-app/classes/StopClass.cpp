#include "StopClass.h"


void StopClass::set(void)
{
	this->lock();
	this->stop = true;
	this->unlock();
}

bool StopClass::get(void)
{
	bool aux;

	this->lock();
	aux = this->stop;
	this->unlock();

	return aux;
}
