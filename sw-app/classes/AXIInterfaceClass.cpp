#include "AXIInterfaceClass.h"

#include <iostream>
#include <unistd.h>
#include <time.h>
#include <sys/mman.h>
#include <fcntl.h>

#include <stdio.h>

#include "TOFClass.h"
#include "FireClass.h"

#define ASIC_NEW_DATA	0x00000001
#define POT_NEW_DATA	0x00000002
#define TIMING_CORE_EN	0x00000004
#define MEM_READ_NRST	0x00000008
#define MEM_READ_EN		0x00000010
#define TDC_EN			0x00000020
#define TC_WE			0x00000040
#define TC_MEM_UPDATED	0x00000080

#define NASICConfig_CMD 148
#define NPOTConfig_CMD 3

#define DAC_INIT	5
#define DAC_STEP	35
#define DAC_LINES FRAME_ROWS

AXIInterfaceClass::AXIInterfaceClass() {

	char uio0 [] = "/dev/uio0";
	char uio1 [] = "/dev/uio1";
	char uio2 [] = "/dev/uio2";

	/* open the UIO device file to allow access to the device in user space */
	arm_fd = open(uio0, O_RDWR);
	if (arm_fd < 1)	{
		std::cout << "Invalid UIO device file: " << uio0 << ".\n";
	}

	/* memory map the GPIO register into user space */
	arm_ptr = (int * ) mmap(NULL, sizeof(unsigned long) * 10, PROT_READ|PROT_WRITE, MAP_SHARED, arm_fd, 0);
	if (arm_ptr == MAP_FAILED) {
		std::cout << "MMap call failure\n";
	}

	/* open the UIO device file to allow access to the device in user space */
	vmirror_fd = open(uio1, O_RDWR);
	if (vmirror_fd < 1)	{
		std::cout << "Invalid UIO device file: " << uio1 << ".\n";
	}

	/* memory map the GPIO register into user space */
	vmirror_ptr = (int * ) mmap(NULL, sizeof(unsigned long) * 8, PROT_READ|PROT_WRITE, MAP_SHARED, vmirror_fd, 0);
	if (vmirror_ptr == MAP_FAILED) {
		std::cout << "MMap call failure\n";
	}

	/* open the UIO device file to allow access to the device in user space */
	tc_fd = open(uio2, O_RDWR);
	if (tc_fd < 1)	{
		std::cout << "Invalid UIO device file: " << uio2 << ".\n";
	}

	/* memory map the GPIO register into user space */
	tc_ptr = (int * ) mmap(NULL, sizeof(unsigned long) * 8, PROT_READ|PROT_WRITE, MAP_SHARED, tc_fd, 0);
	if (tc_ptr == MAP_FAILED) {
		std::cout << "MMap call failure\n";
	}

	this->axiReg2_data = 0;
	this->vsync = 0;
}

AXIInterfaceClass::AXIInterfaceClass(char * uio0, char * uio1, char * uio2) {

	/* open the UIO device file to allow access to the device in user space */
	arm_fd = open(uio0, O_RDWR);
	if (arm_fd < 1)	{
		std::cout << "Invalid UIO device file: " << uio0 << ".\n";
	}

	/* memory map the GPIO register into user space */
	arm_ptr = (int * ) mmap(NULL, sizeof(unsigned long) * 10, PROT_READ|PROT_WRITE, MAP_SHARED, arm_fd, 0);
	if (arm_ptr == MAP_FAILED) {
		std::cout << "MMap call failure\n";
	}

	/* open the UIO device file to allow access to the device in user space */
	vmirror_fd = open(uio1, O_RDWR);
	if (vmirror_fd < 1)	{
		std::cout << "Invalid UIO device file: " << uio1 << ".\n";
	}

	/* memory map the GPIO register into user space */
	vmirror_ptr = (int * ) mmap(NULL, sizeof(unsigned long) * 8, PROT_READ|PROT_WRITE, MAP_SHARED, vmirror_fd, 0);
	if (vmirror_ptr == MAP_FAILED) {
		std::cout << "MMap call failure\n";
	}

	/* open the UIO device file to allow access to the device in user space */
	tc_fd = open(uio2, O_RDWR);
	if (tc_fd < 1)	{
		std::cout << "Invalid UIO device file: " << uio2 << ".\n";
	}

	/* memory map the GPIO register into user space */
	tc_ptr = (int * ) mmap(NULL, sizeof(unsigned long) * 8, PROT_READ|PROT_WRITE, MAP_SHARED, tc_fd, 0);
	if (tc_ptr == MAP_FAILED) {
		std::cout << "MMap call failure\n";
	}

	this->axiReg2_data = 0;
	this->vsync = 0;
}

AXIInterfaceClass::~AXIInterfaceClass() {

	/* Unmap the UIO device and close the device file before leaving
	 */
	munmap(arm_ptr,sizeof(unsigned long) * 10);
	close(arm_fd);

	/* Unmap the UIO device and close the device file before leaving
	 */
	munmap(vmirror_ptr,sizeof(unsigned long) * 8);
	close(vmirror_fd);

	/* Unmap the UIO device and close the device file before leaving
	 */
	munmap(tc_ptr,sizeof(unsigned long) * 8);
	close(tc_fd);
}

