function [] = FinalPlot(path_start, Path_bez, l, square_axes, totl, color_bar...
    , speed_color, delta_t, d_speed_color, cb, cx, lr, x_sp)

%--------------------Final Plot-------------------------------%
%-------global variables----------%
global xf; %final position
global x0; %current starting pointPath_bez
global step_max; %max step distance
global step_min; %minimum step distance
global t; %parameterization variable
global n_obs; %number of obstacles
global obs; %positions of obstacles
global obs_rad; %radius of obstacles
global num_path; %number of segments optimized
global x_next; %used in multi_start function
global uav_ws; %UAV wing span
global initial; % to calculate d_l_min
initial = 1;
global uav_finite_size;
global summer_c cool_c copper_c parula_c winter_c blue_red blue_magenta_red;


%------------add last segments of path to total-----------%

for j = 2 : num_path
    
    for i = 1 : length(t)
        path_mid(i,:) = (1-t(i))^2*x_next(2*j-2,:) + 2*(1-t(i))*t(i)*x_next(2*j-1,:)+t(i)^2*x_next(2*j,:);
    end
    
    path_start = [path_start; path_mid(1,:)];
    Path_bez = [Path_bez; path_mid];
    
end



figure(l+1);
hold on

if square_axes == 1
    axis square
end

if totl == 1
    
    set(gca,'XTickLabel','')
    set(gca,'YTickLabel','')
    
end

%----------------plot UAV-------------------%

if color_bar == 1
    
    colorbar('southoutside','Ticks',[0,0.20,0.4,0.6,0.8,1],'TickLabels',{'V_{min}, 10 m/s','11 m/s','12 m/s','13 m/s','14 m/s','V_{max},15 m/s'},'fontsize',11);
    
    if summer_c == 1
        colormap summer
    elseif cool_c == 1
        colormap cool
    elseif copper_c == 1
        colormap copper
    elseif parula_c == 1
        colormap parula
    elseif winter_c == 1
        colormap winter
    elseif blue_red == 1
        
        % RGB - blue = slow, red = fast
        mymap = zeros(64,3);
        
        mymap(:,1) = linspace(0,1,64);
        mymap(:,2) = ones(64,1)*0;
        mymap(:,3) = linspace(1,0,64);
        
        colormap(mymap)
        
    elseif blue_magenta_red == 1
        
        % RGB - blue = slow, red = fast
        mymap = zeros(64,3);
        
        mymap(:,1) = linspace(0,2,64);
        mymap(:,2) = ones(64,1)*0;
        mymap(:,3) = linspace(2,0,64);
        
        for i = 1 : 64
            if mymap(i,1) >= 1.0
                mymap(i,1) = 1.0;
            end
            if mymap(i,3) >= 1.0
                mymap(i,3) = 1.0;
            end
        end
        
        colormap(mymap)
        
        
    end
end

if speed_color == 1
    
    num_segments = length(Path_bez)/length(t);
    num_bits = length(Path_bez)-1;
    
    segment_length = zeros(num_segments,1);
    bit_length = zeros(num_bits,1);
    
    segment = zeros(length(t),2,num_segments);
    bit = zeros(2,2,num_bits);
    
    %break up path into segments
    for i = 1 : num_segments
        
        segment(:,:,i) = Path_bez((i-1)*length(t)+1:length(t)*i,:);
        
    end
    
    %populate bit
    for i = 1 : num_bits
        
        bit(:,:,i) = Path_bez(i:i+1,:);
        
    end
    
    
    %calculate lengths of each segment
    for i = 1 : num_segments
        
        for j = 2 : length(t)
            segment_length(i) = segment_length(i) + norm ( segment(j,:,i) - segment(j-1,:,i));
        end
        
        %check
        if segment_length(i) < step_min
            segment_length(i) = step_min;
        end
        if segment_length(i) > step_max
            segment_length(i) = step_max;
        end
        
        
    end
    
    %calculate lengths (velocity, since /delta_t) of each bit
    for i = 1 : num_bits
        bit_length(i) = norm( bit(2,:,i) - bit(1,:,i))/delta_t;
        
        %check
        if bit_length(i) < step_min
            bit_length(i) = step_min;
        end
        if bit_length(i) > step_max
            bit_length(i) = step_max;
        end
    end
    
    
    
    %compare lengths to speed
    
    for i = 1 : num_bits
        
        color_var_b(i) = (bit_length(i)-step_min)/(step_max-step_min);
        
    end
    
    r_color_var_b = zeros(num_bits,1);
    g_color_var_b = zeros(num_bits,1);
    b_color_var_b = zeros(num_bits,1);
    
    %based on speed, change color
    for i = 1 : num_segments
        
        color_var(i) = (segment_length(i)-step_min)/(step_max-step_min);
        
    end
    
    
    
    c_r = color_r(color_var);
    c_g = color_g(color_var);
    c_b = color_b(color_var);
    
    
    %plot
    
    if d_speed_color == 1
        
        for i = 1 : num_bits
            
            plot(bit(1:2,1,i),bit(1:2,2,i),'Color',[cb*(color_var_b(i)),cb*(1-color_var_b(i)),0]);
            
        end
        
    else
        
        for i = 1 : num_segments
            
            plot(segment(:,1,i),segment(:,2,i),'Color',[cb*c_r(i), cb*c_g(i), cb*c_b(i)]);
            
        end
        
    end
    
    
    
