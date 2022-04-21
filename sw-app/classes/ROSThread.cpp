#include "ROSThread.h"

#include <ros/ros.h>
#include <sensor_msgs/PointCloud2.h>
#include <pthread.h>

// PCL library includes
#include <pcl/point_cloud.h>
#include <pcl/io/pcd_io.h>
#include <pcl/point_types.h>
#include <pcl_conversions/pcl_conversions.h>

#include "dma-proxy.h"

#include <iostream>
#include <fstream>

void ROSThread::run() {

	StopClass * stop = reinterpret_cast<ROSargs *> (this->arg)->stop;
	TOFClass * ToF = reinterpret_cast<ROSargs *> (this->arg)->tof;
	FireClass * fire = reinterpret_cast<ROSargs *> (this->arg)->fire;
	int argc = reinterpret_cast<ROSargs *> (this->arg)->argc;
	char ** argv = reinterpret_cast<ROSargs *> (this->arg)->argv;

	pcl::PointCloud<pcl::PointXYZ> pcl_frame;
	sensor_msgs::PointCloud2 pcl2_frame;

	int row = 0;
	int column = 0;
	std::vector<unsigned int> ToFData;
    std::vector <FireInfo> FireData;
	// First frame has seq = 0
	uint64_t pcl2_Header_seq = 0;
	float distance;

	int TransferSize = 0;

	pcl_frame.width = FRAME_COLUMNS;
	pcl_frame.height = FRAME_ROWS;
	pcl_frame.points.resize(pcl_frame.width*pcl_frame.height);

	// Create and open a text file
	//std::ofstream MyFile("TDCv.txt");

	ros::init(argc, argv, "LIDAR_Zedboard");
	ros::NodeHandle n;
	ros::Publisher chatter_pub = n.advertise<sensor_msgs::PointCloud2>("LIDAR_TOF", 100);

	while(!stop->get() || (stop->get() && ToF->size() > 0)) {

		row = 0;
		column = 0;

		while(row < FRAME_ROWS)
		{
			// Read Time-of-flight Data
			ToFData = ToF->dequeue();

			if(row%MEMCYCLES == 0 && !stop->get()) {
				//std::cout << "Memory" << row << "\n";
				FireData = fire->dequeue();
				//std::cout << "MemoryUpdated" << FireData.at(0).frame << "\n";
			}

			if(!ToFData.empty())
			{
				TransferSize += ToFData.size();

				//data = FireData;

				while(column < FRAME_COLUMNS) {

					// Calculate distance in meters; d = v*t -> v = speed of light in m/ps
					distance = (ToFData.at(column) * 0.000299792458);

					//MyFile << ToFData.at(column) << std::endl;

					// Build pcl::PointCloud<pcl::PointXYZ>
					pcl_frame.points[row*FRAME_COLUMNS + column].x = column - FRAME_COLUMNS/2; //FireData.at(column).Y
					pcl_frame.points[row*FRAME_COLUMNS + column].z = row - FRAME_ROWS/2;
					pcl_frame.points[row*FRAME_COLUMNS + column].y = distance;

					//std::cout << "Row" << row << " <-> Col" << column << "\n";

					//data.pop_front();

					column++;
				}

				ToFData.clear();
				column = 0;
				row++;
			}
		}

		fire->changeFrame();

		//std::cout << "NewFrame" << std::endl;

		// Convert from pcl::PointCloud<pcl::PointXYZ> to sensor_msgs::PointCloud2
		pcl::toROSMsg(pcl_frame, pcl2_frame);

		// Complete Header of the PointCloud2
		pcl2_frame.header.frame_id = "LIDAR_Zedboard_frame";
		pcl2_frame.header.seq = pcl2_Header_seq;
		pcl2_frame.header.stamp = ros::Time::now();

		// Increment sequence to be used with the next frame
		pcl2_Header_seq++;

		chatter_pub.publish(pcl2_frame);
		//std::cout << "Publish" << std::endl;
	}

	std::cout << "ROS Transfer Size:" << TransferSize << std::endl;

	//MyFile.close();
}
