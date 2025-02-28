
load('Cylinder_in_Center_in_Motion_17-Nov-2019_14-53.mat');

c = physconst('LightSpeed');

fc = 7.29e9;

rangeResolution = 3;  
crossRangeResolution = 3;   

bw = c/(2*rangeResolution);

fs = 2.332800384e10;
prf = 14294120;
pw = 1/prf;
aperture = 4;

load('data.mat');
x_loc = data.AntX;
y_loc = data.AntY;
z_loc = zeros(1,676);

b = [0 time_samples(1:675)];

waveform = phased.RectangularWaveform('SampleRate', 2.332800384e10, 'PulseWidth', pw , 'PRF', prf, 'OutputFormat', 'Samples', 'NumSamples',...
    1536);

wpts = [b' x_loc' y_loc' z_loc'];

platform = phased.Platform('MotionModel','Custom',...
    'CustomTrajectory', wpts);

plot3(x_loc, y_loc, z_loc)
speed = 100;  
flightDuration = 4;

slowTime = 1/prf;


maxRange = 10;
truncrangesamples = 676;
fastTime = (0:1/fs:(truncrangesamples-1)/fs);
% Set the reference range for the cross-range processing.
Rc = 25;

antenna = phased.CosineAntennaElement('FrequencyRange', [1e9 12e9]);
antennaGain = aperture2gain(aperture,c/fc); 

transmitter = phased.Transmitter('PeakPower', 50e3, 'Gain', antennaGain);
radiator = phased.Radiator('Sensor', antenna,'OperatingFrequency', fc, 'PropagationSpeed', c);

collector = phased.Collector('Sensor', antenna, 'PropagationSpeed', c,'OperatingFrequency', fc);
receiver = phased.ReceiverPreamp('SampleRate', fs, 'NoiseFigure', 30);

channel = phased.FreeSpace('PropagationSpeed', c, 'OperatingFrequency', fc,'SampleRate', fs,...
    'TwoWayPropagation', true);

targetpos= [.5,.5,0;.1,.1,0; 0,0,0]'; 

targetvel = [0,0,0;0,0,0; 0,0,0]';

target = phased.RadarTarget('OperatingFrequency', fc, 'MeanRCS', [1,1,1]);
pointTargets = phased.Platform('InitialPosition', targetpos,'Velocity',targetvel);
% The figure below describes the ground truth based on the target
% locations.
figure(2);h = axes;plot(targetpos(2,1),targetpos(1,1),'*g');hold all;plot(targetpos(2,2),targetpos(1,2),'*r');hold all;plot(targetpos(2,3),targetpos(1,3),'*b');hold off;
set(h,'Ydir','reverse');xlim([-10 10]);ylim([-10 10]);
title('Ground Truth');ylabel('Range');xlabel('Cross-Range');

numpulses = 1536;
% Define the broadside angle
refangle = zeros(1,size(targetpos,2));
rxsig = zeros(truncrangesamples,numpulses);
for ii = 1:numpulses
    % Update radar platform and target position
    [radarpos, radarvel] = radarPlatform(slowTime);
    [targetpos,targetvel] = pointTargets(slowTime);
    
    % Get the range and angle to the point targets
    [targetRange, targetAngle] = rangeangle(targetpos, radarpos);
    
    % Generate the LFM pulse
    sig = waveform();
    % Use only the pulse length that will cover the targets.
    sig = sig(1:truncrangesamples);
    
    % Transmit the pulse
    sig = transmitter(sig);
    
    % Define no tilting of beam in azimuth direction
    targetAngle(1,:) = refangle;
    
    % Radiate the pulse towards the targets
    sig = radiator(sig, targetAngle);
    
    % Propagate the pulse to the point targets in free space
    sig = channel(sig, radarpos, targetpos, radarvel, targetvel);
    
    % Reflect the pulse off the targets
    sig = target(sig);
    
    % Collect the reflected pulses at the antenna
    sig = collector(sig, targetAngle);
    
    % Receive the signal  
    rxsig(:,ii) = receiver(sig);
    
end