void AXIInterfaceClass::ASIC_Configuration(void)
{
	ASIC_command ASIC_Config[NASICConfig_CMD];
	int i = 0;

	ASIC_Config[0].Haddr = 0x00;	ASIC_Config[0].Laddr = 0x0D;	ASIC_Config[0].data = 0x00;		ASIC_Config[0].cmd = 0x01;
	ASIC_Config[1].Haddr = 0x00;	ASIC_Config[1].Laddr = 0x0D;	ASIC_Config[1].data = 0x03; 	ASIC_Config[1].cmd = 0x00;
	ASIC_Config[2].Haddr = 0x00;	ASIC_Config[2].Laddr = 0x0D;	ASIC_Config[2].data = 0x00; 	ASIC_Config[2].cmd = 0x01;
	ASIC_Config[3].Haddr = 0x00;	ASIC_Config[3].Laddr = 0x09; 	ASIC_Config[3].data = 0x00; 	ASIC_Config[3].cmd = 0x01;
	ASIC_Config[4].Haddr = 0x00;	ASIC_Config[4].Laddr = 0x09; 	ASIC_Config[4].data = 0x0A; 	ASIC_Config[4].cmd = 0x00;
	ASIC_Config[5].Haddr = 0x00;	ASIC_Config[5].Laddr = 0x0A; 	ASIC_Config[5].data = 0x00; 	ASIC_Config[5].cmd = 0x01;
	ASIC_Config[6].Haddr = 0x00;	ASIC_Config[6].Laddr = 0x0A; 	ASIC_Config[6].data = 0x08; 	ASIC_Config[6].cmd = 0x00;
	ASIC_Config[7].Haddr = 0x00;	ASIC_Config[7].Laddr = 0x0B; 	ASIC_Config[7].data = 0x00; 	ASIC_Config[7].cmd = 0x01;
	ASIC_Config[8].Haddr = 0x00;	ASIC_Config[8].Laddr = 0x0B; 	ASIC_Config[8].data = 0x84; 	ASIC_Config[8].cmd = 0x00; //Dis_Dig_out (BIT7) 1-Disabled
	ASIC_Config[9].Haddr = 0x00;	ASIC_Config[9].Laddr = 0x0E; 	ASIC_Config[9].data = 0x0A; 	ASIC_Config[9].cmd = 0x00;
	ASIC_Config[10].Haddr = 0x00;	ASIC_Config[10].Laddr = 0x0F; 	ASIC_Config[10].data = 0x08; 	ASIC_Config[10].cmd = 0x00;
	ASIC_Config[11].Haddr = 0x00;	ASIC_Config[11].Laddr = 0x18; 	ASIC_Config[11].data = 0x80; 	ASIC_Config[11].cmd = 0x00;
	ASIC_Config[12].Haddr = 0x00;	ASIC_Config[12].Laddr = 0x19; 	ASIC_Config[12].data = 0x00; 	ASIC_Config[12].cmd = 0x01;
	ASIC_Config[13].Haddr = 0x00;	ASIC_Config[13].Laddr = 0x19; 	ASIC_Config[13].data = 0x0F; 	ASIC_Config[13].cmd = 0x00;
	ASIC_Config[14].Haddr = 0x00;	ASIC_Config[14].Laddr = 0x22; 	ASIC_Config[14].data = 0x00; 	ASIC_Config[14].cmd = 0x01;
	ASIC_Config[15].Haddr = 0x00;	ASIC_Config[15].Laddr = 0x22; 	ASIC_Config[15].data = 0xD0; 	ASIC_Config[15].cmd = 0x00;
	ASIC_Config[16].Haddr = 0x00;	ASIC_Config[16].Laddr = 0x28; 	ASIC_Config[16].data = 0x00; 	ASIC_Config[16].cmd = 0x01;
	ASIC_Config[17].Haddr = 0x00;	ASIC_Config[17].Laddr = 0x28; 	ASIC_Config[17].data = 0x03; 	ASIC_Config[17].cmd = 0x00;
	ASIC_Config[18].Haddr = 0x00;	ASIC_Config[18].Laddr = 0x29;	ASIC_Config[18].data = 0x04; 	ASIC_Config[18].cmd = 0x00;
	ASIC_Config[19].Haddr = 0x00;	ASIC_Config[19].Laddr = 0x2E; 	ASIC_Config[19].data = 0x00; 	ASIC_Config[19].cmd = 0x01;
	ASIC_Config[20].Haddr = 0x00;	ASIC_Config[20].Laddr = 0x2E; 	ASIC_Config[20].data = 0xFB; 	ASIC_Config[20].cmd = 0x00;
	ASIC_Config[21].Haddr = 0x00;	ASIC_Config[21].Laddr = 0x2F; 	ASIC_Config[21].data = 0x80; 	ASIC_Config[21].cmd = 0x00;
	ASIC_Config[22].Haddr = 0x00;	ASIC_Config[22].Laddr = 0x3E; 	ASIC_Config[22].data = 0x00; 	ASIC_Config[22].cmd = 0x00;
	ASIC_Config[23].Haddr = 0x00;	ASIC_Config[23].Laddr = 0x08; 	ASIC_Config[23].data = 0x00; 	ASIC_Config[23].cmd = 0x01;
	ASIC_Config[24].Haddr = 0x00;	ASIC_Config[24].Laddr = 0x08; 	ASIC_Config[24].data = 0x02; 	ASIC_Config[24].cmd = 0x00; //PD_DAC (BIT7) 0-Enabled
	ASIC_Config[25].Haddr = 0x00;	ASIC_Config[25].Laddr = 0x09; 	ASIC_Config[25].data = 0x00; 	ASIC_Config[25].cmd = 0x01;
	ASIC_Config[26].Haddr = 0x00;	ASIC_Config[26].Laddr = 0x09; 	ASIC_Config[26].data = 0x0A; 	ASIC_Config[26].cmd = 0x00;
	ASIC_Config[27].Haddr = 0x00;	ASIC_Config[27].Laddr = 0x08; 	ASIC_Config[27].data = 0x00; 	ASIC_Config[27].cmd = 0x01;
	ASIC_Config[28].Haddr = 0x00;	ASIC_Config[28].Laddr = 0x08; 	ASIC_Config[28].data = 0x02; 	ASIC_Config[28].cmd = 0x00; //PD_DAC (BIT7) 0-Enabled
	ASIC_Config[29].Haddr = 0x00;	ASIC_Config[29].Laddr = 0x0C; 	ASIC_Config[29].data = 0x00; 	ASIC_Config[29].cmd = 0x00;
	ASIC_Config[30].Haddr = 0x00;	ASIC_Config[30].Laddr = 0x0D; 	ASIC_Config[30].data = 0x00; 	ASIC_Config[30].cmd = 0x01;
	ASIC_Config[31].Haddr = 0x00;	ASIC_Config[31].Laddr = 0x0D; 	ASIC_Config[31].data = 0x0B; 	ASIC_Config[31].cmd = 0x00; //EV EH (BIT7-6) 00-Disabled
	ASIC_Config[32].Haddr = 0x00;	ASIC_Config[32].Laddr = 0x10; 	ASIC_Config[32].data = 0x00; 	ASIC_Config[32].cmd = 0x01;
	ASIC_Config[33].Haddr = 0x00;	ASIC_Config[33].Laddr = 0x10;	ASIC_Config[33].data = 0x78; 	ASIC_Config[33].cmd = 0x00;
	ASIC_Config[34].Haddr = 0x00;	ASIC_Config[34].Laddr = 0x19; 	ASIC_Config[34].data = 0x00; 	ASIC_Config[34].cmd = 0x01;
	ASIC_Config[35].Haddr = 0x00;	ASIC_Config[35].Laddr = 0x19; 	ASIC_Config[35].data = 0x0F; 	ASIC_Config[35].cmd = 0x00;
	ASIC_Config[36].Haddr = 0x00;	ASIC_Config[36].Laddr = 0x19; 	ASIC_Config[36].data = 0x00; 	ASIC_Config[36].cmd = 0x01;
	ASIC_Config[37].Haddr = 0x00;	ASIC_Config[37].Laddr = 0x19; 	ASIC_Config[37].data = 0x0F; 	ASIC_Config[37].cmd = 0x00;
	ASIC_Config[38].Haddr = 0x00;	ASIC_Config[38].Laddr = 0x11; 	ASIC_Config[38].data = 0x00; 	ASIC_Config[38].cmd = 0x01;
	ASIC_Config[39].Haddr = 0x00;	ASIC_Config[39].Laddr = 0x11; 	ASIC_Config[39].data = 0xA7; 	ASIC_Config[39].cmd = 0x00;
	ASIC_Config[40].Haddr = 0x00;	ASIC_Config[40].Laddr = 0x11; 	ASIC_Config[40].data = 0x00; 	ASIC_Config[40].cmd = 0x01;
	ASIC_Config[41].Haddr = 0x00;	ASIC_Config[41].Laddr = 0x11; 	ASIC_Config[41].data = 0xA7; 	ASIC_Config[41].cmd = 0x00;
	ASIC_Config[42].Haddr = 0x00;	ASIC_Config[42].Laddr = 0x12; 	ASIC_Config[42].data = 0x05; 	ASIC_Config[42].cmd = 0x00;
	ASIC_Config[43].Haddr = 0x00;	ASIC_Config[43].Laddr = 0x13; 	ASIC_Config[43].data = 0x05; 	ASIC_Config[43].cmd = 0x00;
	ASIC_Config[44].Haddr = 0x00;	ASIC_Config[44].Laddr = 0x10; 	ASIC_Config[44].data = 0x00; 	ASIC_Config[44].cmd = 0x01;
	ASIC_Config[45].Haddr = 0x00;	ASIC_Config[45].Laddr = 0x10; 	ASIC_Config[45].data = 0x7F; 	ASIC_Config[45].cmd = 0x00;
	ASIC_Config[46].Haddr = 0x00;	ASIC_Config[46].Laddr = 0x14; 	ASIC_Config[46].data = 0x8D; 	ASIC_Config[46].cmd = 0x00;
	ASIC_Config[47].Haddr = 0x00;	ASIC_Config[47].Laddr = 0x15; 	ASIC_Config[47].data = 0x2A; 	ASIC_Config[47].cmd = 0x00;
	ASIC_Config[48].Haddr = 0x00;	ASIC_Config[48].Laddr = 0x16; 	ASIC_Config[48].data = 0x0E; 	ASIC_Config[48].cmd = 0x00;
	ASIC_Config[49].Haddr = 0x00;	ASIC_Config[49].Laddr = 0x17; 	ASIC_Config[49].data = 0x7F; 	ASIC_Config[49].cmd = 0x00;
	ASIC_Config[50].Haddr = 0x00;	ASIC_Config[50].Laddr = 0x10; 	ASIC_Config[50].data = 0x00; 	ASIC_Config[50].cmd = 0x01;
	ASIC_Config[51].Haddr = 0x00;	ASIC_Config[51].Laddr = 0x10; 	ASIC_Config[51].data = 0x7F; 	ASIC_Config[51].cmd = 0x00;
	ASIC_Config[52].Haddr = 0x00;	ASIC_Config[52].Laddr = 0x1C; 	ASIC_Config[52].data = 0x00; 	ASIC_Config[52].cmd = 0x01;
	ASIC_Config[53].Haddr = 0x00;	ASIC_Config[53].Laddr = 0x1C; 	ASIC_Config[53].data = 0x00; 	ASIC_Config[53].cmd = 0x00; //PD_YC (BIT7) 0-Enabled
	ASIC_Config[54].Haddr = 0x00;	ASIC_Config[54].Laddr = 0x23; 	ASIC_Config[54].data = 0x00; 	ASIC_Config[54].cmd = 0x01;
	ASIC_Config[55].Haddr = 0x00;	ASIC_Config[55].Laddr = 0x23; 	ASIC_Config[55].data = 0x24; 	ASIC_Config[55].cmd = 0x00;
	ASIC_Config[56].Haddr = 0x00;	ASIC_Config[56].Laddr = 0x1E; 	ASIC_Config[56].data = 0x00; 	ASIC_Config[56].cmd = 0x01;
	ASIC_Config[57].Haddr = 0x00;	ASIC_Config[57].Laddr = 0x1E; 	ASIC_Config[57].data = 0x12; 	ASIC_Config[57].cmd = 0x00;
	ASIC_Config[58].Haddr = 0x00;	ASIC_Config[58].Laddr = 0x21; 	ASIC_Config[58].data = 0x00; 	ASIC_Config[58].cmd = 0x01;
	ASIC_Config[59].Haddr = 0x00;	ASIC_Config[59].Laddr = 0x21; 	ASIC_Config[59].data = 0x74; 	ASIC_Config[59].cmd = 0x00; //YC_HS_SEL (BIT7) 0-FromSPI
	ASIC_Config[60].Haddr = 0x00;	ASIC_Config[60].Laddr = 0x1D; 	ASIC_Config[60].data = 0xE0; 	ASIC_Config[60].cmd = 0x00;
	ASIC_Config[61].Haddr = 0x00;	ASIC_Config[61].Laddr = 0x1E; 	ASIC_Config[61].data = 0x00; 	ASIC_Config[61].cmd = 0x01;
	ASIC_Config[62].Haddr = 0x00;	ASIC_Config[62].Laddr = 0x1E; 	ASIC_Config[62].data = 0x12; 	ASIC_Config[62].cmd = 0x00;
	ASIC_Config[63].Haddr = 0x00;	ASIC_Config[63].Laddr = 0x1F; 	ASIC_Config[63].data = 0x1F; 	ASIC_Config[63].cmd = 0x00;
	ASIC_Config[64].Haddr = 0x00;	ASIC_Config[64].Laddr = 0x20; 	ASIC_Config[64].data = 0x00; 	ASIC_Config[64].cmd = 0x00;
	ASIC_Config[65].Haddr = 0x00;	ASIC_Config[65].Laddr = 0x21; 	ASIC_Config[65].data = 0x00; 	ASIC_Config[65].cmd = 0x01;
	ASIC_Config[66].Haddr = 0x00;	ASIC_Config[66].Laddr = 0x21; 	ASIC_Config[66].data = 0x74; 	ASIC_Config[66].cmd = 0x00; //YC_HS_SEL (BIT7) 0-From SPI 74 1-FromDigital F4
	ASIC_Config[67].Haddr = 0x00;	ASIC_Config[67].Laddr = 0x22; 	ASIC_Config[67].data = 0x00; 	ASIC_Config[67].cmd = 0x01;
	ASIC_Config[68].Haddr = 0x00;	ASIC_Config[68].Laddr = 0x22; 	ASIC_Config[68].data = 0xD0; 	ASIC_Config[68].cmd = 0x00;
	ASIC_Config[69].Haddr = 0x00;	ASIC_Config[69].Laddr = 0x23; 	ASIC_Config[69].data = 0x00; 	ASIC_Config[69].cmd = 0x01;
	ASIC_Config[70].Haddr = 0x00;	ASIC_Config[70].Laddr = 0x23; 	ASIC_Config[70].data = 0x24; 	ASIC_Config[70].cmd = 0x00;
	ASIC_Config[71].Haddr = 0x00;	ASIC_Config[71].Laddr = 0x22; 	ASIC_Config[71].data = 0x00; 	ASIC_Config[71].cmd = 0x01;
	ASIC_Config[72].Haddr = 0x00;	ASIC_Config[72].Laddr = 0x22; 	ASIC_Config[72].data = 0xF0; 	ASIC_Config[72].cmd = 0x00;
	ASIC_Config[73].Haddr = 0x00;	ASIC_Config[73].Laddr = 0x24; 	ASIC_Config[73].data = 0x9B; 	ASIC_Config[73].cmd = 0x00;
	ASIC_Config[74].Haddr = 0x00;	ASIC_Config[74].Laddr = 0x25; 	ASIC_Config[74].data = 0xEF; 	ASIC_Config[74].cmd = 0x00;
	ASIC_Config[75].Haddr = 0x00;	ASIC_Config[75].Laddr = 0x26; 	ASIC_Config[75].data = 0x00; 	ASIC_Config[75].cmd = 0x01;
	ASIC_Config[76].Haddr = 0x00;	ASIC_Config[76].Laddr = 0x26; 	ASIC_Config[76].data = 0x01; 	ASIC_Config[76].cmd = 0x00;
	ASIC_Config[77].Haddr = 0x00;	ASIC_Config[77].Laddr = 0x28; 	ASIC_Config[77].data = 0x00; 	ASIC_Config[77].cmd = 0x01;
	ASIC_Config[78].Haddr = 0x00;	ASIC_Config[78].Laddr = 0x28; 	ASIC_Config[78].data = 0x03; 	ASIC_Config[78].cmd = 0x00;
	ASIC_Config[79].Haddr = 0x00;	ASIC_Config[79].Laddr = 0x26; 	ASIC_Config[79].data = 0x00; 	ASIC_Config[79].cmd = 0x01;
	ASIC_Config[80].Haddr = 0x00;	ASIC_Config[80].Laddr = 0x26; 	ASIC_Config[80].data = 0x01; 	ASIC_Config[80].cmd = 0x00;
	ASIC_Config[81].Haddr = 0x00;	ASIC_Config[81].Laddr = 0x2C; 	ASIC_Config[81].data = 0x00; 	ASIC_Config[81].cmd = 0x01;
	ASIC_Config[82].Haddr = 0x00;	ASIC_Config[82].Laddr = 0x2C; 	ASIC_Config[82].data = 0x0A; 	ASIC_Config[82].cmd = 0x00;
	ASIC_Config[83].Haddr = 0x00;	ASIC_Config[83].Laddr = 0x2D; 	ASIC_Config[83].data = 0x00; 	ASIC_Config[83].cmd = 0x01;
	ASIC_Config[84].Haddr = 0x00;	ASIC_Config[84].Laddr = 0x2D; 	ASIC_Config[84].data = 0x2B; 	ASIC_Config[84].cmd = 0x00;
	ASIC_Config[85].Haddr = 0x00;	ASIC_Config[85].Laddr = 0x2E; 	ASIC_Config[85].data = 0x00; 	ASIC_Config[85].cmd = 0x01;
	ASIC_Config[86].Haddr = 0x00;	ASIC_Config[86].Laddr = 0x2E; 	ASIC_Config[86].data = 0xFB; 	ASIC_Config[86].cmd = 0x00;
	ASIC_Config[87].Haddr = 0x00;	ASIC_Config[87].Laddr = 0x2C; 	ASIC_Config[87].data = 0x00; 	ASIC_Config[87].cmd = 0x01;
	ASIC_Config[88].Haddr = 0x00;	ASIC_Config[88].Laddr = 0x2C; 	ASIC_Config[88].data = 0x0A; 	ASIC_Config[88].cmd = 0x00;
	ASIC_Config[89].Haddr = 0x00;	ASIC_Config[89].Laddr = 0x2D; 	ASIC_Config[89].data = 0x00; 	ASIC_Config[89].cmd = 0x01;
	ASIC_Config[90].Haddr = 0x00;	ASIC_Config[90].Laddr = 0x2D; 	ASIC_Config[90].data = 0x2B; 	ASIC_Config[90].cmd = 0x00;
	ASIC_Config[91].Haddr = 0x00;	ASIC_Config[91].Laddr = 0x2C; 	ASIC_Config[91].data = 0x00; 	ASIC_Config[91].cmd = 0x01;
	ASIC_Config[92].Haddr = 0x00;	ASIC_Config[92].Laddr = 0x2C; 	ASIC_Config[92].data = 0x0A; 	ASIC_Config[92].cmd = 0x00;
	ASIC_Config[93].Haddr = 0x00;	ASIC_Config[93].Laddr = 0x2D; 	ASIC_Config[93].data = 0x00; 	ASIC_Config[93].cmd = 0x01;
	ASIC_Config[94].Haddr = 0x00;	ASIC_Config[94].Laddr = 0x2D; 	ASIC_Config[94].data = 0x3B; 	ASIC_Config[94].cmd = 0x00;
	ASIC_Config[95].Haddr = 0x00;	ASIC_Config[95].Laddr = 0x30; 	ASIC_Config[95].data = 0x00; 	ASIC_Config[95].cmd = 0x01;
	ASIC_Config[96].Haddr = 0x00;	ASIC_Config[96].Laddr = 0x30; 	ASIC_Config[96].data = 0x83; 	ASIC_Config[96].cmd = 0x00;
	ASIC_Config[97].Haddr = 0x00;	ASIC_Config[97].Laddr = 0x34; 	ASIC_Config[97].data = 0x40; 	ASIC_Config[97].cmd = 0x00;
	ASIC_Config[98].Haddr = 0x00;	ASIC_Config[98].Laddr = 0x35; 	ASIC_Config[98].data = 0x00; 	ASIC_Config[98].cmd = 0x01;
	ASIC_Config[99].Haddr = 0x00;	ASIC_Config[99].Laddr = 0x35; 	ASIC_Config[99].data = 0xFC; 	ASIC_Config[99].cmd = 0x00;	//DAC_IN_SPI_SW (BIT2) 0-IO
	ASIC_Config[100].Haddr = 0x00;	ASIC_Config[100].Laddr = 0x3F;	ASIC_Config[100].data = 0x00;	ASIC_Config[100].cmd = 0x01;
	ASIC_Config[101].Haddr = 0x00;	ASIC_Config[101].Laddr = 0x3F;	ASIC_Config[101].data = 0x08;	ASIC_Config[101].cmd = 0x00; //DAC_IN_SW (BIT4) 1-PositionGenerator 10
	ASIC_Config[102].Haddr = 0x00;	ASIC_Config[102].Laddr = 0x35;	ASIC_Config[102].data = 0x00;	ASIC_Config[102].cmd = 0x01;
	ASIC_Config[103].Haddr = 0x00;	ASIC_Config[103].Laddr = 0x35;	ASIC_Config[103].data = 0xFC;	ASIC_Config[103].cmd = 0x00; //DAC_IN_SPI_SW (BIT2) 0-IO
	ASIC_Config[104].Haddr = 0x00;	ASIC_Config[104].Laddr = 0x39;	ASIC_Config[104].data = 0x00; 	ASIC_Config[104].cmd = 0x01;
	ASIC_Config[105].Haddr = 0x00;	ASIC_Config[105].Laddr = 0x39;	ASIC_Config[105].data = 0x16; 	ASIC_Config[105].cmd = 0x00;
	ASIC_Config[106].Haddr = 0x00;	ASIC_Config[106].Laddr = 0x3B;	ASIC_Config[106].data = 0x00; 	ASIC_Config[106].cmd = 0x01;
	ASIC_Config[107].Haddr = 0x00;	ASIC_Config[107].Laddr = 0x3B;	ASIC_Config[107].data = 0x19; 	ASIC_Config[107].cmd = 0x00;
	ASIC_Config[108].Haddr = 0x00;	ASIC_Config[108].Laddr = 0x3A;	ASIC_Config[108].data = 0x00; 	ASIC_Config[108].cmd = 0x00;
	ASIC_Config[109].Haddr = 0x00;	ASIC_Config[109].Laddr = 0x3B;	ASIC_Config[109].data = 0x00; 	ASIC_Config[109].cmd = 0x01;
	ASIC_Config[110].Haddr = 0x00;	ASIC_Config[110].Laddr = 0x3B;	ASIC_Config[110].data = 0x19; 	ASIC_Config[110].cmd = 0x00;
	ASIC_Config[111].Haddr = 0x00;	ASIC_Config[111].Laddr = 0x38;	ASIC_Config[111].data = 0x00; 	ASIC_Config[111].cmd = 0x00;
	ASIC_Config[112].Haddr = 0x00;	ASIC_Config[112].Laddr = 0x39;	ASIC_Config[112].data = 0x00; 	ASIC_Config[112].cmd = 0x01;
	ASIC_Config[113].Haddr = 0x00;	ASIC_Config[113].Laddr = 0x39;	ASIC_Config[113].data = 0x16; 	ASIC_Config[113].cmd = 0x00;
	ASIC_Config[114].Haddr = 0x00;	ASIC_Config[114].Laddr = 0x3C;	ASIC_Config[114].data = 0x14; 	ASIC_Config[114].cmd = 0x00;
	ASIC_Config[115].Haddr = 0x00;	ASIC_Config[115].Laddr = 0x3D;	ASIC_Config[115].data = 0x3B; 	ASIC_Config[115].cmd = 0x00;
	ASIC_Config[116].Haddr = 0x00;	ASIC_Config[116].Laddr = 0x3F;	ASIC_Config[116].data = 0x00; 	ASIC_Config[116].cmd = 0x01;
	ASIC_Config[117].Haddr = 0x00;	ASIC_Config[117].Laddr = 0x3F;	ASIC_Config[117].data = 0x10; 	ASIC_Config[117].cmd = 0x00; //DAC_IN_SW (BIT4) 0-IO
	ASIC_Config[118].Haddr = 0x00;	ASIC_Config[118].Laddr = 0x30;	ASIC_Config[118].data = 0x00; 	ASIC_Config[118].cmd = 0x01;
	ASIC_Config[119].Haddr = 0x00;	ASIC_Config[119].Laddr = 0x30;	ASIC_Config[119].data = 0x80; 	ASIC_Config[119].cmd = 0x00;
	ASIC_Config[120].Haddr = 0x00;	ASIC_Config[120].Laddr = 0x31;	ASIC_Config[120].data = 0x00; 	ASIC_Config[120].cmd = 0x01;
	ASIC_Config[121].Haddr = 0x00;	ASIC_Config[121].Laddr = 0x31;	ASIC_Config[121].data = 0x11; 	ASIC_Config[121].cmd = 0x00;
	ASIC_Config[122].Haddr = 0x00;	ASIC_Config[122].Laddr = 0x0D;	ASIC_Config[122].data = 0x00; 	ASIC_Config[122].cmd = 0x01;
	ASIC_Config[123].Haddr = 0x00;	ASIC_Config[123].Laddr = 0x0B;	ASIC_Config[123].data = 0x00; 	ASIC_Config[123].cmd = 0x01;
	ASIC_Config[124].Haddr = 0x00;	ASIC_Config[124].Laddr = 0x0B;	ASIC_Config[124].data = 0x8B; 	ASIC_Config[124].cmd = 0x00; //Dis_Dig_out (BIT7) 1
	ASIC_Config[125].Haddr = 0x00;	ASIC_Config[125].Laddr = 0x0D;	ASIC_Config[125].data = 0x00; 	ASIC_Config[125].cmd = 0x01;
	ASIC_Config[126].Haddr = 0x00;	ASIC_Config[126].Laddr = 0x0D;	ASIC_Config[126].data = 0x4B; 	ASIC_Config[126].cmd = 0x00; //EH (BIT6) 1-Disabled
	ASIC_Config[127].Haddr = 0x00;	ASIC_Config[127].Laddr = 0x10;	ASIC_Config[127].data = 0x00; 	ASIC_Config[127].cmd = 0x01;
	ASIC_Config[128].Haddr = 0x00;	ASIC_Config[128].Laddr = 0x10;	ASIC_Config[128].data = 0x7B; 	ASIC_Config[128].cmd = 0x00;
	ASIC_Config[129].Haddr = 0x00;	ASIC_Config[129].Laddr = 0x10;	ASIC_Config[129].data = 0x7F; 	ASIC_Config[129].cmd = 0x00;
	ASIC_Config[130].Haddr = 0x00;	ASIC_Config[130].Laddr = 0x10;	ASIC_Config[130].data = 0x78; 	ASIC_Config[130].cmd = 0x00;
	ASIC_Config[131].Haddr = 0x00;	ASIC_Config[131].Laddr = 0x10;	ASIC_Config[131].data = 0x7F; 	ASIC_Config[131].cmd = 0x00;
	ASIC_Config[132].Haddr = 0x00;	ASIC_Config[132].Laddr = 0x10;	ASIC_Config[132].data = 0x7B; 	ASIC_Config[132].cmd = 0x00;
	ASIC_Config[133].Haddr = 0x00;	ASIC_Config[133].Laddr = 0x10;	ASIC_Config[133].data = 0x7F; 	ASIC_Config[133].cmd = 0x00;
	ASIC_Config[134].Haddr = 0x00;	ASIC_Config[134].Laddr = 0x10;	ASIC_Config[134].data = 0x78; 	ASIC_Config[134].cmd = 0x00;
	ASIC_Config[135].Haddr = 0x00;	ASIC_Config[135].Laddr = 0x10;	ASIC_Config[135].data = 0x7F; 	ASIC_Config[135].cmd = 0x00;
	ASIC_Config[136].Haddr = 0x00;	ASIC_Config[136].Laddr = 0x10;	ASIC_Config[136].data = 0x7B; 	ASIC_Config[136].cmd = 0x00;
	ASIC_Config[137].Haddr = 0x00;	ASIC_Config[137].Laddr = 0x10;	ASIC_Config[137].data = 0x7F; 	ASIC_Config[137].cmd = 0x00;
	ASIC_Config[138].Haddr = 0x00;	ASIC_Config[138].Laddr = 0x10;	ASIC_Config[138].data = 0x78; 	ASIC_Config[138].cmd = 0x00;
	ASIC_Config[139].Haddr = 0x00;	ASIC_Config[139].Laddr = 0x10;	ASIC_Config[139].data = 0x7F; 	ASIC_Config[139].cmd = 0x00;
	ASIC_Config[140].Haddr = 0x00;	ASIC_Config[140].Laddr = 0x10;	ASIC_Config[140].data = 0x7B;	ASIC_Config[140].cmd = 0x00;
	ASIC_Config[141].Haddr = 0x00;	ASIC_Config[141].Laddr = 0x10;	ASIC_Config[141].data = 0x7F; 	ASIC_Config[141].cmd = 0x00;
	ASIC_Config[142].Haddr = 0x00;	ASIC_Config[142].Laddr = 0x10;	ASIC_Config[142].data = 0x78; 	ASIC_Config[142].cmd = 0x00;
	ASIC_Config[143].Haddr = 0x00;	ASIC_Config[143].Laddr = 0x10;	ASIC_Config[143].data = 0x7F; 	ASIC_Config[143].cmd = 0x00;
	ASIC_Config[144].Haddr = 0x00;	ASIC_Config[144].Laddr = 0x10;	ASIC_Config[144].data = 0x7B; 	ASIC_Config[144].cmd = 0x00;
	ASIC_Config[145].Haddr = 0x00;	ASIC_Config[145].Laddr = 0x10;	ASIC_Config[145].data = 0x7F; 	ASIC_Config[145].cmd = 0x00;
	ASIC_Config[146].Haddr = 0x00;	ASIC_Config[146].Laddr = 0x10;	ASIC_Config[146].data = 0x78; 	ASIC_Config[146].cmd = 0x00;
	ASIC_Config[147].Haddr = 0x00;	ASIC_Config[147].Laddr = 0x10;	ASIC_Config[147].data = 0x7F; 	ASIC_Config[147].cmd = 0x00;

	this->lock();

	while(i < NASICConfig_CMD)
	{
		ASIC_SendCommand(&ASIC_Config[i]);
		i = i + 1;
	}

	this->unlock();
}

