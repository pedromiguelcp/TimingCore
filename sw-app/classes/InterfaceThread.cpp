#include "InterfaceThread.h"

#include <iostream>

void InterfaceThread::run(void)
{
	StopClass * stop = reinterpret_cast<Interfaceargs *> (this->arg)->stop;
	AXIInterfaceClass * axiptr = reinterpret_cast<Interfaceargs *> (this->arg)->axi;

	int option = -1;
	int value = -1;
	int address = 0;

	int enH = 1;
	int enV = 0;
	int enL = 1;

	int lastVgain = 11; //Default value on startup

	int laserData = 0;
	double freq = 0;

	//int i = 8;

	while(!stop->get())
	{
		printMenu();
		std::cin >> option;

		switch(option)
		{
		case 1:
			std::cout << "New horizontal gain value:\n";
			std::cin >> value;
			std::cout << value << std::endl;
			axiptr->POT_ChangeHorizontalGain(value);
			break;
		case 2:
			std::cout << "New vertical gain value:\n";
			std::cin >> value;
			std::cout << value << std::endl;
			lastVgain = value;
			axiptr->ASIC_ChangeVerticalGain(lastVgain);
			break;
		case 3:
			if(enH) {
				std::cout << "Disable Horizontal\n";
				axiptr->POT_DisableHorizontal(lastVgain);
				enH = 0;
			}
			else {
				std::cout << "Enable Horizontal\n";
				axiptr->POT_EnableHorizontal();
				enH = 1;
			}
			break;
		case 4:
			if(enV) {
				std::cout << "Disable Vertical\n";
				axiptr->ASIC_DisableVertical(lastVgain);
				enV = 0;
			}
			else {
				std::cout << "Enable Vertical\n";
				axiptr->ASIC_EnableVertical(lastVgain);
				enV = 1;
			}
			break;
		case 5:
			if(enL) {
				std::cout << "Disable Laser\n";
				axiptr->Laser_ChangeFrequency(freq);
				axiptr->TimingCore_Disable();
				enL = 0;
			}
			else {
				std::cout << "Enable Laser\n";
				axiptr->Laser_ChangeFrequency(freq);
				axiptr->TimingCore_Enable();
				enL = 1;
			}
			break;
		case 6:
			std::cout << "New vertical laser firing frequency (10ns*input_value): \n";
			std::cin >> freq;
			std::cout << freq << std::endl;
			axiptr->Laser_ChangeFrequency(freq);
			break;
		case 7:
			std::cout << "ASIC register address value: \n";
			std::cin >> value;
			std::cout << value << std::endl;
			std::cout << std::hex << (int) axiptr->ASIC_Read(value) << std::endl;
			break;
		case 8:
			axiptr->UpdateVerticalPosition();
			break;
		case 9:
			std::cout << "ASIC register address value:" << std::endl;
			std::cin >> address;
			std::cout << "ASIC register value:" << std::endl;
			std::cin >> value;
			axiptr->ASIC_Write(address,value);
			break;
		case 10:
			stop->set();
			break;
		default:
			std::cout << "Invalid Command\n";
			option = -1;
			break;
		}

		//while(i < 64)
		//{
		//	std::cout << std::uppercase << std::hex << i << "->" << std::uppercase << std::hex << (int) axiptr->ASIC_Read((char)i) << std::endl;
		//	i++;
		//}
		//i=8;

		option = -1;
		value = -1;
	}

	std::cout << "Interface Shutdown" << std::endl;
}

void InterfaceThread::printMenu(void) {

	std::cout << "*********************************************************************\n";
	std::cout << "*******************Available configuration options*******************\n\n";
	std::cout << "1. Horizontal gain" << std::endl;
	std::cout << "2. Vertical gain" << std::endl;
	std::cout << "3. Enable/Disable Horizontal" << std::endl;
	std::cout << "4. Enable/Disable Vertical" << std::endl;
	std::cout << "5. Enable/Disable Laser" << std::endl;
	std::cout << "6. Define Laser Frequency" << std::endl;
	std::cout << "7. Read from ASIC" << std::endl;
	std::cout << "8. Update Vertical line" << std::endl;
	std::cout << "9. Write to ASIC" << std::endl;
	std::cout << "10. Shutdown LIDAR" << std::endl << std::endl;
	std::cout << "Select an option please:" << std::endl;
}
