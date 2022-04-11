#ifndef AXIINTERFACECLASS_H
#define AXIINTERFACECLASS_H

#include "Lock.h"

typedef struct
{
	char Haddr;
	char Laddr;
	char data;
	char cmd;
} ASIC_command;

typedef struct
{
	char addr;
	char data;
} POT_command;


class AXIInterfaceClass : public Lock {


	private:
		int arm_fd;
		int * arm_ptr;

		int vmirror_fd;
		int * vmirror_ptr;

		int tc_fd;
		int * tc_ptr;

		int vsync;
		int axiReg2_data;

		void ASIC_SendCommand(ASIC_command * ASIC);
		void VSync_Enable(void);

	public:
		AXIInterfaceClass();
		AXIInterfaceClass(char * uio0 = NULL, char * uio1 = NULL, char * uio2 = NULL);
		~AXIInterfaceClass();

		void ASIC_Configuration(void);
		void POT_Configuration(void);
		void VerticalController_Configuration(void);

		void TDC_Enable(void);
		void TDC_Disable(void);

		void TimingCore_Configuration(void);
		void TimingCore_Enable(void);
		void TimingCore_Disable(void);
		void TimingCore_Memory_Enable(void);
		void TimingCore_Memory_Disable(void);
		int TimingCore_Memory_Update(void);
		void TimingCore_Write(int data);
		void TimingCore_Update_QuarterMirrorCycleDelay(int qmcd);
		int TimingCore_Frequency_Read(void);

		int Frequency_Read(void);
		void Laser_ChangeFrequency(int freq);

		void POT_EnableHorizontal(void);
		void POT_DisableHorizontal(int hGain);
		void POT_ChangeHorizontalGain(int hGain);

		void ASIC_EnableVertical(char vGain);
		void ASIC_DisableVertical(char vGain);
		void ASIC_ChangeVerticalGain(char vGain);
		char ASIC_Read(char address);
		void ASIC_Write(char addr, char data);

		void UpdateVerticalPosition(void);
		void VMirror_ChangeVerticalPosition(int MSG, int LSG);
};

#endif
