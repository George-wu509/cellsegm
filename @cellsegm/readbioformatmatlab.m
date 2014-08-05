function [] = readbioformatmatlab(varargin)
% READBIOFORMATMATLAB Reads Bio-Formats like .LIF using the bfopen tool for
%   matlab. Can be downloaded from 
%   http://www.openmicroscopy.org/site/support/bio-formats5/developers/matlab-dev.html
%   The folder with the tools must be placed in the matlab path prior to
%   usage.
%
%   READBIOFORMATMATLAB(INFILE) reads Bio-Formats like .lif specified in the cell array
%   INFILE using the command line tools. If there is only one file the file 
%   name can be given as a string.
%   Data is saved as stack1, stack2, and so on, in a folder with subscript 
%   '-matlab'. Data is saved both as .tif and .mat
%
%
%   READBIOFORMATMATLAB(INFILE,'mat') save the data only as .mat format and the
%   .tif files are deleted after use.
%
%
%   =======================================================================================
%   Copyright (C) 2013  Erlend Hodneland
%   Email: erlend.hodneland@biomed.uib.no 
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%   =======================================================================================
%
liffile = varargin{1};
format = 'all';
if nargin == 2
    format = varargin{2};
end;

if ~ismember(format,{'all','mat'})
    error('Wrong option to READBIOFORMAT');
end;

if ~iscell(liffile)
    liffile = {liffile};
end;

for i = 1 : numel(liffile)

    % reading pixel size and number of series
    [folder file ext] = fileparts(liffile{i});
    namehere = [file ext];
    
    msg = ['Converting ' namehere ' in folder ' folder];
    disp(msg);
    
    % read the data
    try
        data = bfopen(liffile{i});
    catch
        msg = ['Could not open ' liffile{i}];
        disp(msg);
    end;
    nseries = size(data,1);
    
    msg = ['Number of series: ' int2str(nseries)];
    disp(msg);
        
    for j = 1 : nseries
        
        dim = size(data{j,1}{1,1});
%         omeMeta = data{j, 4};
%         dim(1) = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
%         dim(2) = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
%         dim(3) = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
%         h(2) = omeMeta.getPixelsPhysicalSizeX(0).getValue(); % in ??m
%         h(1) = omeMeta.getPixelsPhysicalSizeY(0).getValue(); % in ??m
%         h(3) = omeMeta.getPixelsPhysicalSizeZ(0).getValue(); % in ??m
        
        % the hashtable
        hasht = data{j,2};
   
        h = zeros(1,3);
        a = get(hasht,'HardwareSetting|ScannerSettingRecord|dblVoxelY #1');
        h(1) = str2double(a);
        a = get(hasht,'HardwareSetting|ScannerSettingRecord|dblVoxelX #1');
        h(2) = str2double(a);
        a = get(hasht,'HardwareSetting|ScannerSettingRecord|dblVoxelZ #1');
        h(3) = str2double(a);
        % in microns
        h = h*1e6;
%         nch = str2double(get(hasht,'HardwareSetting|ScannerSettingRecord|nChannels #1'));
        
        if sum(isnan(h)) == 3
            warning(['Could not read hashtable from series ' int2str(j)]);
            continue;
        end;
        
        % stage position
%         get(hasht,'HardwareSetting|FilterSettingRecord|DMI6000 Stage Pos x #1')        
%         pos(1) = str2double(get(hasht,'HardwareSetting|FilterSettingRecord|DMI6000 Stage Pos x #1'));
%         pos(2) = str2double(get(hasht,'HardwareSetting|FilterSettingRecord|DMI6000 Stage Pos y #1'));
%         pos(3) = str2double(get(hasht,'HardwareSetting|FilterSettingRecord|DMI6000 Stage Pos z #1'));
        
        msg = ['Voxel size: ' num2str(h)];
        disp(msg);
        
        
        nimages = size(data{j,1},1);        
        imtif = zeros([dim(1:2),nimages]);
        for k = 1 : nimages            
            imhere = data{j,1}{k,1};
            imtif(:,:,k) = double(imhere);
        end;

        % reorder data into an array
        str = data{j,1}{1,2};
        indplane = strfind(str,'plane');
        str = str(indplane:end);
        str = [str ';'];
        indslash = strfind(str,'/');
        indscolon = strfind(str,';');
        try
            zmax = str2double(str(indslash(2)+1:indscolon(2)-1));
        catch
            zmax = 1;
        end;
        try
            cmax = str2double(str(indslash(3)+1:indscolon(3)-1));
        catch
            cmax = 1;
        end;
        try
            tmax = str2double(str(indslash(4)+1:indscolon(4)-1));
        catch
            tmax = 1;            
        end;

        msg = ['Number of planes: ' int2str(zmax)];
        disp(msg);

        msg = ['Number of time points: ' int2str(tmax)];
        disp(msg);

        msg = ['Number of channels: ' int2str(cmax)];
        disp(msg);        

        % reshape image
        imtif2 = imtif(:);        
        im = reshape(imtif2,dim(1),dim(2),zmax,tmax,cmax);
        clear imtif2;
        im = squeeze(im);
                
        
        % save file
        foldersave = fullfile(folder,[file '-matlab']);
        [a,b,c] = mkdir(foldersave);
        
        % anyway save as mat format
        pathsave = fullfile(foldersave,['stack' int2str(j) '.mat']);
        msg = ['Saving ' pathsave];
        disp(msg);
        save(pathsave,'im','h','-v7.3');
        
        % save as tif also
        if isequal(format,'all')
            pathsave = fullfile(foldersave,['stack' int2str(j) '.tif']);
            msg = ['Saving ' pathsave];
            disp(msg);
            imwritemulttif(pathsave,imtif);
        end;
        clear imtif;
        
    end;
    
    
end;