% primatefaces_main GUI for training and running face detection and face recognition for
% rhesus macaques (can be adapted to other species).

function [] = primatefaces_main

guiobj=gobjects(3,10);

%% start up window
guiobj(1,1) = figure('Name','Primate Faces','Menubar','none','Position',[0,0,800,400],'Units','Pixels','NumberTitle','off','Resize','off'); % create setup window
movegui(guiobj(1,1),'center') % move to centre of window

%% Display backdrop
I=imread('Faces.jpg');
guiobj(1,2)=axes('Parent',guiobj(1,1),'Units','Pixels','Position',[0,100,800,300]);
imshow(I,'Parent',guiobj(1,2));

%% Add buttons for detection and identification
guiobj(1,3)=uicontrol('Parent',guiobj(1,1),'Style','pushbutton','Position',[100,25,200,50],'String','Detection','FontSize',16,'Callback',@detect,'BackgroundColor',[0.7,0.7,0.7]);
guiobj(1,4)=uicontrol('Parent',guiobj(1,1),'Style','pushbutton','Position',[500,25,200,50],'String','Recognition','FontSize',16,'Callback',@recog,'BackgroundColor',[0.7,0.7,0.7]);


%% When detection button pressed - run detection setup program
    function detect(~,~,~)
        guiobj(1,1).Visible='off';
        choice = questdlg('What do you want to do?','Detection','Train new detector','Run detection on images or videos','Train new detector');
        if ~isempty(choice)
            switch choice
                case 'Train new detector'
                    primatefaces_traindet
                case 'Run detection on images or videos'
                    primatefaces_setup(1)
            end
        end
        guiobj(1,1).Visible='on';
    end

%% When recognition button pressed - run detection setup program
    function recog(~,~,~)
        guiobj(1,1).Visible='off';
        choice = questdlg('What do you want to do?','Identification','Train new face recognition model','Run recognition on images or videos','Train new face recognition model');
        if ~isempty(choice)
            switch choice
                case 'Train new face recognition model'
                    primatefaces_trainrec
                case 'Run recognition on images or videos'
                    primatefaces_setup(2)
            end
        end
        guiobj(1,1).Visible='on';
    end

end