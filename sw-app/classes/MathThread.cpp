#include "MathThread.h"

#include <iostream>
#include <cmath>
#include <complex>

#include "FireClass.h"
#include "TOFClass.h"

#define THETAMAX 9 //maximum mechanical angular deflection
#define SYSCLOCK 500000000 //500MHz clock
#define TOTALPOINTS (FRAME_COLUMNS*NUMBER_OF_FRAMES)

void MathThread::run() {

	int newcycle = 1;
	int precycle = 1;
	double freq = 0;
	double wn;
	double dt;
	std::complex <double> dtc;
	std::complex <double> t_curr;
	std::complex <double> t_next;
	double thetaM = (THETAMAX*M_PI)/180;
	double step = ((2*thetaM)/(TOTALPOINTS-1));
	double theta;
	double nextTheta;

	int active_pixel = 1;
	unsigned int addr = 0;
	int data2send = 0;
	unsigned int i;
	unsigned int dt_ticks;

	int quarter_mirror_cycle_delay;

	int memory_selector = 0;
	int temp[NUMBER_OF_FRAMES][FRAME_COLUMNS];
	int temp_inv[NUMBER_OF_FRAMES][FRAME_COLUMNS];

	int order = 0;
	int prev_addr = 0;
	int addr_aux = 0;
	int iterator = 0;

	int vposition = 0x1FFF;
	int MSG, LSG;

	StopClass * stop = reinterpret_cast<Mathargs *> (this->arg)->stop;
	AXIInterfaceClass * axiptr = reinterpret_cast<Mathargs *> (this->arg)->axi;
	FireClass * fire = reinterpret_cast<Mathargs *> (this->arg)->fire;

	std::vector <FireInfo> fireData (FRAME_COLUMNS, FireInfo {0,false,0,0,0});

	int FireSize = 0;

	while (!stop->get())
	{
		newcycle = axiptr->TimingCore_Memory_Update();
		axiptr->TimingCore_Memory_Enable();

		//MSG = (vposition >> 8) & 0x1F;
		//LSG = vposition & 0xFF;

		//axiptr->VMirror_ChangeVerticalPosition(MSG,LSG);
		//axiptr->UpdateVerticalPosition();

		//if(vposition > 0)
		//	vposition = vposition - 1;
		//else vposition = 0x1FFF;


		if	(newcycle != precycle) {

			addr = 0;
			memory_selector = 0;

			axiptr->TimingCore_Memory_Disable(); //memory being updated
			precycle = newcycle;

			freq = axiptr->TimingCore_Frequency_Read();
			quarter_mirror_cycle_delay = (int)(freq/2);			//Não deverá ser a /4?????
			freq = 1/((freq*2)/(1000000000));
			wn = (2*M_PI*freq);
			dt = 0;
			dtc = 0;
			theta = thetaM;
			nextTheta = 0;
			dt_ticks = 0;
			//t_curr = (acos(theta/thetaM)/wn);
			t_next = 0;

			for (i=0; i<TOTALPOINTS; i++)	{
				nextTheta = theta - step;
				t_next = acos(std::complex <double> (nextTheta/thetaM)) / wn;
				dt = t_next.real();

				//t_curr = t_next;
				theta = nextTheta;
				dt_ticks = (int)(dt*SYSCLOCK);

				temp[memory_selector][addr] = dt_ticks;
				temp_inv[memory_selector][(FRAME_COLUMNS-1)-addr] = dt_ticks;

				if(memory_selector < NUMBER_OF_FRAMES-1){
					memory_selector++;
				} else{
					memory_selector=0;
					addr++;
				}
			}

			//reorganize the memory according to the number of point per line to fire
			memory_selector = 0;
			addr = 0;
			prev_addr = 0;
			dt_ticks = 0;
			addr_aux = 0;

			for(int i = 0; i < NUMBER_OF_FRAMES; i++){
				addr = 0;
				iterator = 0;
				addr_aux = 0;
				order = 0;
				for(int j = 0; j < NUMBER_OF_PASSAGES; j++){
					for(int k = 0; k < POINTS_PER_LINE; k++){
						if(order == 0){
							addr = (k*NUMBER_OF_PASSAGES) + iterator;
						}
						else{
							addr = (((POINTS_PER_LINE-1)-k)*NUMBER_OF_PASSAGES) + (NUMBER_OF_PASSAGES-1) - iterator;
						}

						if(addr == 0){
							dt_ticks = temp[i][addr];
						}
						else{
							if(order == 0){
								if(k==0){
									dt_ticks = temp_inv[i][0] - temp_inv[i][prev_addr] + temp[i][addr];
								}
								else{
									dt_ticks = temp[i][addr] - temp[i][prev_addr];
								}
							}
							else{
								if(k==0){
									dt_ticks = temp[i][FRAME_COLUMNS-1] - temp[i][prev_addr] + temp_inv[i][addr];
								}
								else{
									dt_ticks = temp_inv[i][addr] - temp_inv[i][prev_addr];
								}
							}
						}

						//Write to FIFO laser fire positions to be read by the ROS Thread when building the point cloud
						//fireData.pop_front();
						//fireData.push_back(FireInfo {dt_ticks, true, 0, addr, i}); //dt - active_pixel - X - Y - frame
						fireData.at(addr_aux) = FireInfo {dt_ticks, true, 0, addr, i};

						//Add to fire_ptr->enqueue
						data2send = (dt_ticks | (active_pixel << 16) | (addr_aux << 17) | (i<<28));
						axiptr->TimingCore_Write(data2send);


						prev_addr = addr;
						addr_aux++;
					}
					if(order == 0){
						order = 1;
					}
					else{
						order = 0;
						iterator++;
					}
				}

				fire->enqueue(fireData);
			}

			axiptr->TimingCore_Update_QuarterMirrorCycleDelay(quarter_mirror_cycle_delay);

			FireSize ++;
		}

		nanosleep((const struct timespec[]){{0, 9000000L}}, NULL); // 1/20kHz * 90passages
	}

	std::cout << "Math Transfer Size:" << FireSize << std::endl;
}
