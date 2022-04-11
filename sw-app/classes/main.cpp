#include "ConfigurationThread.h"
#include "ROSThread.h"
#include "DMAThread.h"
#include "MathThread.h"
#include "InterfaceThread.h"

#include <iostream>

int main(int argc, char *argv[]) {

	StopClass stop;
	AXIInterfaceClass axi((char * )"/dev/uio1", (char * )"/dev/uio2", (char * )"/dev/uio0");
	TOFClass tof;
	FireClass fire;

	Configargs configTargs{&axi};
	DMAargs dmaTargs{&stop,&axi,&tof};
	ROSargs rosTargs{&stop,&tof,&fire,argc,argv};
	Mathargs mathTargs{&stop,&axi,&fire};
	Interfaceargs interfaceTargs{&stop,&axi};

	ConfigurationThread config;
	ROSThread ros;
	DMAThread dma;
	MathThread math;
	InterfaceThread interface;

	config.start(&configTargs,10);
	config.join();

	dma.start(&dmaTargs, 8);
	ros.start(&rosTargs, 6);
	math.start(&mathTargs, 4);
	interface.start(&interfaceTargs, 2);

	dma.join();
	ros.join();
	math.join();
	interface.join();
}