void AXIInterfaceClass::POT_Configuration(void)
{
	POT_command POT_Config[NPOTConfig_CMD];
	int pot_spi_ready = 0;
	int i = 0;

	POT_Config[0].addr = 0;	POT_Config[0].data = 118;
	POT_Config[1].addr = 0;	POT_Config[1].data = 20;
	POT_Config[2].addr = 1;	POT_Config[2].data = 80;

	this->lock();

	while(i < NPOTConfig_CMD)
	{
		pot_spi_ready = *(arm_ptr + 0x05);
		if(pot_spi_ready==1) //POT_SPI_READY
		{
			*(arm_ptr + 0x04) = (POT_Config[i].addr << 8) | POT_Config[i].data;
			axiReg2_data = axiReg2_data + POT_NEW_DATA;
			*(arm_ptr + 0x02) = axiReg2_data;
			axiReg2_data = axiReg2_data - POT_NEW_DATA;
			*(arm_ptr + 0x02) = axiReg2_data;
			i = i + 1;
		}

		nanosleep((const struct timespec[]){{0, 2500000L}}, NULL);
	}

	this->unlock();
}

void AXIInterfaceClass::TDC_Enable(void)
{
	this->lock();

	axiReg2_data = axiReg2_data + TDC_EN;
	*(arm_ptr + 0x02) = axiReg2_data;

	this->unlock();
}

