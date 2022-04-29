#define _USE_MATH_DEFINES
#include <iostream>
#include <vector>
#include <string>
#include <cmath>
#include <complex>
#include <fstream> 

#define THETAMAX 9 //maximum mechanical angular deflection
#define SYSCLOCK 500000000 //500MHz clock
#define FRAME_COLUMNS 360
#define NUMBER_OF_FRAMES 5
#define TOTALPOINTS (FRAME_COLUMNS*NUMBER_OF_FRAMES)
#define POINTS_PER_LINE 20
#define NUMBER_OF_PASSAGES (FRAME_COLUMNS/POINTS_PER_LINE)
std::ofstream dt_ticks_file ("dt_ticks.txt");
std::ofstream mem_arrange_file ("mem_arrange.txt");
std::ofstream my_mem_arrange_file ("my_mem_arrange.txt");
std::ofstream arrange_ticks_file ("arrange_ticks.txt");
std::ofstream my_arrange_ticks_file ("my_arrange_ticks.txt");
std::ofstream trigger_ticks_file ("trigger_ticks.txt");

int main(int argc, char *argv[]) {
    std::cout << std::endl << std::endl << "**********************************" << std::endl << std::endl;
    int newcycle = 1;
	int precycle = 1;
	double freq = 0;
	double wn;
	double dt;
	std::complex <double> t_next;
	double thetaM = (THETAMAX*M_PI)/180;
	double step = ((2*thetaM)/(TOTALPOINTS-1));
	double theta;
	double nextTheta;

	int active_pixel = 1;
	unsigned int addr = 0;
	unsigned int myaddr = 0;
	int data2send = 0;
	unsigned int i;
	unsigned int dt_ticks;
	unsigned int mydt_ticks;
    unsigned int last_dt_ticks;

	int quarter_mirror_cycle_delay;

	int memory_selector = 0;
	int temp[NUMBER_OF_FRAMES][FRAME_COLUMNS];
	int temp_inv[NUMBER_OF_FRAMES][FRAME_COLUMNS];

	int order = 0;
	int prev_addr = 0;
	int myprev_addr = 0;
	int addr_aux = 0;
	int iterator = 0;
	int myiterator = 0;

	int vposition = 0x1FFF;
	int MSG, LSG;
	int FireSize = 0;
    int counter_frames = 0;

	//StopClass * stop = reinterpret_cast<Mathargs *> (this->arg)->stop;
	//AXIInterfaceClass * axiptr = reinterpret_cast<Mathargs *> (this->arg)->axi;
	//FireClass * fire = reinterpret_cast<Mathargs *> (this->arg)->fire;

	//std::vector <FireInfo> fireData (FRAME_COLUMNS, FireInfo {0,false,0,0,0});


	//while (!stop->get())
	//{
		//newcycle = axiptr->TimingCore_Memory_Update();
		//axiptr->TimingCore_Memory_Enable();

        precycle = 0;//just to make it start
		if	(newcycle != precycle) {

			addr = 0;
			myaddr =0;
			memory_selector = 0;

			//axiptr->TimingCore_Memory_Disable(); //memory being updated
			precycle = newcycle;

			//freq = axiptr->TimingCore_Frequency_Read();

            freq = (int)SYSCLOCK/10800;//assuming mirror at 10800Hz
            //std::cout << "Freq from HW = " << freq << std::endl;

			quarter_mirror_cycle_delay = (int)(freq/2);			//Não deverá ser a /4?????
            //std::cout << "Quarter Mirror Cycle Delay = " << quarter_mirror_cycle_delay << std::endl;

			freq = 1/((freq*2)/(1000000000));
            //std::cout << "Freq = " << freq << std::endl;

			wn = (2*M_PI*freq);
			dt = 0;
			theta = thetaM;
			nextTheta = 0;
			dt_ticks = 0;
            last_dt_ticks = 0;
			t_next = 0;

			for (i=0; i<TOTALPOINTS; i++)	{
				nextTheta = theta - step;
				t_next = acos(std::complex <double> (nextTheta/thetaM)) / wn;
				dt = t_next.real();

				theta = nextTheta;
				dt_ticks = (int)(dt*SYSCLOCK);



                /*if(i == 0 || ((i-1) % 5 == 0)){
                    //std::cout << "Trigger " << i << "  dt_Tick "  << dt_ticks << std::endl;

                    dt_ticks_file << dt_ticks << std::endl;
                    trigger_ticks_file << (dt_ticks - last_dt_ticks) << std::endl;
                    last_dt_ticks = dt_ticks;
                }*/

                if(counter_frames == 0){
                    dt_ticks_file << dt_ticks << std::endl;
                    trigger_ticks_file << (dt_ticks - last_dt_ticks) << std::endl;
                    last_dt_ticks = dt_ticks;
                }

                counter_frames++;
                if(counter_frames == 5){
                    counter_frames = 0;
                }


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
			myaddr=0;
			prev_addr = 0;
			myprev_addr=0;
			dt_ticks = 0;
			mydt_ticks=0;
			addr_aux = 0;

			//for(int i = 0; i < NUMBER_OF_FRAMES; i++){
			for(int i = 1; i < 2; i++){
				addr = 0;
				myaddr=0;
				iterator = 0;
				myiterator=0;
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
							mem_arrange_file << "dt_ticks = temp[" << i << "][" << addr << "]" << std::endl;
						}
						else{
							if(order == 0){
								if(k==0){
									dt_ticks = temp_inv[i][0] - temp_inv[i][prev_addr] + temp[i][addr];
									mem_arrange_file << "dt_ticks = temp_inv[" << i << "][0] - temp_inv["  << i << "][" << prev_addr << "] + temp[" <<  i << "][" << addr << "]" << std::endl;
								}
								else{
									dt_ticks = temp[i][addr] - temp[i][prev_addr];
									mem_arrange_file << "dt_ticks = temp[" << i << "][" << addr << "] - temp["  << i << "][" << prev_addr << "]" << std::endl;
								}
							}
							else{
								if(k==0){
									dt_ticks = temp[i][FRAME_COLUMNS-1] - temp[i][prev_addr] + temp_inv[i][addr];
									mem_arrange_file << "dt_ticks = temp[" << i << "][" << FRAME_COLUMNS-1 << "] - temp["  << i << "][" << prev_addr << "] + temp_inv[" <<  i << "][" << addr << "]" << std::endl;
								}
								else{
									dt_ticks = temp_inv[i][addr] - temp_inv[i][prev_addr];
									mem_arrange_file << "dt_ticks = temp_inv[" << i << "][" << addr << "] - temp_inv["  << i << "][" << prev_addr << "]" << std::endl;
								}
							}
						}

						/***************************************/
						myaddr = (k*NUMBER_OF_PASSAGES) + myiterator;
						if(myaddr==0 && j==0){//just the first passage
							mydt_ticks = temp[i][myaddr];
							//my_mem_arrange_file << "dt_ticks = temp[" << i << "][" << myaddr << "]" << std::endl;
						}
						else
						{
							if(k == 0){
								//mydt_ticks = temp[i][FRAME_COLUMNS-1] - temp[i][myprev_addr] + temp[i][myaddr];
								mydt_ticks = temp[i][myaddr] - temp[i][myprev_addr] + temp[i][FRAME_COLUMNS-1];
								//my_mem_arrange_file << "dt_ticks = temp[" << i << "][" << FRAME_COLUMNS-1 << "] - temp["  << i << "][" << myprev_addr << "] + temp["  << i << "][" << myaddr << "]" << std::endl;
							}
							else{
								mydt_ticks = temp[i][myaddr] - temp[i][myprev_addr];
								//my_mem_arrange_file << "dt_ticks = temp[" << i << "][" << myaddr << "] - temp["  << i << "][" << myprev_addr << "]" << std::endl;
							}
						}
						

						/***************************************/
						arrange_ticks_file << dt_ticks << std::endl;
						my_arrange_ticks_file << mydt_ticks << std::endl;
						//Write to FIFO laser fire positions to be read by the ROS Thread when building the point cloud
						//fireData.at(addr_aux) = FireInfo {dt_ticks, true, 0, addr, i};

						//Add to fire_ptr->enqueue
						data2send = (dt_ticks | (active_pixel << 16) | (addr_aux << 17) | (i<<28));
						//axiptr->TimingCore_Write(data2send);


						prev_addr = addr;
						myprev_addr=myaddr;
						addr_aux++;
					}
					if(order == 0){
						order = 1;
					}
					else{
						order = 0;
						iterator++;
					myiterator++;
					}
				}

				//fire->enqueue(fireData);
			}

			//axiptr->TimingCore_Update_QuarterMirrorCycleDelay(quarter_mirror_cycle_delay);

			FireSize ++;
		}

		//nanosleep((const struct timespec[]){{0, 9000000L}}, NULL); // 1/20kHz * 90passages
	//}
    dt_ticks_file.close();
    trigger_ticks_file.close();
	//std::cout << "Math Transfer Size:" << FireSize << std::endl;

}