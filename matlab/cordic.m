THETAMAX=9;%maximum mechanical angular deflection
SYSCLOCK=500000000;%system freq
FRAME_COLUMNS=360;%horizontal points
NUMBER_OF_FRAMES=5;%pointcloud frames
TOTALPOINTS=FRAME_COLUMNS*NUMBER_OF_FRAMES;
MIRROR_FREQ=10800;

SYS_MIRROR_RATIO=SYSCLOCK/MIRROR_FREQ;%system ticks for 1 mirror period

thetaM=THETAMAX*pi/180;%thetamax in radians
step=2*thetaM/(TOTALPOINTS-1);%horizontal step between laser beams
quarter_mirror_cycle_delay=SYS_MIRROR_RATIO/4;%sync to start new line
wn=2*pi*MIRROR_FREQ;%mirror moviment

theta_it=0;
total_dt_ticks=0;
dt_ticks=0;
frame_it=1;
% open your file for writing
ticksFile = fopen('mirrorTicks.txt','wt');
previous_dt_ticks = cell(NUMBER_OF_FRAMES,1);
mirror_ticks=[];
laser_ticks=[];
for i = 1:NUMBER_OF_FRAMES 
  previous_dt_ticks{i} = 0; 
end


while theta_it < TOTALPOINTS
    %deltaT=deltaAngle/W
    current_theta=acos((thetaM-theta_it*step)/thetaM)/wn;%0-pi (first and second quandrants)
    %get ticks according to the system clock
    total_dt_ticks=round(current_theta*SYSCLOCK);

    %system ticks counting from the last one
    dt_ticks=total_dt_ticks-previous_dt_ticks{frame_it};

    laser_ticks=[laser_ticks,total_dt_ticks];
    mirror_ticks=[mirror_ticks,dt_ticks];

    fprintf(ticksFile,'%d\n',dt_ticks');

    %save current ticks
    previous_dt_ticks{frame_it}=total_dt_ticks;
    theta_it=theta_it+1;

    if(frame_it<NUMBER_OF_FRAMES)
        frame_it=frame_it+1;
    else 
        frame_it=1;
    end
end
fclose(ticksFile);

figure;
subplot(1,2,1)
plot(mirror_ticks,'linestyle','none','marker','.')
xlabel("pixel")
ylabel("diferential ticks")
subplot(1,2,2)
plot(laser_ticks,'linestyle','none','marker','.')
xlabel("pixel")
ylabel("total ticks")