void AXIInterfaceClass::TDC_Disable(void)
{
	this->lock();

	axiReg2_data = axiReg2_data - TDC_EN;
	*(arm_ptr + 0x02) = axiReg2_data;

	this->unlock();
}







void AXIInterfaceClass::TimingCore_Configuration(void)
{
	this->lock();

	*(tc_ptr + 0x01) = FRAME_COLUMNS - 1;
	*(tc_ptr + 0x02) = FRAME_ROWS - 1;
	*(tc_ptr + 0x03) = ((MEMCYCLES-1)<<3) | (NUMBER_OF_FRAMES-1);
	*(tc_ptr + 0x04) = PULSE_LENGTH;
	*(tc_ptr + 0x05) = QUARTER_MIRROR_CYCLE_DELAY;

	this->unlock();
}

void AXIInterfaceClass::TimingCore_Enable(void)
{
	this->lock();

	axiReg2_data = axiReg2_data + TIMING_CORE_EN;
	*(arm_ptr + 0x02) = axiReg2_data;

	this->unlock();
}

void AXIInterfaceClass::TimingCore_Disable(void)
{
	this->lock();

	axiReg2_data = axiReg2_data - TIMING_CORE_EN;
	*(arm_ptr + 0x02) = axiReg2_data;

	this->unlock();
}

