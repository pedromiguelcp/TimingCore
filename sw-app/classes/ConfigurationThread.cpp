#include "ConfigurationThread.h"

#include <iostream>

void ConfigurationThread::run() {

	AXIInterfaceClass * axiptr = reinterpret_cast<Configargs *> (this->arg)->axi;

	axiptr->ASIC_Configuration();
	axiptr->POT_Configuration();
	axiptr->TimingCore_Configuration();
	axiptr->TimingCore_Enable();
	axiptr->VerticalController_Configuration();
}
