%% csar demo 

c = physconst('LightSpeed');

fc = 7.29e9;   % center frequency
fs = 2.3328e10;   % Sampling Rate 
bwf = 1.4e9;      % bandwidth 
f_upper = 7.29e9+bwf/2;   % upper frequency 
f_lowwer = 7.29e9-bwf/2;  % lower frequency 


range_samples = 1536;     % number of fast time samples 
resolution    = c/range_samples/2; 

ncr = 200; % number of cross range samples (slow time track)  
theta_range = linspace(0,2*pi,ncr); 

Rg = 1.83;    % radius of circular track 

xR = Rg*cos(theta_range);   % x location of radar 
yR = Rg*sin(theta_range);   % y location of radar 

oX = 0;
oY = 0;

x_array  = linspace(0,9.9,1536);
y_array  = linspace(0,9.9,1536);
xx = 0;
yy = 0;

%% 

for j = 1:ncr 
        xx=x_array*cos(theta_range(j)+pi)+xR(j);
        yy=y_array*sin(theta_range(j)+pi)+yR(j);
        scatter(xx,yy,'b');
        axis([-2 2 -2 2])
        hold on

        
        
end

        

%% Signal Simulation 



ntarget=4;                        % number of targets
% Set ntarget=1 to see "clean" PSF of target at origin
% Try this with other targets

% xn: range;            yn= cross-range;    fn: reflectivity
  xn=zeros(1,ntarget);  yn=xn;              fn=xn;

% Targets within digital spotlight filter
%
  xn(1)=0;              yn(1)=0;            fn(1)=1;
  xn(2)=.7*X0;          yn(2)=-.6*Y0;       fn(2)=1.4;
  xn(3)=0;              yn(3)=-.85*Y0;      fn(3)=.8;
  xn(4)=-.5*X0;         yn(4)=.75*Y0;       fn(4)=1.;



 %% Backprojection 
 
 
filename = "Snow_Melted_Refrozen_40_deg_R_180_slice_x.gif" 

c = physconst('LightSpeed');

%max_amplitude;

fs = 7.29e9;

res = 1;

ncr = find(time_samples>60,1)

 % number of cross range samples (slow time track)  
degree = 20;
 
offset = 100;
theta_range = time_samples(1:ncr)*pi/30;

theta_range = circshift(theta_range,offset);

dd = scaledFrame;



ftres = 300   % fast Time res
stres = 300   % slow Time res 
zres  = 300   % z res 

data = zeros(ftres,stres);

R0 = 1.81 % radius from radar front to center of turntable 
fracR0 = .25 % fraction of radar return interested in, measured from center of radius
height = 1;

rd = R0;
%zd = 0;
zd = 0;


d = 0
max_cell = 0;
min_cell = 1000;
for rd_index = 1:size(rd,2)
for zd_index = 1:size(zd,2)
    
id = linspace(-rd(rd_index)*fracR0,rd(rd_index)*fracR0,ftres);
jd = linspace(-rd(rd_index)*fracR0,rd(rd_index)*fracR0,stres);
kd = linspace(0,.9,zres);
for i = 1:size(id,2)
    for j = 1:size(jd,2)
        d = 0;
        for k = 1:res:length(theta_range)
            xd = zd(zd_index)  - rd(rd_index)*cos(theta_range(k));
            yd = jd(j) - rd(rd_index)*sin(theta_range(k));
            zdd = height - kd(i);
            td = (2*sqrt(xd^2+yd^2+(zdd^2)));
            cell = round(td*(1536/9.9))+1;
            % cell = round(td*fs)+1;
            if (cell > max_cell)
                max_cell = cell;
            end
            if (cell < min_cell)
                min_cell = cell;
            end
            
                
            signal = abs(dd(cell,k));
            d = d + signal;
        end
        
        data(i,j) = d; 
    end
end



h = figure;
image = imagesc(flip(abs(data)));
%if max(max(data)) > max_amplitude
%    max_amplitude = max(max(data));
%end
scaledData = 20*log10(data./max(max(data)));
%image = imagesc(scaledData);
%caxis([-3 0]);
xticks(linspace(1,ftres,7));
xticklabels([linspace(jd(1),jd(end),7)]);
yticks(linspace(1,stres,7));
yticklabels([linspace(kd(end),kd(1),7)]);
xlabel('Y Range (m)');
ylabel('Z Cross-Range (m)');
title({['Snow Melted then Refrozen @ 45 deg']...
    ['Backprojection Reconstruction,',num2str(ftres),'x',num2str(stres), ' Resolution']...
    [' Slice @ X = ' num2str(zd(zd_index)), ' meters'] ...
    ['Radius @ R = ', num2str(rd(rd_index)),  ' meters'] ...
    [ 'Number of Pixels above -3db = ', num2str(length(find(scaledData>=-3))), ' Pixels']})
drawnow
% gif creation 
getframe(h);
frame = getframe(h); 
im = frame2im(frame); 
[imind,cm] = rgb2ind(im,256); 
if (zd_index == 1 && rd_index == 1)
          imwrite(imind,cm,filename,'gif', 'Loopcount',inf); 
      else 
          imwrite(imind,cm,filename,'gif','WriteMode','append'); 
end 
end
end