void AXIInterfaceClass::TimingCore_Memory_Enable(void)
{
	this->lock();

	*(tc_ptr + 0x00) = 1;

	this->unlock();
}

void AXIInterfaceClass::TimingCore_Memory_Disable(void)
{
	this->lock();

	*(tc_ptr + 0x00) = 0;

	this->unlock();
}

int AXIInterfaceClass::TimingCore_Memory_Update(void)
{
	int value;

	this->lock();

	value = * (tc_ptr + 0x01);

	this->unlock();

	return value;
}

void AXIInterfaceClass::TimingCore_Write(int data)
{
	this->lock();

	*(tc_ptr + 0x06) = data;
	*(tc_ptr + 0x07) = 1;
	*(tc_ptr + 0x07) = 0;

	this->unlock();
}

void AXIInterfaceClass::TimingCore_Update_QuarterMirrorCycleDelay(int qmcd)
{
	this->lock();

	* (tc_ptr + 0x05) = qmcd;

	this->unlock();
}

int AXIInterfaceClass::TimingCore_Frequency_Read(void)
{
	int value;

	this->lock();

	value = * (tc_ptr + 0x00);

	this->unlock();

	return value;
}









void AXIInterfaceClass::ASIC_SendCommand(ASIC_command * ASIC)
{

	*(arm_ptr + 0x00) = ASIC->data;
	*(arm_ptr + 0x01) = (ASIC->cmd<<16 | ASIC->Haddr<<8 | ASIC->Laddr);
	axiReg2_data = axiReg2_data + ASIC_NEW_DATA;
	*(arm_ptr + 0x02) = axiReg2_data;
	axiReg2_data = axiReg2_data - ASIC_NEW_DATA;
	*(arm_ptr + 0x02) = axiReg2_data;

	nanosleep((const struct timespec[]){{0, 2500000L}}, NULL);

}

