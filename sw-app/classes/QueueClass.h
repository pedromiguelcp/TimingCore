#ifndef QUEUECLASS_H
#define QUEUECLASS_H

#include <list>

#include "Condition.h"

template <class T>
class QueueClass {

	private:
		std::list<T> Queue;
		Condition * Cnd;

	public:
		QueueClass(){this->Cnd = new Condition();};
		~QueueClass(){delete this->Cnd;};
		void enqueue(T element);
		T dequeue(void);
		int size(void);

};

#endif

template <class T>
void QueueClass<T>::enqueue(T element)
{
	this->Cnd->lock();
	this->Queue.push_back(element);
	this->Cnd->notify();
	this->Cnd->unlock();
}

template <class T>
T QueueClass<T>::dequeue(void)
{
	T element;

	this->Cnd->lock();

	if(this->Queue.empty())
		this->Cnd->wait();

	element = this->Queue.front();
	this->Queue.pop_front();

	this->Cnd->unlock();

	return element;
}

template <class T>
int QueueClass<T>::size(void)
{
	return this->Queue.size();
}
