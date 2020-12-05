% PROGRAM TO CALCULATE SHORTEST PATHS BETWEEN ALL PAIRS OF DISTRICTS (IN
% EACH YEAR)

clc
clear all;

%add the path of the input files
addpath '../trade costs/';
addpath '../../Data/maps/';
addpath '../../Data/Prices_salt/';

%add the path of the Boost Graph Library
%addpath 'matlab_bgl-4.0.1/matlab_bgl/'
%for 64 bit Mac OS
addpath(genpath('../trade costs/matlab_bgl_4.0_osx64'))
addpath(genpath('matlab_bgl'))

disp('Shortest Path Calculation');

%%%%%%%%%%%%%%%%%%%% SET PARAMETERS: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	%using 105 km as 1 lat-long distance unit
	sparsecutoff = 1*105;  
	dist_sparsecutoff = 2*105; 
	gapcutoff = 0.015*105; 
	coastcutoff = 1*105;
	low = 0.0000000000001;  % This is just a very low number which I use as the distance between two points that are on top of each other (because the distance of zero is reserved for 'can't go there').


%%%%%%%%%%%%%%%%%%%% INPUT THE .SHP FILES AFTER CONVERTING THEM USING EXCEL %%%%%%%%%%%%%%%%%%%%%%

% input the railway network shapefile:
	L_RR1 = double(csvread('railways_Dissolve_Simplify2_point2.csv',1,0));
    
	[N_RR M ] = size(L_RR1);
	clear M
	L_RR2 = ones(N_RR,6);
	for i = 1:N_RR
		L_RR2(i,1) = i-1;
	end
	L_RR2(:,2) = L_RR1(:,6); % y coord
	L_RR2(:,3) = L_RR1(:,5); % x coord
	L_RR2(:,4) = 3*ones(N_RR,1); % railway points are coded as type = 3
	L_RR2(:,5) = L_RR1(:,3);  % line segment ID
	L_RR2(:,6) = L_RR1(:,2);  % year of opening (NB: Pakistan/Bangladesh RR segments opened somewhere inside 1931 and 1956 are coded as '3156' since don't know exact years)

		% NB: L_RR1(:,4) is irrelevant;
		% NB: L_RR1(:,1) is gauge; not used

	clear L_RR1

    %order of columns in L matrix to follow:
        %L1: point id (my coding, not GIS's...but it's in the order it came out of GIS in)
        %L2: y
        %L3: x
        %L4: feature type (Dist =1, Salt = 2, RR=3, River=4, Coast=5)
        %L5: feature id
        %L6: year open


% input the district centroids shapefile:

	L_Dist1 = csvread('bd_ns_boundary2.csv',1,0);
    
	[N_Dist M ] = size(L_Dist1);
	clear M
	L_Dist2 = ones(N_Dist,6);
	L_Dist2(:,1) = L_Dist1(:,9); %distid
	L_Dist2(:,2) = L_Dist1(:,11);  %y
	L_Dist2(:,3) = L_Dist1(:,10); %x
	L_Dist2(:,4) = 1;  % districts are coded as 1.
	L_Dist2(:,5) = NaN; % set to NaN to avoid any mistakes below
	L_Dist2(:,6) = 0; % no year open

	clear L_Dist1

% input the river points shapefile:
	L_River1 = csvread('rivers_simplepoint2.csv',1,0);
 
	[N_River M ] = size(L_River1);
	clear M
	L_River2 = ones(N_River,6);
	for i = 1:N_River
		L_River2(i,1) = i;
	end
	L_River2(:,2) = L_River1(:,14); % y
	L_River2(:,3) = L_River1(:,13); % x
	L_River2(:,4) = 4*ones(N_River,1); % river points are coded as type = 4
	L_River2(:,5) = L_River1(:,12);  % line segment ID
	L_River2(:,6) = 0;  % no year of opening

		% NB: L_River1(:,1-11 ) is irrelevant

	clear L_River1	

% input the coastal points shapefile:
	L_Coast1 = csvread('coast_simplepoint2.csv',1,0);
 
	[N_Coast M ] = size(L_Coast1);
	clear M
	L_Coast2 = ones(N_Coast,6);
	for i = 1:N_Coast
		L_Coast2(i,1) = i;
	end
	L_Coast2(:,2) = L_Coast1(:,14); % y
	L_Coast2(:,3) = L_Coast1(:,13); % x
	L_Coast2(:,4) = 5*ones(N_Coast,1); % coast points are coded as type = 5
	L_Coast2(:,5) = L_Coast1(:,11);  % line segment ID
	L_Coast2(:,6) = 0;  % no year of opening

		% NB: L_Coast1(:,1-10, 12) is irrelevant

	clear L_Coast1	

% input the salt source locations:
	L_Salt  = zeros(9,6);

	L_Salt(1,1) = 9081006;  % Kokan (= Bombay port); near Thana district.
	L_Salt(1,2) = 18 + 55/60 + 56/3600;
	L_Salt(1,3) = 72 + 50/60 + 11/3600;
	L_Salt(2,1) =  9061104; %Calcutta (= mouth of Hugli river at Bengal Sea); near Calcutta district
	L_Salt(2,2) =  22 + 10/60 + 24/3600;
	L_Salt(2,3) =  88 + 3/60 + 13/3600;
	L_Salt(3,1) =  9152011;  % Mandi; near Mandi state
	L_Salt(3,2) =  31.43;
	L_Salt(3,3) =  76.58;
	L_Salt(4,1) =  9000000;   %Didwana.  not near any state
	L_Salt(4,2) =  27.40;
	L_Salt(4,3) =  74.567;
	L_Salt(5,1) =  9162012;  %Sambhar (town); relatively near Krishangarh state
	L_Salt(5,2) =  26+ 54/60 + 0/3600;
	L_Salt(5,3) =  75 + 13/60 + 0/3600;	
	L_Salt(6,1) =  9162004;  %Bharatpur (town); near Bharatpur state
	L_Salt(6,2) =  27 + 15/60 + 0/3600;
	L_Salt(6,3) =  77 + 30/60 + 0/3600;	
	L_Salt(7,1) =  9151006;  % Sultanpur (town); near Gurgaon
	L_Salt(7,2) =  28 + 27/60 + 28/3600;
	L_Salt(7,3) =  76 + 54/60 + 37/3600;	
	L_Salt(8,1) =  9151021;  % cis-Indus (Khewra is new name for old Mayo Mine, which Watt says was main source); near Shahpur district.
	L_Salt(8,2) =  32.65;
	L_Salt(8,3) =  73.02 ;	
	L_Salt(9,1) =  9151027; % Kohati (Jutta/Jatta was biggest mine according to Watt); near Kohat district.
	L_Salt(9,2) =  33.767;  
	L_Salt(9,3) =  70.892;

	L_Salt(:,4) = 2*ones(9,1); %Salt source points are coded as type = 2.
	L_Salt(:,5) = NaN;  % no line segment type.
	L_Salt(:,6) = 0;  % no year of opening.

	[N_Salt M] = size(L_Salt);

    

%%%%%%%%%%%%%%%%%%%% CREATE THE FULL LOCATION MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% append the different location matrices together:
	L = [L_Dist2; L_Salt; L_RR2; L_River2; L_Coast2];  % This order is important for some of the code below.
	[N_L M] = size(L);
	clear M

    clear L_RR2 L_Dist2 L_Coast2 L_River2 L_Salt L_od 
    
    disp('Creating distance matrix...');


%%%%%%%%%%%%%%%%%%%% EXTRACT INDICES WHERE YEARS CHANGE, FOR USE BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% generate vector 'yrlist', whose first value is the last point in L with a year of opening value < 1850, and so on to 1930.
	% eg the 10th element of 'yrlist' is the number of the element in L (when L is sorted by feature type and then year) that contains the last RR point with year of opening = 1859 
	startyr = 1850;
	endyr = 1930;
	L = sortrows(L,[4 6]);
	yrlist = zeros(endyr-startyr+1,1);
	for yr = startyr:endyr
		yrlist(yr-startyr+1) = max([N_Dist+N_Salt; find(L(:,6)<=yr & L(:,4)==3)]);
	end
	clear yr
    
    
    

%%%%%%%%%%%%%%%%%%%% PREPARE THE COST MATRIX FROM THE LOCATION MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% enter relative cost parameters (estimated in Step 1, price regressions) for each mode of travel (road, coast, river,
% rail) here:

     railcost=1;
     roadcost=2.375;
     rivercost=2.25;
     coastcost=6.1875;
    
C_base = zeros(N_L);


	% First calculate the distance between all bilateral pairs of locations (of all 5 types)
	for i = 1:N_L
		for j = i:N_L
            C_base(i,j) = haversine(L(i,2),L(i,3),L(j,2),L(j,3));
		end
	end


% start to make Cost matrix (C) from Location matrix (L)...
% basic strategy is to first make a C matrix that has the Euclidean
% distance between any i,j pair of locations (adjusted to be sparse in a
% way described below) and then, later, assign the relevant relative cost
% parameters to each mode of transport (from i to j)

% NB will follow convention that:
    % T=1 means rail, T=2 means river, T=3 means coast, T=4 means road.
    
    C = C_base;
    
	% DISTRICT-DISTRICT (AND SALT-SALT, SALT-DIST) BLOCKS OF MATRIX:
		% keep these as Euclidean distance; allows 'road' network to connect all districts to each other pre railway network built (though later this will get restricted by need for C to be sparse)
    for i = 1:N_Dist+N_Salt
		for j = i:N_Dist+N_Salt
            %then assign roadcost type:
            C(i,j) = C(i,j)*roadcost;  
        end;
    end

	% DISTRICT (and SALT)-OTHER LOCATIONS BLOCKS OF MATRIX :
		%Want to apply roadcost here, but make it sparse (ie only allow jumps from RR or River points to Coast points if they lie within sparsecutoff of each other):
		%Allow (further below) a higher sparse cutoff for district-other journeys
	for i = 1:N_Dist+N_Salt
		for j = N_Dist+N_Salt+1:N_L
			if C(i,j) ==0 && i~=j 
				C(i,j) = 99999;  
			end
			if C(i,j) >dist_sparsecutoff && C(i,j) ~=99999
				C(i,j) = 0; %recall, C=0 below will be interpreted as C=Inf
			end
            %then assign roadcost type:
            if C(i,j) ~= 99999 && C(i,j)~=0;
            C(i,j) = C(i,j)*roadcost;
            end;
            
			%then reverse the 99999 protection:
			if C(i,j) == 99999;
				C(i,j) = low;
            end
		end
	end
		


	% RR-RR BLOCKS:
	for i = N_Dist + N_Salt + 1:N_Dist + N_Salt + N_RR
		for j = i:N_Dist +N_Salt+ N_RR
		
	
		% Correct for fact that occasionally there are small gaps between the 
        % start point of one line segment and the end point of a different segment; 
        % don't want these to interrupt the flow.  So protect C_ij if gap is small and of same type.
			if C(i,j) < gapcutoff && L(i,4) == L(j,4) && L(i,5) ~= L(j,5);
				C(i,j) = 99999;
			end
	

		% Force a sparse structure on C by setting all high (rail-rail) distances (between non-adjacent neighbours) to zero.  
        % This is necessary below (algorithm requires sparsity).
		% but first 'protect' any truly zero distance points for use later:
			if C(i,j) ==0 && i~=j ;
				C(i,j) = 99999;  
			end
		
			% then put any rail-rail distances that are large (over sparsecutoff) and are not protected
            % and are either not from the same feature "L(i,5) ~= L(j,5)"
            % OR are from the same feature but not adjacent
            % "abs(i-j)~=1"
            % to zero (recall, C=0 below will be interpreted as C=Inf).
            if C(i,j) >sparsecutoff && C(i,j) ~=99999 && (L(i,5) ~= L(j,5) || abs(i-j)~=1);
				C(i,j) = 0;
            end
              
            % for adjacent features (serial number differs by one) on the 
            % same line segment (ie feature ID) (whether rail or river), 
            % assign relevant rail type, if it is not protected:
  			if L(i,5) ==L(j,5) && abs(i-j)==1 && C(i,j) ~= 99999 && C(i,j)~=0;
              C(i,j) = C(i,j)*railcost;
            % else, set roadcost to every rail feature, which is not
            % protected
            elseif C(i,j) ~= 99999 && C(i,j)~=0;
              C(i,j) = C(i,j)*roadcost;
            end
            
            
            if abs(i-j)~=1 && C(i,j) ~= 99999 && C(i,j)~=0;
              
            end
            
            
           	%then reverse the 99999 protection:
			if C(i,j) == 99999;
				C(i,j) = low;
            end
		end
    end

%RIVER-RIVER BLOCKS:
	for i = N_Dist +N_Salt +N_RR +1:N_Dist +N_Salt+ N_RR + N_River
		for j = i:N_Dist +N_Salt+ N_RR + N_River
		
	
		% Correct for fact that occasionally there are small gaps between the 
        % start point of one line segment and the end point of a different segment; 
        % don't want these to interrupt the flow.  So protect C_ij if gap is small and of same type.
			if C(i,j) < gapcutoff && L(i,4) == L(j,4) && L(i,5) ~= L(j,5);
				C(i,j) = 99999;
			end
	

		% Force a sparse structure on C by setting all high (river-river) distances (between non-adjacent neighbours) to zero.  
        % This is necessary below (algorithm requires sparsity).
		% but first 'protect' any truly zero distance points for use later:
			if C(i,j) ==0 && i~=j ;
				C(i,j) = 99999;  
			end
		
			% then put any river-river distances that are large (over sparsecutoff) and are not protected
            % and are either not from the same feature "L(i,5) ~= L(j,5)"
            % OR are from the same feature but not adjacent
            % "abs(i-j)~=1"
            % to zero (recall, C=0 below will be interpreted as C=Inf).
            if C(i,j) >sparsecutoff && C(i,j) ~=99999 && (L(i,5) ~= L(j,5) || abs(i-j)~=1);
				C(i,j) = 0;
            end
            
            % for adjacent features (serial number differs by one) on the 
            % same line segment (ie feature ID) (whether rail or river), 
            % assign relevant rail type, if it is not protected:
  			if L(i,5) ==L(j,5) && abs(i-j)==1 && C(i,j) ~= 99999 && C(i,j)~=0;
              C(i,j) = C(i,j)*rivercost;
            % else, set roadcost to every river feature, which is not
            % protected
            elseif C(i,j) ~= 99999 && C(i,j)~=0;
              C(i,j) = C(i,j)*roadcost;
            end
            
           	%then reverse the 99999 protection:
			if C(i,j) == 99999;
				C(i,j) = low;
            end
		end
    end

    
	% COAST-COAST BLOCK OF MATRIX:
		% Can only travel to any coastal point within distance 'coastcutoff').  
	for i = N_L-N_Coast+1:N_L
	        for j = i:N_L

			% 'protect' any truly zero distance points for use later:
			if C(i,j) ==0 && i~=j ;
			    C(i,j) = 99999;  
			end
		    % then assign sparsity:
			if C(i,j) > coastcutoff && C(i,j)~=99999;
			    C(i,j) = 0;
			end
            % assign the coast-coast transport cost:
            if C(i,j) ~= 99999 && C(i,j)~=0;
			C(i,j) = C(i,j)*coastcost;
            end;
            %then reverse the 99999 protection:
			if C(i,j) == 99999;
			    C(i,j) = low;
            end;
		end
	
    end

	

	% COAST-RR/RIVER - RR/RIVER-COAST BLOCKS:
		%Want to apply roadcost here, but make it sparse (ie only allow jumps from RR or River points to Coast points if they lie within sparsecutoff of each other):
	for i = N_Dist+N_Salt+1:N_Dist + N_Salt+ N_RR + N_River
		for j = N_Dist + N_Salt+ N_RR + N_River+1:N_L
			if C(i,j) ==0 && i~=j ;
				C(i,j) = 99999;  
			end
			if C(i,j) >sparsecutoff && C(i,j) ~=99999;
				C(i,j) = 0;
			end
            %then assign roadcost type:
            if C(i,j) ~= 99999 && C(i,j)~=0;
            C(i,j) = C(i,j)*roadcost;
            end;
			%then reverse the 99999 protection:
			if C(i,j) == 99999;
				C(i,j) = low;
            end
        end
    end

    % ASSIGN ROAD-COST TO REMAINING RAIL/RIVER-RIVER/RAIL CONNECTIONS
    for i = N_Dist+N_Salt+1:N_Dist +N_Salt+ N_RR
		for j = N_Dist +N_Salt+ N_RR+1: N_Dist +N_Salt+ N_RR+ N_River
           if C(i,j) == 0 ;
				C(i,j) = 99999;  
			end
			if C(i,j) > sparsecutoff && C(i,j) ~= 99999;
				C(i,j) = 0;
			end
            %then assign roadcost type:
            if C(i,j) ~= 99999 && C(i,j)~=0;
            C(i,j) = C(i,j)*roadcost;
            end;
			%then reverse the 99999 protection:
			if C(i,j) == 99999;
				C(i,j) = low;
            end
        end
    end
    
   
    
	% THEN SYMMETRISE THE ENTIRE C and T MATRIX:
	for j = 1:N_L 
		for i = j:N_L
			C(i,j) = C(j,i);
		end
    end 
    
	% Now they are sparse, and so you an declare them as such:
    
		C = sparse(C);
        
    disp('Distance matrix created!');

    
    
    %Create temp file for output:
        filename = ['LCRED_D2D_alphahat.csv'];
        fid = fopen(filename, 'w');

        %create Header
        Header = 'origin_id,destination_id,year,alpha_road,alpha_coast,alpha_river,LCRED \n';
        fprintf(fid, Header);
        fclose(fid);

        
        
        
%calculate LCRED for every pair of districts and in all years:
        
    for yr = 1930:-1:1850 % run this backwards in time, so it starts with the full C matrix and successively drops segments that haven't been built yet
        yr
        [N_L M] = size(C);
        C([yrlist(yr-startyr+1)+1:N_L-N_Coast-N_River],:) = []; % These 2 lines kill every point (in the RR part of the C matrix) that has year of opening > 'yr', the year of the cycle.
        C(:,[yrlist(yr-startyr+1)+1:N_L-N_Coast-N_River]) = []; 


        Output = zeros([N_Dist*N_Dist, 7]);

        for i = 1:N_Dist

            [LCRED pred] = shortest_paths(C,i);

            for j = 1:N_Dist               
                Output(j+(i-1)*N_Dist,1) = L(i,1); %origin id
                Output(j+(i-1)*N_Dist,2) = L(j,1); %destination id
                Output(j+(i-1)*N_Dist,3) = yr; %year
                Output(j+(i-1)*N_Dist,4) = roadcost; %roadcost
                Output(j+(i-1)*N_Dist,5) = coastcost; %coastcost
                Output(j+(i-1)*N_Dist,6) = rivercost; %rivercost
                Output(j+(i-1)*N_Dist,7) = LCRED(j); %shortest path distance BLG
            end
        end
    

    %append output to csv

    dlmwrite (filename, Output, '-append', 'precision',12);

    end
 
