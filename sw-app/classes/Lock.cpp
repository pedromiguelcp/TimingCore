#include "Lock.h"

Lock::Lock() {
	pthread_mutex_init(&mutex, NULL);
}
Lock::~Lock() {
	pthread_mutex_destroy(&mutex);
}
void Lock::lock() {
	pthread_mutex_lock(&mutex);
}
void Lock::unlock() {
	pthread_mutex_unlock(&mutex);
}
