function [] = PrimateFaces_Viewer

% get screen size
screen_size=get(0,'ScreenSize');

% set up gui
guiobj=gobjects(1,10);
guiobj(1) = figure('Name','Primate Faces Viewer','Menubar','none','Position',[50,50,screen_size(3)-100,screen_size(4)-200],'Units','Pixels','NumberTitle','off','Resize','off'); % create setup window
movegui(guiobj(1,1),'center') % move to centre of window
fig_size=guiobj(1).Position;
button_width=[0.05,0.15,0.1,0.15,0.1,0.15,0.1,0.15,0.05]*fig_size(3);
button_startx=cumsum(button_width);
button_height=[0.1,0.04]*fig_size(4);
button_starty=[0.85,0.9]*fig_size(4);

% get list of detection models
model_dir=uigetdir('Select folder containing detection models');
model_list=cell(10,1);
files=dir(model_dir);
files={files(3:end).name};
no=0;
for n=1:length(files)
    [~,~,ext] = fileparts(files{n});
    if strcmp(ext,'.xml')
        no=no+1;
        model_list{no}=files{n};
    end
end
model_list=model_list(1:no);
meta_list={'File Name:';'';'Width:';'';'Height:';''};

% continue gui setup
guiobj(2) = uicontrol('Parent', guiobj(1),'Position',[button_startx(1),button_starty(1),button_width(2),button_height(1)],'Style','pushbutton','String','Load Image','FontSize',16,'Callback',@loadimage);
guiobj(3) = uicontrol('Parent', guiobj(1),'Position',[button_startx(3),button_starty(1),button_width(4),button_height(2)],'Style','popupmenu','String',model_list,'FontSize',14,'Callback',@detector_menu);
uicontrol('Parent', guiobj(1),'Position',[button_startx(3),button_starty(2),button_width(4),button_height(2)],'Style','text','String','Detector Model','FontSize',14);
guiobj(4) = uicontrol('Parent', guiobj(1),'Position',[button_startx(5),button_starty(1),button_width(6),button_height(2)],'Style','edit','String','100','FontSize',16,'Callback',@minsize);
uicontrol('Parent', guiobj(1),'Position',[button_startx(5),button_starty(2),button_width(6),button_height(2)],'Style','text','String','Minimum Size','FontSize',14);
guiobj(5) = uicontrol('Parent', guiobj(1),'Position',[button_startx(7),button_starty(1),button_width(8),button_height(1)],'Style','pushbutton','String','Save Image','FontSize',16,'Callback',@saveimage);
guiobj(6) = axes('Parent',guiobj(1),'Units','Pixels','Position',[0.05*fig_size(3),0.20*fig_size(4),0.75*fig_size(3),0.6*fig_size(4)],'XTick',[],'YTick',[],'Box','on');
guiobj(7) = uicontrol('Parent', guiobj(1),'Position',[0.05*fig_size(3),0.08*fig_size(4),0.6*fig_size(3),0.05*fig_size(4)],'Value',5/25,'Style','slider','SliderStep',[1/25,2/25],'Min',1/25,'Callback',@thresholdchange);
uicontrol('Parent', guiobj(1),'Position',[0.05*fig_size(3),0.02*fig_size(4),0.6*fig_size(3),0.05*fig_size(4)],'Style','text','String','Threshold','FontSize',20);
guiobj(8) = uicontrol('Parent', guiobj(1),'Position',[0.7*fig_size(3),0.02*fig_size(4),0.1*fig_size(3),0.1*fig_size(4)],'String','5','Style','text','FontSize',32);
guiobj(9) = uicontrol('Parent',guiobj(1),'Position',[0.81*fig_size(3),0.6*fig_size(4),0.1*fig_size(3),0.2*fig_size(4)],'Style','text','FontSize',12,'HorizontalAlignment','left','String',meta_list);

% initialise variables
merge_threshold=5;
min_size=[100,100];
image=[];
img_dim=size(image);
imageout=[];
detection_model='PrimateFaceModel.xml';
i=find(strcmp(model_list,detection_model));
guiobj(3).Value=i;
detector=vision.CascadeObjectDetector(fullfile(model_dir,detection_model),'MergeThreshold',merge_threshold,'MinSize',min_size);

% change threshold
    function thresholdchange(hObject, ~, ~)
        merge_threshold=round(25*hObject.Value);
        detector.MergeThreshold=merge_threshold;
        guiobj(8).String=num2str(merge_threshold);
        if ~isempty(image)
            detectface;
        end
    end

% load image
    function loadimage(~, ~, ~)
        [FileName,PathName] = uigetfile({'*.jpg';'*.png'},'Select an image');
        
        try
            image=imread(strcat(PathName,FileName));
        catch
            errordlg('Invalid Image');
        end
        
        if ~isempty(image)
            img_dim=size(image);
            meta_list{1}=['File Name: ',FileName];
            meta_list{3}=['Width: ',num2str(img_dim(2)),' Pixels'];
            meta_list{5}=['Height: ',num2str(img_dim(1)),' Pixels'];
            guiobj(9).String=meta_list;
            detectface;
        end
    end

% save image
    function saveimage(~,~,~)
        [FileName,PathName] = uiputfile({'*.jpg';'*.png'},'Save image as');
        try
            imwrite(imageout,strcat(PathName,FileName))
        catch
            errordlg('Cannot Save Image');
        end
    end

% set minimum size
    function minsize(hObject,~,~)
        min_size=str2double(hObject.String);
        if min_size<32
            min_size=32;
            guiobj(4).String=num2str(min_size);
        end
        detector.MinSize=[min_size,min_size];
        if ~isempty(image)
            detectface;
        end
    end

% change detection model
    function detector_menu(hObject,~,~)
        detection_model=model_list{hObject.Value};
        detector=vision.CascadeObjectDetector(fullfile(model_dir,detection_model),'MergeThreshold',merge_threshold);
        if ~isempty(image)
            detectface;
        end
    end

% run face detection
    function detectface
        I=imadjust(rgb2gray(image));
        bbox=step(detector,I);
        lwidth=ceil(max(img_dim)/300);
        imageout=insertShape(image,'Rectangle',bbox,'Color','Green','LineWidth',lwidth);
        imshow(imageout,'Parent',guiobj(6))
    end
end