void AXIInterfaceClass::ASIC_ChangeVerticalGain(char vGain)
{
	char addr = 0;
	char data = 0;

	ASIC_command asic_c;

	data = vGain | 0x00000080;
	data = data & 0x0000008F;
	addr = 11; //0x0B

	this->lock();

	asic_c = {0x00,0x0D,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,addr,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,addr,data,0x00};
	ASIC_SendCommand(&asic_c);

	this->unlock();
}

void AXIInterfaceClass::ASIC_EnableVertical(char vGain)
{
	char auxVgain = vGain;
	char addr = 0;
	int i;

	ASIC_command asic_c;

	this->lock();

	asic_c = {0x00,0x0D,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x0B,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x0B,0x80,0x00};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x0D,0xCB,0x00};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x0B,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	auxVgain = 0;
	addr = 11; //0x0B
	for(i = 0; i < vGain; i++){
		auxVgain = i+1;
		auxVgain = auxVgain | 0x00000080;
		auxVgain = auxVgain & 0x0000008F;

		asic_c = {0x00,addr,auxVgain,0x00};
		ASIC_SendCommand(&asic_c);
	}

	this->unlock();
}

void AXIInterfaceClass::ASIC_DisableVertical(char vGain)
{
	char auxVgain = vGain;
	char addr = 0;
	int i;

	ASIC_command asic_c;

	this->lock();

	asic_c = {0x00,0x0D,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x0B,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x0B,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	auxVgain = 0;
	addr = 11; //0x0B
	for(i = vGain; i > 0; i--){
		auxVgain = i-1;
		auxVgain = auxVgain | 0x00000080;
		auxVgain = auxVgain & 0x0000008F;

		asic_c = {0x00,addr,auxVgain,0x00};
		ASIC_SendCommand(&asic_c);
	}

	asic_c = {0x00,0x0D,0x4B,0x00};
	ASIC_SendCommand(&asic_c);

	auxVgain = vGain;
	auxVgain = auxVgain | 0x00000080;
	auxVgain = auxVgain & 0x0000008F;

	asic_c = {0x00,0x0B,auxVgain,0x00};
	ASIC_SendCommand(&asic_c);

	this->unlock();
}

char AXIInterfaceClass::ASIC_Read(char address)
{
	char value;

	ASIC_command asic_c;

	this->lock();

	asic_c = {0x00,address,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	value = *(arm_ptr + 0x03);

	this->unlock();

	return value;
}

void AXIInterfaceClass::ASIC_Write(char addr, char data)
{
	ASIC_command asic_c;

	this->lock();

	asic_c = {0x00,addr,data,0x00};
	ASIC_SendCommand(&asic_c);

	this->unlock();
}

void AXIInterfaceClass::POT_ChangeHorizontalGain(int hGain)
{
	int pot_spi_ready = 0;
	int pot_addr = 0;
	int pot_data = 0;
	int data;

	pot_spi_ready = *(arm_ptr + 0x05);
	if(pot_spi_ready==1) {
		pot_addr = 0;
		//data must be inverted bitwise to agree with Maradin mode of operation
		data = ~hGain;
		data = (0x000000FF & data);
		//xil_printf("data inverted: %x\n", data);
		pot_data = (pot_addr << 8) | data;
		//xil_printf("pot_data: %x\n", pot_data);

		this->lock();

		*(arm_ptr + 0x04) = pot_data;
		axiReg2_data = axiReg2_data + POT_NEW_DATA;
		*(arm_ptr + 0x02) = axiReg2_data;
		axiReg2_data = axiReg2_data - POT_NEW_DATA;
		*(arm_ptr + 0x02) = axiReg2_data;
		nanosleep((const struct timespec[]){{0, 2500000L}}, NULL);

		this->unlock();
	}
}

void AXIInterfaceClass::POT_EnableHorizontal(void)
{
	char data = 75; //0x4B
	char addr = 14; //0x0D
	int i,j;

	//AUXILIAR DATA BUFFER FOR VERTICAL ENABLE/DISABLE
	char aux_data[4] = {0x7B,0x7F,0x78,0x7F};

	ASIC_command asic_c;

	this->lock();

	asic_c = {0x00,char(addr),0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,addr,data,0x00};
	ASIC_SendCommand(&asic_c);

	addr = 16; //0x10

	asic_c = {0x00,addr,0x00,0x01};
	ASIC_SendCommand(&asic_c);

	for(i = 0; i < 5; i++){
		for(j = 0; j < 4; j++){

			asic_c = {0x00,addr, aux_data[j],0x00};
			ASIC_SendCommand(&asic_c);
		}
	}

	this->unlock();
}

void AXIInterfaceClass::POT_DisableHorizontal(int vGain)
{
	char data = vGain;
	char addr = 14; //0x0D

	ASIC_command asic_c;

	this->lock();

	asic_c = {0x00,addr, 0x00,0x01};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,addr, data,0x00};
	ASIC_SendCommand(&asic_c);

	this->unlock();
}

int AXIInterfaceClass::Frequency_Read(void)
{
	int value;

	this->lock();

	value = * (arm_ptr + 0x00);

	this->unlock();

	return value;
}

void AXIInterfaceClass::Laser_ChangeFrequency(int freq)
{
	this->lock();

	* (arm_ptr + 0x07) = freq;

	this->unlock();
}

void AXIInterfaceClass::VerticalController_Configuration(void)
{
	ASIC_command asic_c;

	this->lock();

	this->vsync = 0;

	asic_c = {0x00,0x35, 0xFC,0x00};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x34, 0xFF,0x00};
	ASIC_SendCommand(&asic_c);

	this->VSync_Enable();

	this->unlock();
}

void AXIInterfaceClass::UpdateVerticalPosition(void) {

	this->lock();

	this->VSync_Enable();

	this->unlock();
}

void AXIInterfaceClass::VMirror_ChangeVerticalPosition(int MSG, int LSG)
{
	ASIC_command asic_c;

	char msgain, lsgain;

	this->lock();

	msgain = ((MSG << 3) | 0x04) & 0xFF;
	lsgain = LSG & 0xFF;

	asic_c = {0x00,0x35, msgain,0x00};
	ASIC_SendCommand(&asic_c);

	asic_c = {0x00,0x34, lsgain,0x00};
	ASIC_SendCommand(&asic_c);

	this->unlock();
}

void AXIInterfaceClass::VSync_Enable()
{

	if(this->vsync == 1)
		this->vsync = 0;
	else	this->vsync = 1;

	*(vmirror_ptr + 0x04) = this->vsync;

}