else
    
    plot(Path_bez(:,1),Path_bez(:,2),'Color',[0, cb, 0]); %plots path of UAV
    
end

%plot segment of path from inside landing zone to final destination
%straight line
% plot([Path_bez(length(Path_bez),1) xf(1)],[Path_bez(length(Path_bez),2) xf(2)], 'Color',...
%     [cb*c_r(length(c_r)), cb*c_g(length(c_g)), cb*c_b(length(c_b))] );
% Quadratic Bezier curve
% -------------------------------------------------------------------- %
p0 = Path_bez(length(Path_bez),:);
p2 = xf;

m = (p0(2) - Path_bez(length(Path_bez)-1,2))/(p0(1) - Path_bez(length(Path_bez)-1,1));

fd = norm(p2 - p0);

p1(1) = 0.5*fd + p0(1);
p1(2) = 0.5*fd*m + p0(2);

finalsegment = zeros(length(t),2);
for i = 1 : length(t)
    finalsegment(i,:) = (1-t(i))^2*p0 +2*t(i)*(1-t(i))*p1+t(i)^2*p2;
end

for i = 1 : num_segments
    plot(finalsegment(:,1),finalsegment(:,2),'Color',[cb*c_r(length(c_r)), cb*c_g(length(c_r)), cb*c_b(length(c_r))]);
end
% -------------------------------------------------------------------- %


if uav_finite_size == 0
    for i = 1 : length(path_start)
        
        if speed_color == 1
            
            plot(path_start(i,1),path_start(i,2),'o','Color',[cb*(color_var_b(i)),cb*(1-color_var_b(i)),0]);
            
        else
            
            plot(path_start(i,1),path_start(i,2),'og');
            
        end
        
    end
end

if uav_finite_size == 1
    for i = 1 : length(path_start)
        
        if speed_color == 1
            
            cs = 2*uav_ws/cx;
            x = path_start(i,1) - uav_ws : cs : path_start(i,1)+ uav_ws;
            y =  (uav_ws^2 - (x - path_start(i,1)).^2).^0.5 + path_start(i,2); %top part of circle
            y1 = -(uav_ws^2 - (x - path_start(i,1)).^2).^0.5 + path_start(i,2); %bottom part of circle
            
            plot(x,y,'Color',[cb*c_r(i), cb*c_g(i), cb*c_b(i)]);
            plot(x,y1,'Color',[cb*c_r(i), cb*c_g(i), cb*c_b(i)]);
            
        else
            cs = 2*uav_ws/cx;
            x = path_start(i,1) - uav_ws : cs : path_start(i,1)+ uav_ws;
            y =  (uav_ws^2 - (x - path_start(i,1)).^2).^0.5 + path_start(i,2); %top part of circle
            y1 = -(uav_ws^2 - (x - path_start(i,1)).^2).^0.5 + path_start(i,2); %bottom part of circle
            
            plot(x,y,'Color',[0, cb, 0]);
            plot(x,y1,'Color',[0, cb, 0]);
        end
    end
end

path_mid(length(t),:)
cs = 2*uav_ws/cx;
x = path_mid(length(t),1) - uav_ws : cs : path_mid(length(t),1) + uav_ws;
y =  (uav_ws^2 - (x - path_mid(length(t),1)).^2).^0.5 + path_mid(length(t),2); %top part of circle
y1 = -(uav_ws^2 - (x - path_mid(length(t),1)).^2).^0.5 + path_mid(length(t),2); %bottom part of circle

plot(x,y,'Color',[cb*c_r(length(path_start)), cb*c_g(length(path_start)), cb*c_b(length(path_start))]);
plot(x,y1,'Color',[cb*c_r(length(path_start)), cb*c_g(length(path_start)), cb*c_b(length(path_start))]);

%-----------------------------------------%


%plot landing area
cs = 2*lr/cx;
x = xf(1) - lr : cs : xf(1)+ lr;
y =  (lr^2 - (x - xf(1)).^2).^0.5 + xf(2); %top part of circle
y1 = -(lr^2 - (x - xf(1)).^2).^0.5 + xf(2); %bottom part of circle

plot(x,y,'g--');
plot(x,y1,'g--');

for i = 1 : n_obs %-------- static obstacles ----------%
    
    
    plot(obs(i,1),obs(i,2),'xk'); % staic obstacles' centers
    cs = 2*obs_rad(i)/cx;
    x = obs(i,1) - obs_rad(i) : cs : obs(i,1)+ obs_rad(i);
    y =  (obs_rad(i)^2 - (x - obs(i,1)).^2).^0.5 + obs(i,2); %top part of circle
    y1 = -(obs_rad(i)^2 - (x - obs(i,1)).^2).^0.5 + obs(i,2); %bottom part of circle
    
    plot(x,y,'k');
    plot(x,y1,'k');
    
    
end  %--------------------------------------%

%xlim([x_sp(1) (xf(1)+10)]);
%ylim([x_sp(2) (10+xf(2))]);
xlim([x_sp(1) (xf(1))]);
ylim([x_sp(2) (xf(2))]);
hold off