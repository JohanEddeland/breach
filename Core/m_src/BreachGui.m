function varargout = BreachGui(varargin)
% BREACHGUI M-file for BreachGui.fig
%      BREACHGUI, by itself, creates a new BREACHGUI or raises the existing
%      singleton*.
%
%      H = BREACHGUI returns the handle to a new BREACHGUI or the handle to
%      the existing singleton*.
%
%      BREACHGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BREACHGUI.M with the given input arguments.
%
%      BREACHGUI('Property','Value',...) creates a new BREACHGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BreachGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BreachGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BreachGui

% Last Modified by GUIDE v2.5 26-Feb-2017 22:40:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BreachGui_OpeningFcn, ...
    'gui_OutputFcn',  @BreachGui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before BreachGui is made visible.
function BreachGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BreachGui (see VARARGIN)

handles = info(handles, 'Starting Breach.... (Memory tip: his first name is Millard)');
crd = pwd;
set(hObject, 'Name', ['Breach (' crd  ')']);

%% used to memorize previous entries
handles.last_options =[];
handles.check_prop_options =[];

%% Init system panel
Br = varargin{1};
handles.BrSys = Br;
assignin('base', 'BrSys_GUI', Br);
Sys = Br.Sys;
SysName = Sys.name;
handles.Sys=Sys;

if isfield(handles.BrSys,  'SimInputsOnly')
    set(handles.checkbox_input_only,'Value',handles.BrSys.SimInputsOnly);
end
handles.system_name_file = [ SysName '.mat' ];

if (isfield(Sys,'tspan'))
    if isscalar(Sys.tspan)
        handles.last_tspan = ['[0 ' dbl2str(Sys.tspan) ']'];
    elseif numel(Sys.tspan)==2
        handles.last_tspan = ['[' dbl2str(Sys.tspan(1)) ' ' dbl2str(Sys.tspan(2)) ']'];
    else
        handles.last_tspan = ['0:' dbl2str(Sys.tspan(2)-Sys.tspan(1)) ':' dbl2str(Sys.tspan(end))];
    end
else
    handles.last_tspan = '';
end

str_name = ['System (' handles.system_name_file ')'];
if (numel(str_name)>35)
    str_name= [str_name(1:30) '...' str_name(end-5:end)];
end
set(handles.system_panel,'Title',str_name );

handles = update_system_panel(handles);
handles.figp=[];

%% Init working sets panel
handles.working_sets_file_name = [Sys.Dir filesep SysName, '_param_sets.mat'];
Pthis = Br.P;   
try
    handles.working_sets = load(handles.working_sets_file_name);
catch
    save([Sys.Dir filesep SysName '_param_sets.mat'], 'Pthis');
    handles.working_sets = load(handles.working_sets_file_name);
end

fnames = fieldnames(handles.working_sets);
handles.current_set = fnames{1};
handles.working_sets.Pthis = Pthis;
set(handles.working_sets_listbox, 'Value', 1);
set(handles.autosave_checkbox, 'Value', 1);

nb_pts = size(handles.working_sets.(handles.current_set).pts, 2);
handles.working_sets.(handles.current_set).selected = zeros(1,nb_pts);
handles = update_working_sets_panel(handles);

%% Init properties panel

handles.properties_file_name = [Sys.Dir filesep SysName '_properties.mat'];
try
    handles.properties = load(handles.properties_file_name);
catch
    phi0 = STL_Formula('phi0',[Sys.ParamList{1} '[t]<=.1']) ; %#ok<NASGU>
    save([Sys.Dir filesep SysName '_properties.mat'], 'phi0');
    handles.properties = load(handles.properties_file_name);
end

fnames = fieldnames(handles.properties);
handles.current_prop = fnames{1};
handles.idx_prop= 1;
handles = update_properties_panel(handles);

%% Init modif panel
handles.current_pts = 1;
handles.refine = 1;
handles.plot_proj = [];
handles.refine_all = 0;
handles.halton = 0;
handles.refine_args = 0;

handles.selected_param=1;
handles.selected_varying_param = 1;

% Init param pts plot
handles.current_plot{1} =[];
handles.current_plot{2} =[];
handles.current_plot{3} =[];
handles.current_marked = [];

handles = update_modif_panel(handles);
handles = info(handles, 'Ready.');

% Choose default command line output for BreachGui
handles.output = handles.BrSys;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BreachGui wait for user response (see UIRESUME)
% uiwait(handles.breach);

% --- Outputs from this function are returned to the command line.
function varargout = BreachGui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listbox_default_parameters.
function listbox_default_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_default_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val= get(hObject,'Value');
handles.selected_param = val;

if (val<= handles.Sys.DimX)
    if isfield(handles.Sys, 'type')
        if (strcmp(handles.Sys.type, 'Simulink')||(strcmp(handles.Sys.type, 'Extern')))
            whatisit = 'a signal.';
        else
            whatisit = 'an initial condition.';
        end
    else
        whatisit = 'an initial condition.';
    end
elseif val<= handles.Sys.DimP
    whatisit = 'a system parameter.';
else
    whatisit = 'a property parameter.';
end

handles = update_modif_panel(handles);

set(handles.text_info, 'String', ['Parameter ' ...
    handles.working_sets.(handles.current_set).ParamList{val} ...
    ' is ' whatisit])
guidata(hObject, handles);
% Hints: contents = get(hObject,'String') returns listbox_default_parameters contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_default_parameters


% --- Executes during object creation, after setting all properties.
function listbox_default_parameters_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_default_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit_epsi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_epsi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in button_remove_set.
function button_remove_set_Callback(hObject, eventdata, handles)
try
    ind = handles.selected_varying_param;
    fn = fieldnames(handles.working_sets);
    st = fn{get(handles.working_sets_listbox,'Value')};
    val = get(handles.working_sets_listbox,'Value');
    
    if (val>1)
        val = val-1;
        set(handles.working_sets_listbox,'Value', val);
        handles.current_set = fn{val};
    else
        handles.current_set = fn{val+1};
    end
    
    handles.working_sets = rmfield(handles.working_sets,st);
    handles =update_working_sets_panel(handles);
    handles= update_properties_panel(handles);
    handles =update_modif_panel(handles);
    guidata(hObject,handles);
    
end
% hObject    handle to button_remove_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on selection change in working_sets_listbox.
function working_sets_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to working_sets_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = get(hObject,'String');
fn = fieldnames(handles.working_sets);
set_name = fn{get(hObject,'Value')};
handles.current_set = set_name;
handles.current_pts = 1;
handles.BrSys.SetP(handles.working_sets.(set_name));

handles = update_working_sets_panel(handles);
handles = update_modif_panel(handles);
handles= update_properties_panel(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function working_sets_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to working_sets_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_varying_parameters.
function listbox_varying_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_varying_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val= get(hObject,'Value');
handles.selected_varying_param = val;
handles= update_modif_panel(handles);
handles= update_properties_panel(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function listbox_varying_parameters_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_varying_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in button_add_param.
function button_add_param_Callback(hObject, eventdata, handles)
% hObject    handle to button_add_param (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = add_param(handles);
handles = update_modif_panel(handles);
guidata(hObject, handles);

function handles= add_param(handles)
ind = handles.selected_param;
P = handles.working_sets.(handles.current_set);

if (size(P.pts,2)>1)
    return;
end

if find(P.dim==ind)
    return
end

k = handles.current_pts;
if (P.pts(ind,k))
    epsi= .1*abs(P.pts(ind));
else
    epsi = .1;
end

if isfield(handles.Sys, 'type')
    if strcmp(handles.Sys.type, 'Simulink')
        if (ind<= P.DimX)
            handles = info(handles,'Cannot modify initial condition for a Simulink signal (must use an explicit parameter)');
            return
        end
    end
end

P.dim = [P.dim ind];
P.epsi(end+1,:) = epsi;

handles.selected_varying_param = numel(P.dim);
handles.working_sets.(handles.current_set) = P;


% --- Executes on button press in button_compute_traj.
function button_compute_traj_Callback(hObject, eventdata, handles)
% hObject    handle to button_compute_traj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tspan = inputdlg('Enter tspan (Format: [ti tf] or [t0 t1 t2 ... tn] or ti:dt:tf)','Compute trajectories', 1, {handles.last_tspan});
if isempty(tspan)
    return;
end
handles.last_tspan = tspan{1};
tspan = eval(tspan{1});

handles= info(handles,'Computing trajectories...');
handles.BrSys.SetP(handles.working_sets.(handles.current_set));
handles.BrSys.Sim(tspan);
handles.working_sets.(handles.current_set) = handles.BrSys.P;
handles= info(handles,'Computing trajectories... Done.');

handles = update_working_sets_panel(handles);
guidata(hObject, handles);
h = BreachTrajGui(handles.BrSys, handles);

% --- Executes on button press in button_remove_param.
function button_remove_param_Callback(hObject, eventdata, handles)
% hObject    handle to button_remove_param (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
st =    get(handles.listbox_varying_parameters,'String');
if(numel(st)>1)
    handles=rm_param(handles);
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
end

function handles= rm_param(handles)
P = handles.working_sets.(handles.current_set);
if(size(P.pts,2)>1)
    return;
end
ind = handles.selected_varying_param;
handles.selected_varying_param = max(1,handles.selected_varying_param-1);
set(handles.listbox_varying_parameters, 'Value', handles.selected_varying_param);
P.dim = P.dim([1:ind-1 ind+1:end]);
P.epsi = P.epsi([1:ind-1 ind+1:end],:);
handles.working_sets.(handles.current_set)=P;

% --- Executes during object creation, after setting all properties.
function edit_tspan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_tspan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_default_param_Callback(hObject, eventdata, handles)
% hObject    handle to edit_default_param (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = eval(get(hObject,'String'));
param = get(handles.edit_param_name,'String');
ii = FindParam(handles.working_sets.(handles.current_set), param);

if ~any(handles.working_sets.(handles.current_set).dim==ii)
    
    handles.working_sets.(handles.current_set) = ...
        SetParam(handles.working_sets.(handles.current_set),param, val);
    
    handles.selected_param = FindParam(handles.working_sets.(handles.current_set), param);
    
    set(handles.listbox_default_parameters, 'Value',handles.selected_param);
    
    if isfield(handles.working_sets.(handles.current_set), 'traj')
        if(handles.selected_param <= handles.working_sets.(handles.current_set).DimP)
            %NM: tspan=handles.working_sets.(handles.current_set).traj{1}.time;
            [~,~,~,~,tokens] = regexp(handles.last_tspan,'([0-9eE\+-\.]+):([0-9eE\+-\.]+):([0-9eE\+-\.]+)');
            tspan = str2double(tokens{1}{1}):str2double(tokens{1}{2}):str2double(tokens{1}{3});
            handles = info(handles,'Updating trajectories...');
            handles.working_sets.(handles.current_set) = ComputeTraj(handles.Sys,rmfield(handles.working_sets.(handles.current_set),'traj'), tspan);
            handles = info(handles,'Updating trajectories... Done.');
        end
    end
    
    if isfield(handles.working_sets.(handles.current_set), 'props')
        
        props = handles.working_sets.(handles.current_set).props;
        props_values = handles.working_sets.(handles.current_set).props_values;
        
        P0 = rmfield(handles.working_sets.(handles.current_set),'props');
        P0 = rmfield(P0,'props_names');
        P0 = rmfield(P0,'props_values');
        
        for ii = 1:numel(props)
            phi = props(ii);
            tau = props_values(ii).tau;
            if isfield(P0,'traj')
                handles = info(handles, 'Computing satisfaction of formula...');
                P0 = SEvalProp(handles.Sys, P0, phi, tau);
                handles = info(handles, 'Computing satisfaction of formula... Done.');
            else
                PO = SPurge_props(P0);
                handles = info(handles, 'Parameters changed, recompute trajectories to re-evaluate properties.');
            end
        end
        handles.working_sets.(handles.current_set) = P0;
    end
    
    handles = update_modif_panel(handles);
    handles = update_properties_panel(handles);   
    guidata(hObject,handles);
    
else
    handles = info(handles, 'To change this value, use Modif current sample');
end

% --- Executes during object creation, after setting all properties.
function edit_default_param_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_default_param (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_uncertainty_Callback(hObject, eventdata, handles)
% hObject    handle to edit_uncertainty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = eval(get(hObject,'String'));
try
    handles.working_sets.(handles.current_set).epsi(handles.selected_varying_param,handles.current_pts) = val;
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function edit_uncertainty_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_uncertainty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_refine_Callback(hObject, eventdata, handles)
% hObject    handle to edit_refine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    handles.refine_args = eval(get(hObject,'String'));
catch
    handles.refine_args = 0;
    return
end

nb_pts = size(handles.working_sets.(handles.current_set).pts,2);

if (handles.refine_all)
    if (handles.halton)
        nb_pts = nb_pts*handles.refine_args;
    else
        nb_pts = CountRefine(handles.working_sets.(handles.current_set), ...
            handles.refine_args);
    end
    
else
    
    ipts = find(handles.working_sets.(handles.current_set).selected);
    if isempty(ipts)
        ipts = handles.current_pts;
    end
    
    Ptmp = Sselect(handles.working_sets.(handles.current_set),ipts);
    if (handles.halton)
        nb_pts = handles.refine_args * size(Ptmp.pts, 2);
    else
        nb_pts = CountRefine(Ptmp, handles.refine_args);
    end
    
end

set(handles.button_go_refine,'String',['Go (' num2str(nb_pts) ' new pts)']);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_refine_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_refine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_value_pts_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_pts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = eval(get(hObject,'String'));
ipts = handles.working_sets.(handles.current_set).dim(handles.selected_varying_param);
handles.working_sets.(handles.current_set).pts(ipts,handles.current_pts) = val;
handles = update_modif_panel(handles);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_value_pts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_pts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in button_new_set.
function button_new_set_Callback(hObject, eventdata, handles)
% hObject    handle to button_new_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    names = fieldnames(handles.working_sets);
    new_name =  genvarname('P',names);
    P = CreateParamSet(handles.Sys,min([handles.Sys.DimP handles.Sys.DimX+1]));
    P.selected = 0;
    handles.working_sets = setfield(handles.working_sets, new_name, P);
    handles = update_working_sets_panel(handles);
    guidata(hObject,handles);
catch
    s = lasterror;
    warndlg(['Problem new_set: ' s.message] );
    error(s);
    return
end

% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function test_memory_Callback(hObject, eventdata, handles)
% hObject    handle to test_memory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msgbox('Who was the 13th president of the United States of America ?', ...
    'Memory Test')

% --------------------------------------------------------------------
function menu_load_working_set_Callback(hObject, eventdata, handles)
% hObject    handle to menu_load_working_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[FileName,PathName] = uigetfile('*.mat','Load Parameter Set...');
if(FileName==0)
    return;
end

handles.working_sets_file_name = [PathName, FileName];
try
    handles.working_sets = load(handles.working_sets_file_name);
    handles.current_pts = 1;
    set(handles.working_sets_listbox, 'Value', 1);
    fn = fieldnames(handles.working_sets);
    handles.current_set = fn{1};
    handles = update_working_sets_panel(handles);
    guidata(hObject,handles);
catch err
    warndlg(['Problem loading: ' err.message] );
    rethrow(err);
end


% --------------------------------------------------------------------
function menu_save_as_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save_as (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    [FileName,PathName] = uiputfile('*.mat','Save Parameter Set As...');
    if(FileName==0)
        return;
    end
    
    handles.working_sets_file_name = [PathName, FileName];
    ws = handles.working_sets;
    handles = info(handles, 'Saving parameter set...');
    save(handles.working_sets_file_name, '-struct','ws');
    handles = info(handles, 'Saving parameter set... Done.');
    handles = update_working_sets_panel(handles);
    guidata(hObject,handles);
catch err
    warndlg(['Problem saving: ' err.message] );
    rethrown(err);
end


% --------------------------------------------------------------------
function quit_Callback(hObject, eventdata, handles)
% hObject    handle to quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.breach);

% --- Executes on button press in button_copy_set.
function button_copy_set_Callback(hObject, eventdata, handles)
% hObject    handle to button_copy_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = get(handles.working_sets_listbox, 'Value');
names = fieldnames(handles.working_sets);
set_name = names{val};
new_name = genvarname(set_name,names);
handles.working_sets = setfield(handles.working_sets, new_name, handles.working_sets.(set_name));
handles = update_working_sets_panel(handles);

guidata(hObject,handles);

function edit_rename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_rename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    new_name= get(hObject,'String');
    if (isfield(handles.working_sets,new_name))
        return
    end
    handles.working_sets = setfield(handles.working_sets,new_name, ...
        handles.working_sets.(handles.current_set));
    handles.working_sets = rmfield(handles.working_sets, handles.current_set);
    handles.current_set = new_name;
    handles = update_working_sets_panel(handles);
    handles = update_modif_panel(handles);
    handles= update_properties_panel(handles);
    guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_rename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_rename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_files_Callback(hObject, eventdata, handles)
% hObject    handle to menu_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function slider_current_pts_Callback(hObject, eventdata, handles)
% hObject    handle to slider_current_pts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = get(hObject,'Value');
handles.current_pts = round(val);
handles = update_modif_panel(handles);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function slider_current_pts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_current_pts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in popup_pts3.
function popup_pts3_Callback(hObject, eventdata, handles)
% hObject    handle to popup_pts3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = get(hObject,'String');
strpop = contents{get(hObject,'Value')};
handles.current_plot_pts{3} = {strpop};
handles = plot_pts(handles);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popup_pts3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_pts3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_pts2.
function popup_pts2_Callback(hObject, eventdata, handles)
% hObject    handle to popup_pts2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popup_pts2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_pts2

contents = get(hObject,'String');
strpop = contents{get(hObject,'Value')};
handles.current_plot_pts{2} = {strpop};
handles = plot_pts(handles);

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popup_pts2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_pts2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_pts1.
function popup_pts1_Callback(hObject, eventdata, handles)
% hObject    handle to popup_pts1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = get(hObject,'String');
strpop = contents{get(hObject,'Value')};
handles.current_plot_pts{1} = {strpop};
handles = plot_pts(handles);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popup_pts1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_pts1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox_quasi_random.
function checkbox_quasi_random_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_quasi_random (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.halton =  get(hObject,'Value');
edit_refine_Callback(handles.edit_refine, eventdata, handles)
guidata(hObject, handles);

% --------------------------------------------------------------------
function menu_save_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = info(handles, 'Saving parameter set...\n');
fprintf('Saving parameter set...');
ws = handles.working_sets; %#ok<NASGU>
save(handles.working_sets_file_name, '-struct', 'ws');
handles = info(handles, 'Saving parameter set... Done');
fprintf('Done.\n');
guidata(hObject, handles);

% --- Executes on button press in button_save_in.
function button_save_in_Callback(hObject, eventdata, handles)
% hObject    handle to button_save_in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    FileName = uigetfile('*.mat','Save Parameter Set In...');
    
    if (FileName==0)
        return;
    end
    system(['touch ' FileName]);
    eval([handles.current_set '= handles.working_sets.(handles.current_set);']);
    save(FileName, '-append', handles.current_set);
    guidata(hObject,handles);
end

% FIXME copy this in checkbox_sample_locally? --- Executes on button press in checkbox_refine_all.
function checkbox_refine_all_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_refine_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.refine_all = get(hObject,'Value');
edit_refine_Callback(handles.edit_refine, eventdata, handles)
guidata(hObject, handles)% Hint: get(hObject,'Value') returns toggle state of checkbox_refine_all

% --- Executes on button press in button_make_pts_set.
function button_make_pts_set_Callback(hObject, eventdata, handles)
% hObject    handle to button_make_pts_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

names = fieldnames(handles.working_sets);
new_name = genvarname('P',names);
ipts = find(handles.working_sets.(handles.current_set).selected);
if isempty(ipts)
    return
end

Ptmp = Sselect(handles.working_sets.(handles.current_set),ipts);

handles.working_sets = setfield(handles.working_sets, new_name, Ptmp);
handles = update_working_sets_panel(handles);
guidata(hObject,handles);

% --- Executes on selection change in listbox_prop.
function listbox_prop_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

idx_prop = get(hObject,'Value');
fnames = fieldnames(handles.properties);
handles.current_prop = fnames{idx_prop};
prop = handles.properties.(handles.current_prop);

info_msg = disp(prop,0);
def_par = get_params(prop);
fnames = fieldnames(def_par);

ndf = numel(fnames);
if ndf>0
    info_msg = [info_msg '   |  default params:'];
end
for idf =1:ndf
    info_msg = [info_msg ' ' fnames{idf} '=' num2str(def_par.(fnames{idf}))];
end

set(handles.text_info, 'String', info_msg);
handles = plot_pts(handles);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function listbox_prop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in button_check_property.
function button_check_property_Callback(hObject, eventdata, handles)
prop = handles.properties.(handles.current_prop);
title = 'Check property options';
prompt = {'Enter tspan for trajectory computation (empty = existing traj), ',...
    'Enter tspan for property evaluation (empty = same as above)'};
opt.tspan_traj= [];
opt.tspan_prop_eval = [];

%[opt, handles.check_prop_options] = structdlg(opt,title,prompt, handles.check_prop_options);
%handles.check_prop_options = {handles.check_prop_options{:} '1'};
if isempty(opt)
    return;
end

if ~isempty(opt.tspan_traj)
    Pphi = ComputeTraj(handles.Sys, handles.working_sets.(handles.current_set), ...
        opt.tspan_traj);
else
    Pphi=handles.working_sets.(handles.current_set);
end
handles = info(handles, 'Computing satisfaction of formula...');
handles.working_sets.(handles.current_set) = SEvalProp(handles.Sys,Pphi, prop, opt.tspan_prop_eval);
handles = info(handles, 'Computing satisfaction of formula... Done.');
handles = update_working_sets_panel(handles);
handles = update_modif_panel(handles);
handles = update_properties_panel(handles);
guidata(hObject,handles);


% --- Executes on button press in checkbox_selected.
function checkbox_selected_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = get(hObject,'Value');
handles.working_sets.(handles.current_set).selected(handles.current_pts)=val;
if isempty(find(handles.working_sets.(handles.current_set).selected))
    set(handles.button_plot_selected, 'String', 'Plot trajs')
else
    set(handles.button_plot_selected, 'String', 'Plot select trajs')
end

guidata(hObject, handles);


% --- Executes on button press in button_edit_prop.
function button_edit_prop_Callback(hObject, eventdata, handles)
% hObject    handle to button_edit_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prop = handles.properties.(handles.current_prop);
evalin('base', ['load(''' handles.properties_file_name ''')']);
load(handles.properties_file_name);

prompt={'Edit formula expression:'};
name='Edit property';
numlines=1;
defaultanswer={disp(prop,-1)};
opts.Resize='on';
opts.WindowStyle='normal';
str=inputdlg(prompt,name,numlines,defaultanswer, opts);

if isempty(str)
    return;
end

try
    id = get_id(prop);
    phi_st = str{1};
    PHI = eval(['STL_Formula(''' id ''',''' phi_st ''')']);
    eval([get_id(PHI) '=PHI']);
    
catch
    s = lasterror;
    warndlg(['Invalid formula: ' s.message] );
    error(s);
    return
end

save(handles.properties_file_name, '-append', get_id(PHI));

handles = update_properties_panel(handles);
guidata(hObject, handles);

function handles = update_working_sets_panel(handles)

%% Set title
k = strfind(handles.working_sets_file_name,filesep);
if ~isempty(k)
    str_name = handles.working_sets_file_name(k(end)+1:end);
else
    str_name = handles.working_sets_file_name;
end
str_name = sprintf('Param. Set (%s)', str_name(1:end-4)); % remove the ".mat"
if(numel(str_name)>35)
    str_name = [str_name(1:26) '...' str_name(end-5:end)];
end
set(handles.working_sets_panel,'Title',str_name );

%% Filter out invalid entries     
fn = fieldnames(handles.working_sets);
for ii=1:numel(fn)
    if ~isfield(handles.working_sets.(fn{ii}),'pts')
        handles.working_sets = rmfield(handles.working_sets, fn{ii});
    end
end
fn = fieldnames(handles.working_sets);

%% 
for ii=1:numel(fn)
    pref = '';
    if(handles.working_sets.(fn{ii}).DimP ~= handles.Sys.DimP)
        pref = '!';
    end
    
    if isfield(handles.working_sets.(fn{ii}),'traj_ref')
        if all(handles.working_sets.(fn{ii}).traj_ref~=0)
            pref = [pref,'*']; %#ok<AGROW>
        elseif any(handles.working_sets.(fn{ii}).traj_ref~=0)
            pref = [pref,'+']; %#ok<AGROW>
        end
    elseif isfield(handles.working_sets.(fn{ii}),'traj');
        pref = [pref, '*']; %#ok<AGROW>
    end
    
    fn{ii} = [pref, fn{ii}];
    
end

set(handles.working_sets_listbox,'String', fn);
set(handles.edit_rename,'String',handles.current_set);
handles.BrSys.SetP(handles.working_sets.(handles.current_set)); 

if get(handles.autosave_checkbox, 'Value')
    handles = info(handles, 'Autosaving parameter sets...');
    ws = handles.working_sets; %#ok<NASGU>
    save(handles.working_sets_file_name, '-struct', 'ws');
    handles = info(handles, '');
end

function handles = update_properties_panel(handles)

str_name = ['Properties (' handles.properties_file_name ')'];
if (numel(str_name)>35)
    str_name= [str_name(1:30) '...' str_name(end-5:end)];
end
set(handles.panel_properties,'Title',str_name );

handles.properties = load(handles.properties_file_name);
handles.properties = orderfields(handles.properties);

fnames = fieldnames(handles.properties);
content={};

for i = 1:numel(fnames)
    try
        st = disp(handles.properties.(fnames{i}),-1);
    catch % a common issue is backward incompatibility - trying using RecoverFormula
        warning('Likely a backward compatibility issue, trying to recover formula.');
        handles.properties.(fnames{i})= RecoverFormula(handles.properties.(fnames{i}));
        st = disp(handles.properties.(fnames{i}),-1);
    end
    
    iprop = find_prop(fnames{i},  handles.working_sets.(handles.current_set));
    if (iprop)
        content = {content{:}, ['*' fnames{i} ': ' st]};
    else
        content = {content{:}, [fnames{i} ': ' st]};
    end
end
set(handles.listbox_prop,'String', content);

function handles = update_modif_panel(handles)

%% parameters listbox
nb_pts = size( handles.working_sets.(handles.current_set).pts,2);
if ~isfield(handles.working_sets.(handles.current_set),'selected')
    handles.working_sets.(handles.current_set).selected=zeros(1,nb_pts);
end
handles.BrSys.SetP(handles.working_sets.(handles.current_set));
nb_pts = size(handles.BrSys.P.pts,2);
DimX = handles.BrSys.P.DimX;
DimP = handles.BrSys.P.DimP;
ParamList = handles.BrSys.P.ParamList;
dim = handles.BrSys.P.dim;

if ~isfield(handles.BrSys.P, 'selected')
    val = get(handles.working_sets_listbox, 'Value');
    names = fieldnames(handles.working_sets);
    set_name = names{val};
    handles.working_sets.(set_name)= setfield(handles.working_sets.(set_name), ...
        'selected', zeros(1,nb_pts));
end

handles.current_pts = min(handles.current_pts, nb_pts);
k = handles.current_pts;

%% update content
content = {};

for i=1:DimX
    st = ParamList{i};
    if isfield(handles.Sys, 'type')
        switch handles.Sys.type
            case {'Simulink'}
                st = strcat(st, ':','--');
            case {'Breach', 'Extern'}
                st = strcat(st, '[0]:',' ',dbl2str(handles.BrSys.P.pts(i,k)));
        end
    else
        st = strcat(st, '[0]:',' ',dbl2str(handles.BrSys.P.pts(i,k)));
    end
    content = {content{:} st};
    
end
for i=DimX+1:numel(ParamList)
    st = ParamList{i};
    st = strcat(st, ':',' ',dbl2str(handles.BrSys.P.pts(i,k)));
    content = {content{:} st};
end

handles.selected_param = min(handles.selected_param, ...
    numel(ParamList));

set(handles.listbox_default_parameters,'String',content);
set(handles.listbox_default_parameters,'Value',handles.selected_param);

set(handles.edit_default_param, 'String', dbl2str(handles.BrSys.P.pts(handles.selected_param,k)));
set(handles.edit_param_name, 'String', handles.BrSys.P.ParamList(handles.selected_param));

%% Varying parameters listbox
content = {};

for i=1:numel(dim)
    [st, st_min, st_max] = get_varying_param_string(handles,i);
    content = {content{:} st};

end
set(handles.listbox_varying_parameters,'String',content);

handles.selected_varying_param = min(handles.selected_varying_param, ...
    numel(content));
set(handles.listbox_varying_parameters,'Value',handles.selected_varying_param);

% edit pts and epsi

ipts = dim(min(handles.selected_varying_param, numel(dim)));
pts = handles.BrSys.P.pts(ipts,k);
epsi = handles.BrSys.P.epsi(handles.selected_varying_param,k);

set(handles.edit_value_pts, 'String', dbl2str(pts));
set(handles.edit_uncertainty, 'String', dbl2str(epsi));
st_min = dbl2str(pts-epsi);
st_max = dbl2str(pts+epsi);
set(handles.edit_pmin, 'String', st_min);
set(handles.edit_pmax, 'String', st_max);

% slider

tt=strcat('pts ',num2str(handles.current_pts),'/',num2str(nb_pts));
set(handles.text_pts, 'String', tt );
set(handles.slider_current_pts, 'Value',handles.current_pts,'Min', .9999, 'Max',nb_pts, 'SliderStep', [1/nb_pts 10/nb_pts]);
set(handles.checkbox_selected, 'Value', handles.BrSys.P.selected(handles.current_pts));

% button plot all/selected

if isempty(find(handles.BrSys.P.selected))
    set(handles.button_plot_selected, 'String', 'Plot traj(s)')
else
    set(handles.button_plot_selected, 'String', 'Plot selected')
end


if(DimP ~= handles.Sys.DimP)||(DimX ~= handles.Sys.DimX)
    handles= info(handles, 'WARNING: Dimensions of System and Parameter set are inconsistent - This parameter set was probably created for another system configuration');
end
% menu for param pts plot

set(handles.popup_pts1,'String',ParamList);
handles.current_plot_pts{1} = ParamList(dim(1));
set(handles.popup_pts1,'Value', dim(1));
set(handles.popup_pts2,'String',{'', ParamList{:}});

if(numel(dim)>=2)
    handles.current_plot_pts{2} = ParamList(dim(2));
    set(handles.popup_pts2,'Value', dim(2)+1);
else
    handles.current_plot_pts{2} = '';
    set(handles.popup_pts2,'Value', 1);
end

set(handles.popup_pts3,'String',{'', ParamList{:}});
if(numel(dim)>=3)
    handles.current_plot_pts{3} = ParamList(dim(3));
    set(handles.popup_pts3,'Value', dim(3)+1);
else
    handles.current_plot_pts{3} = '';
    set(handles.popup_pts3,'Value', 1);
end
handles =  plot_pts(handles);

function handles = update_system_panel(handles)

function [st, st_min,st_max] = get_varying_param_string(handles, i)

ipts = handles.BrSys.P.dim(i);
pts = handles.BrSys.P.pts(ipts,handles.current_pts);
epsi = handles.BrSys.P.epsi(i, handles.current_pts);
st = handles.BrSys.P.ParamList{ipts};


st_min = dbl2str(pts-epsi);
st_max = dbl2str(pts+epsi);
st = [st ': ' dbl2str(pts) ' +/- ' dbl2str(epsi) ' i.e ' '[' st_min ',' st_max, ']' ];


function handles= plot_pts(handles)

axes(handles.axes_pts);
hold off;
cla;
legend off;
set(gca,'YLimMode','auto');

param_to_plot = handles.current_plot_pts{1};

if ~isfield(handles.BrSys.P,'selected')
    handles.BrSys.P.selected = zeros(size(handles.BrSys.P.pts,2))
end

ipts = [handles.current_pts find(handles.BrSys.P.selected)];
ipts = unique(sort(ipts));

if ~strcmp(param_to_plot,'')
    if ~strcmp(handles.current_plot_pts{2},'')
        param_to_plot = {param_to_plot{:} handles.current_plot_pts{2}};
    end
    
    if ~strcmp(handles.current_plot_pts{3},'')
        param_to_plot = {param_to_plot{:} handles.current_plot_pts{3}};
    end
end


P = handles.BrSys.P;
i0=0;
if ~isfield(P, 'props_values')
    SplotPts(P, param_to_plot);
    
    if ~isempty(ipts(2:end))
        SplotBoxPts(P, param_to_plot,ipts(2:end),'+b','y',.1);
    end
    
    SplotPts(P, param_to_plot,handles.current_pts,{'ok', 'MarkerSize',14});
    SplotBoxPts(P, param_to_plot,handles.current_pts,{'xk', 'MarkerSize',14} ,'k',.1);
    S = DiscrimPropValues(P);
    SplotPts(S,param_to_plot);
else
    for i=1:numel(P.props_names)
        if strcmp(P.props_names{i}, handles.current_prop)
            i0 = i;
        end
    end
    if i0
        val = cat(1, P.props_values(i0,:).val);
        val = val(:,1);
        iparam = FindParam(P,param_to_plot);
        switch (numel(iparam))
            
            case 1
                x = P.pts(iparam(1),:);
                y = zeros(size(x));
                scatter(x,y, 30, val, 'filled');
                
            case 2
                x = P.pts(iparam(1),:);
                y = P.pts(iparam(2),:);
                scatter(x,y, 30, val, 'filled');
                
            case 3
                x = P.pts(iparam(1),:);
                y = P.pts(iparam(2),:);
                z = P.pts(iparam(3),:);
                scatter3(x,y, z, 30, val, 'filled');
        end
        
        stats = sprintf(['val:' dbl2str(val(handles.current_pts)) ...
            '\n#True:' dbl2str(numel(find(val>0))) '/' dbl2str(numel(val))  ...
            '\nMean:' dbl2str(mean(val)) ...
            '\nstd:' dbl2str(std(val)) ...
            '\nMax:' dbl2str(max(val)) ...
            '\nMin:' dbl2str(min(val))]);
        
        legend(stats)
        
        clim = sym_clim(val);
        if diff(clim)>0
            set(gca, 'CLim',clim );
        end
        colormap([ 1 0 0; 0 1 0 ]);
        
        hold on;
        
        if ~isempty(ipts(2:end))
            SplotBoxPts(P, param_to_plot,ipts(2:end),'+b','y',.1);
        end
        
        SplotPts(P, param_to_plot,handles.current_pts,{'ok', 'MarkerSize',14});
        SplotBoxPts(P, param_to_plot,handles.current_pts,{'xk', 'MarkerSize',14} ,'k',.1);
    else
        SplotPts(P, param_to_plot);
        
        if ~isempty(ipts(2:end))
            SplotBoxPts(P, param_to_plot,ipts(2:end),'+b','y',.1);
        end
        
        SplotPts(P, param_to_plot,handles.current_pts,{'ok', 'MarkerSize',14});
        SplotBoxPts(P, param_to_plot,handles.current_pts,{'xk', 'MarkerSize',14} ,'k',.1);
        S = DiscrimPropValues(P);
        SplotPts(S,param_to_plot);
    end
end

% --------------------------------------------------------------------
function menu_traj_and_sensi_Callback(hObject, eventdata, handles)
% hObject    handle to menu_traj_and_sensi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_compute_traj_Callback(hObject, eventdata, handles)
% hObject    handle to menu_compute_traj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tspan = inputdlg('Enter tspan (Format: [ti tf] or [t0 t1 t2 ... tn] or ti:dt:tf)','Compute trajectories', 1, {handles.last_tspan});
if isempty(tspan)
    return;
end
handles.last_tspan = tspan{1};
tspan = eval(tspan{1});

if (exist([pwd filesep 'cvm'])~=3)
    CompileSystem(handles.Sys);
end

uipause;
set(handles.text_info, 'Simulation running ...');
guidata(hObject, handles);

handles.working_sets.(handles.current_set) = ComputeTraj(handles.Sys, handles.working_sets.(handles.current_set), tspan);
handles = update_working_sets_panel(handles);
uiresume;
set(handles.text_info, 'Simulation done.');
guidata(hObject, handles);

% --------------------------------------------------------------------
function menu_purge_traj_Callback(hObject, eventdata, handles)
% hObject    handle to menu_purge_traj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.working_sets.(handles.current_set) = ...
    SPurge(handles.working_sets.(handles.current_set));
handles = update_working_sets_panel(handles);
handles = update_modif_panel(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_refine_prop_bound_Callback(hObject, eventdata, handles)
% hObject    handle to menu_refine_prop_bound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

restore_traj =0;
if isfield( handles.Sys, 'type')
    if strcmp(handles.Sys.type,'traces')
        if isfield(handles.working_sets.(handles.current_set), 'traj')
            traj(1) = handles.working_sets.(handles.current_set).traj{1};
            restore_traj =1;
        end
    end
end

%  options dialog box
info = 'Refine boundary between regions satisfying different properties';
answers = { handles.current_prop,'','0','3'};
ins = inputdlg({'Enter array of properties (e.g. [phi1, phi2])', 'Enter tspan for trajectories (empty: tspan of computed trajs)','Enter time for property checking', 'Number of iterations'}, info,1, answers );

S = handles.working_sets.(handles.current_set);
if isempty(ins)
    return;
end

load(handles.properties_file_name);

if isempty(ins{1})
    prop_name = handles.current_prop;
    prop = handles.properties.(prop_name);
else
    prop = eval(ins{1});
end

if isempty(ins{2})
    tspan = S.traj{1}.time;
else
    tspan = eval(ins{2});
end

tprop = eval(ins{3});
nb_iter = eval(ins{4});

S = rmfield(S,'selected');
Sf = SFindPropBoundary(handles.Sys,S, prop, tspan,tprop, nb_iter);

% TOFIX: hasty patch
Sf = rmfield(Sf,'selected');


handles.working_sets.(handles.current_set) = Sf;
handles = update_modif_panel(handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function menu_plot_property_val_Callback(hObject, eventdata, handles)
% hObject    handle to menu_plot_property_val (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    close(handles.figp)
end
handles.figp = figure;
hold on;
SplotProp(handles.working_sets.(handles.current_set), handles.properties.(handles.current_prop));
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_falsify_Callback(hObject, eventdata, handles)
% hObject    handle to menu_falsify (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

kn = find(handles.working_sets.(handles.current_set).selected);
if isempty(kn)
    kn = handles.current_pts;
end
Psel = Sselect( handles.working_sets.(handles.current_set), kn);
prop_name = handles.current_prop;
prop = handles.properties.(prop_name);

BrSys = handles.BrSys.copy();
BrSys.SetP(Psel);

if isfield(handles, 'falsif_pb')
    options = handles.falsif_pb.solver_options;
    handles.falsif_pb = FalsificationProblem(BrSys, prop);
else
    handles.falsif_pb = FalsificationProblem(BrSys, prop);
    options = handles.falsif_pb.solver_options;
end

options = structdlg(options);
if isempty(options)
    return;
end
handles.falsif_pb.solver_options = options;
handles.falsif_pb.log_traces=1;

handles = info(handles, 'Optimizing...');

handles.falsif_pb.solve();

BrFalse = handles.falsif_pb.GetBrSet_False();
BrLogged = handles.falsif_pb.GetBrSet_Logged();

if isempty(BrFalse)
    handles = info(handles, 'No falsifying input found');
else
    handles = info(handles, 'Done.');
    PFalse = BrFalse.P;
    PFalse.epsi = 0*PFalse.epsi;
    new_name = ['PFalse_' get_id(prop)];
    handles.working_sets = setfield(handles.working_sets, new_name, PFalse);
end
PLog =  BrLogged.P;
PLog.epsi = 0*PLog.epsi;
new_name2 = ['PLog_' get_id(prop)];
handles.working_sets = setfield(handles.working_sets, new_name2, PLog);

handles = update_working_sets_panel(handles);
handles = update_modif_panel(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_select_Callback(hObject, eventdata, handles)
% hObject    handle to menu_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function menu_select_prop_gt_Callback(hObject, eventdata, handles)
% hObject    handle to menu_select_prop_gt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    iprop = find_prop(handles.current_prop,handles.working_sets.(handles.current_set) );
    valst = inputdlg('greater than ?');
    if isempty(valst)
        return;
    end
    
    val_threshold = eval(valst{1});
    
    if iprop
        val = cat(1,handles.working_sets.(handles.current_set).props_values(iprop,:).val);
        val = val(:,1);
        handles.working_sets.(handles.current_set).selected = (val>=val_threshold)';
    end
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
    
catch
    s = lasterror;
    warndlg(['Problem selection: ' s.message] );
    error(s);
    return
end

% --------------------------------------------------------------------
function menu_select_prop_abs_st_Callback(hObject, eventdata, handles)
% hObject    handle to menu_select_prop_abs_st (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    iprop = find_prop(handles.current_prop,handles.working_sets.(handles.current_set));
    valst = inputdlg('smaller than ?');
    if isempty(valst)
        return;
    end
    val_threshold = eval(valst{1});
    if iprop
        val = cat(1,handles.current_prop,handles.working_sets.(handles.current_set).props_values(iprop,:).val);
        val = val(:,1);
        handles.working_sets.(handles.current_set).selected = (abs(val)<=val_threshold)';
    end
    
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
catch
    s = lasterror;
    warndlg(['Problem during selection: ' s.message] );
    error(s);
    return
end


% --------------------------------------------------------------------
function menu_inverse_selection_Callback(hObject, eventdata, handles)
% hObject    handle to menu_inverse_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.working_sets.(handles.current_set).selected = ~ handles.working_sets.(handles.current_set).selected;
handles = update_modif_panel(handles);
guidata(hObject,handles);


% --------------------------------------------------------------------
function plot_zero_contour_Callback(hObject, eventdata, handles)
% hObject    handle to plot_zero_contour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    axes(handles.axes_pts);
    hold on;
    
    iprop = find_prop(handles.current_prop,  handles.working_sets.(handles.current_set));
    if iprop
        switch numel(Pf.dim)
            case 2
                val = cat(1, Pf.props_values(iprop,:).val);
                Z = val(:,1);
                QuickContourSf(Pf,Z)
        end
    end
catch
    s = lasterror;
    warndlg(['Problem with plot_zero_contour: ' s.message] );
    error(s);
    return
end


% --------------------------------------------------------------------
function menu_unselect_Callback(hObject, eventdata, handles)
% hObject    handle to menu_unselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.working_sets.(handles.current_set).selected = 0* ...
    handles.working_sets.(handles.current_set).selected;
handles = update_modif_panel(handles);

guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_select_range_st_Callback(hObject, eventdata, handles)
% hObject    handle to menu_select_range_st (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    P = handles.working_sets.(handles.current_set);
    deltast = inputdlg('Enter range:');
    if isempty(deltast)
        return;
    end
    delta = eval(deltast{:});
    
    if numel(delta)==1
        delta = repmat(delta, [size(P.epsi,1) 1]);
    end
    
    Dp = repmat(delta,[1 size(P.epsi,2)]);
    kn = find(sum(P.epsi<=Dp,1));
    handles.working_sets.(handles.current_set).selected(kn)=1;
    
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
    
catch
    s = lasterror;
    warndlg(['Problem in selection: ' s.message] );
    error(s);
    return
end


% --- Executes on button press in button_new_prop.
function button_new_prop_Callback(hObject, eventdata, handles)
% hObject    handle to button_new_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prop = handles.properties.(handles.current_prop);
evalin('base', ['load(''' handles.properties_file_name ''')']);
load(handles.properties_file_name);

BrSys = handles.BrSys;
PHI_= BrSys.AddSpecGUI();

% prompt = {'Enter id', 'Edit formula expression:'};
% name = 'New/Copy Formula';
% numlines = 1;
% defaultanswer = {genvarname(get_id(prop), fieldnames(handles.properties)), disp(prop,-1)};
% opts.Resize = 'on';
% opts.WindowStyle = 'normal';
% str = inputdlg(prompt,name,numlines,defaultanswer, opts);
%
% if isempty(str)
%     return;
% end
%
% try
%     id = str{1};
%     phi_st = str{2};
%     PHI = eval(['STL_Formula(''' id ''',''' phi_st ''')']);
%     eval([get_id(PHI) '=PHI']);
% catch
%     s = lasterror;
%     warndlg(['Invalid formula: ' s.message] );
%     error(s);
%     return
% end
if isa(PHI_,'STL_Formula')
    eval([get_id(PHI_) '=PHI_']);
    save(handles.properties_file_name, '-append', get_id(PHI_));
    handles = update_properties_panel(handles);
    guidata(hObject, handles);
else
    info(handles,'No new formula was defined.');
end

function i = find_prop(st, P)
i=0;

if ~isfield(P, 'props_names')
    return;
else
    props_names =  P.props_names;
end

for k = 1:numel(props_names)
    if strcmp(st,props_names{k})
        i = k;
        return;
    end
end

% --- Executes on button press in button_del_property.
function button_del_property_Callback(hObject, eventdata, handles)
% hObject    handle to button_del_property (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    fn = fieldnames(handles.properties);
    
    if numel(fn)==1
        return
    end
    
    st = fn{get(handles.listbox_prop,'Value')};
    val = get(handles.listbox_prop,'Value');
    
    if(val>1)
        val = val-1;
        set(handles.listbox_prop,'Value', val);
        handles.current_prop = fn{val};
    else
        handles.current_prop = fn{val+1};
    end
    
    handles.properties = rmfield(handles.properties,st);
    props = handles.properties;
    save(handles.properties_file_name,'-struct','props');
    
    handles = update_properties_panel(handles);
    guidata(hObject, handles);
    
catch
    s = lasterror;
    warndlg(['Problem deleting property: ' s.message] );
    error(s);
    return
end

% --------------------------------------------------------------------
function menu_load_properties_Callback(hObject, eventdata, handles)
% hObject    handle to menu_load_properties (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    [FileName,PathName,FilterIndex] = uigetfile('*.mat; *.stl','Load Properties Set...');
    
    if (FileName ==0)
        return
    end
    
    [~,~,ext] = fileparts(FileName);
    
    if strcmp(ext,'.mat')
        props = load(FileName);
        fnames = fieldnames(props);
        
        % find properties in the file loaded
        nprops = [];
        
        for j = 1:numel(fnames)
            if isa(props.(fnames{j}), 'STL_Formula')
                nprops = [ nprops props.(fnames{j}) ];
            end
        end
        
        if isempty(nprops)
            warndlg('No properties in this file');
            return
        else
            handles.properties = nprops;
        end
        handles.properties_file_name = FileName;
        handles.current_prop = fnames{1};
        handles.idx_prop = 1;
        
    elseif strcmp(ext,'.stl')
        formulas = STL_ReadFile([PathName FileName]);
        Propsave(handles.Sys, formulas{:});
        
    end
    
    set(handles.listbox_prop, 'Value', 1);
    handles = update_properties_panel(handles);
    guidata(hObject,handles);
    
catch
    
    s = lasterror;
    warndlg(['Problem loading property: ' s.message] );
    error(s);
    return
    
end

% --------------------------------------------------------------------
function menu_save_properties_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save_properties (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    FileName = uiputfile('*.mat','Save Properties Set As...');
    
    if(FileName==0)
        return
    end
    
    handles.properties_file_name = FileName;
    ws = handles.properties;
    save(FileName, '-struct','ws');
    handles = update_properties_panel(handles);
    guidata(hObject,handles);
    
catch
    s = lasterror;
    warndlg(['Problem saving property: ' s.message] );
    error(s);
    return
end

% --------------------------------------------------------------------
function menu_param_sets_Callback(hObject, eventdata, handles)
% hObject    handle to menu_param_sets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_refine_prop_boundary_sensi_Callback(hObject, eventdata, handles)
% hObject    handle to menu_refine_prop_boundary_sensi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    prop_name = handles.current_prop;
    prop = handles.properties.(prop_name);
    
    info = 'NOT TESTED, use without sensi instead'
    ins = inputdlg({'Enter tspan for trajectories','Enter time for property checking', 'Number of iterations'});
    
    if isempty(ins)
        return;
    end
    
    try
        tspan = eval(ins{1});
    catch
        tspan = 0:.1:1;
    end
    
    try
        tprop = eval(ins{2});
    catch
        tprop = 0;
    end
    
    try
        nb_iter = eval(ins{3});
    catch
        nb_iter = 1;
    end
    
    S = rmfield(handles.working_sets.(handles.current_set),'selected');
    
    Sf = SCopyEmpty(S);
    Sf.selected = [];
    
    for i=1:nb_iter
        
        S = SFindPropBoundaReach(handles.Sys,S, prop, tspan,tprop);
        Sn = Sselect(S, find(S.IsOnBoundary>0));
        Snn = Sselect(S, find(S.IsOnBoundary==0));
        
        nbnn = size(Snn.pts,2);
        if(nbnn)
            Sf = SConcat(Sf, Snn);
            Sf.selected(end+1:end+nbnn) = 0 ;
        end
        %    S = VoronoiRefine(S);
        if(i<nb_iter)
            S = Refine(Sn,2);
        end
    end
    
    Sf = SConcat(Sf, Sn);
    nbn = size(Sn.pts,2);
    Sf.selected(end+1:end+nbn) = 1;
    handles.working_sets.(handles.current_set) = Sf;
    handles = update_modif_panel(handles);
    guidata(hObject, handles);
    
catch
    s = lasterror;
    warndlg(['Problem refining: ' s.message] );
    error(s);
    return
end

% --------------------------------------------------------------------
function menu_plot_local_sensi_histo_Callback(hObject, eventdata, handles)
% hObject    handle to menu_plot_local_sensi_histo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%  P = Sselect(handles.working_sets.(handles.current_set), handles.current_pts);
try
    P = handles.working_sets.(handles.current_set);
    [M, handles.last_options] = SplotSensiBar(handles.Sys, P, [],[]);
catch
    s = lasterror;
    warndlg(['Problem refining: ' s.message] );
    error(s);
    return
end

guidata(hObject, handles);

% --------------------------------------------------------------------
function menu_plot_local_sensi_histo_prev_Callback(hObject, eventdata, handles)
% hObject    handle to menu_plot_local_sensi_histo_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%  P = Sselect(handles.working_sets.(handles.current_set), handles.current_pts);

P = handles.working_sets.(handles.current_set);
try
    [M, handles.last_options] = SplotSensiBar(handles.Sys, P, [],handles.last_options);
catch
    handles.last_options = [];
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function menu_properties_Callback(hObject, eventdata, handles)
% hObject    handle to menu_properties (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in button_go_refine.
function button_go_refine_Callback(hObject, eventdata, handles)
% hObject    handle to button_go_refine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    if(handles.refine_args==0)
        return;
    end
    
    restore_traj =0;
    if isfield( handles.Sys, 'type')
        if strcmp(handles.Sys.type,'traces')
            if isfield(handles.working_sets.(handles.current_set), 'traj')
                traj = handles.working_sets.(handles.current_set).traj;
                restore_traj =1;
            end
        end
    end
    
    nb_pts = size(handles.working_sets.(handles.current_set).pts,2);
    if(get(handles.checkbox_sample_locally, 'Value'))
        if(handles.halton)
            Pr = QuasiRefine(handles.working_sets.(handles.current_set), ...
                handles.refine_args);
        else
            Pr = Refine(handles.working_sets.(handles.current_set), ...
                handles.refine_args);
        end
        nnb_pts = size(Pr.pts,2);
        Pr.selected = zeros(1, nnb_pts);
        handles.working_sets.(handles.current_set) = Pr;
        
    else
        
        ipts = find(handles.working_sets.(handles.current_set).selected);
        if isempty(ipts)
            ipts = handles.current_pts;
        end
        
        Ptmp = Sselect(handles.working_sets.(handles.current_set),ipts);
        if(handles.halton)
            Pr =QuasiRefine(Ptmp, handles.refine_args);
        else
            Pr = Refine(Ptmp, handles.refine_args);
        end
        nnb_pts = size(Pr.pts,2);
        Pr.selected = zeros(1, nnb_pts);
        
        nipts = find(~handles.working_sets.(handles.current_set).selected);
        if(ipts == handles.current_pts)
            nipts = nipts(nipts~=handles.current_pts);
        end
        
        if isempty(nipts)
            Pf = Pr;
        else
            P = Sselect(handles.working_sets.(handles.current_set), nipts);
            P = SPurge(P);
            P = SPurge_props(P);
            Sf = SConcat(Pr,P);
        end
        
        if(restore_traj)
            Pf.traj = repmat(traj(1), [1 size(Pf.pts,2)]);
            for j = 1:numel(Pf.traj)
                Pf.traj{j}.param = Pf.pts(:,j);
            end
        end
        
        handles.working_sets.(handles.current_set) = Pf;
        
    end
    
    set(handles.edit_refine, 'String','');
    set(hObject,'String','Go (0 new samples)');
    handles.refine_args = 0 ;
    
    handles = update_working_sets_panel(handles);
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
    
catch
    s = lasterror;
    set(handles.edit_refine, 'String','');
    set(hObject,'String','Go (0 new samples)');
    handles.refine_args = 0 ;
    handles = update_working_sets_panel(handles);
    handles = update_modif_panel(handles);
    warndlg(['Problem refining: ' s.message] );
end

% --- Executes on button press in button_explore_traj.
function button_explore_traj_Callback(hObject, eventdata, handles)
% hObject    handle to button_explore_traj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h = BreachTrajGui(handles.BrSys, handles);

% --------------------------------------------------------------------
function System_Callback(hObject, eventdata, handles)
% hObject    handle to System (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in button_save.
function button_save_Callback(hObject, eventdata, handles)
% hObject    handle to button_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ws = handles.working_sets; %#ok<NASGU>
save(handles.working_sets_file_name, '-struct', 'ws');


% --- Executes on button press in button_del_selected.
function button_del_selected_Callback(hObject, eventdata, handles)
% hObject    handle to button_del_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    % deals with the case where no dynamics is used (only traces)
    restore_traj = 0;
    if isfield(handles.Sys, 'type')
        if strcmp(handles.Sys.type,'traces')
            if isfield(handles.working_sets.(handles.current_set), 'traj')
                traj = handles.working_sets.(handles.current_set).traj;
                restore_traj =1;
            end
        end
    end
    
    nb_pts = size(handles.working_sets.(handles.current_set).pts,2);
    if(nb_pts == 1) % cannot delete a unique sample
        return;
    end
    
    ipts = find(handles.working_sets.(handles.current_set).selected);
    if isempty(ipts)
        return;
    end
    
    nipts = find(~handles.working_sets.(handles.current_set).selected);
    if ipts == handles.current_pts
        nipts = nipts(nipts~=handles.current_pts);
    end
    
    P = Sselect(handles.working_sets.(handles.current_set), nipts);
    
    handles.working_sets.(handles.current_set) = P;
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
    
catch
    s = lasterror;
    warndlg(['Problem deleting selected: ' s.message] );
end


% --------------------------------------------------------------------
function menu_max_robust_satisfaction_Callback(hObject, eventdata, handles)
% hObject    handle to menu_max_robust_satisfaction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    P = handles.working_sets.(handles.current_set);
    info = 'Find max robust satisfaction ';
    
    dim = P.dim;
    pts = P.pts(:,handles.current_pts);
    epsi = P.epsi(:,handles.current_pts);
    
    lbstr = '';
    ustr  = '';
    
    for i=1:numel(pts)
        lbstr = ['' num2str(pts(dim(i)+epsi(1,i)))];
        upstr = ['' num2str(pts(dim(i)+epsi(2,i)))];
    end
    
    answers = {'',lbstr,upstr};
    ins = inputdlg({'Enter tspan for trajectories (default: computed trajectory)', ...
        'Enter lower bounds', ...
        'Enter upper bounds'}, info,1, answers );
    if isempty(ins)
        return;
    end
    
    if isempty(ins{1})
        tspan = S.traj{1}.time;
    else
        tspan = eval(ins{1});
    end
    
    opt.lbound = eval(ins{2});
    opt.ubound = eval(ins{3});
    
    prop_name = handles.current_prop;
    prop = handles.properties.(prop_name);
    
    Sopt = SOptimProp(handles.Sys, P, prop , tspan, lbound, ubound);
    
    % add optimized parameter set
    
    val = get(handles.working_sets_listbox, 'Value');
    names = fieldnames(handles.working_sets);
    set_name = names{val};
    new_name = genvarname(set_name,names);
    handles.working_sets = setfield(handles.working_sets, new_name, Sopt);
    handles = update_modif_panel(handles);
    
catch
    s = lasterror;
    warndlg(['Problem deleting selected: ' s.message] );
    error(s);
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_remove_prop_Callback(hObject, eventdata, handles)
% hObject    handle to menu_remove_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.working_sets.(handles.current_set) = SPurge_props(handles.working_sets.(handles.current_set));
handles = update_working_sets_panel(handles);
handles = update_properties_panel(handles);
handles = update_modif_panel(handles);
guidata(hObject,handles);


% --- Executes on button press in button_plot_prop.
function button_plot_prop_Callback(hObject, eventdata, handles)
% hObject    handle to button_plot_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


prop = handles.properties.(handles.current_prop);
title = 'Plot property options';
prompt = {'Enter tspan for trajectory computation (empty = existing traj), ',...
    'Enter tspan for property evaluation (empty = same as above)' ...
    'Levels of subformulas to plot'};
opt.tspan_traj = [];
opt.tspan_prop_eval = [];
opt.break_lev = inf;

%[opt, handles.check_prop_options] = structdlg(opt, title, prompt, handles.check_prop_options);

if isempty(opt)
    return;
end

Ptmp = Sselect(handles.working_sets.(handles.current_set), handles.current_pts);

if ~isempty(opt.tspan_traj)
    Pphi = SPurge(Ptmp);
    Pphi = ComputeTraj(handles.Sys, Pphi, opt.tspan_traj);
else
    Pphi = Ptmp;
end

if isempty(opt.tspan_prop_eval)
    opt.tspan_prop_eval = Pphi.traj{Pphi.traj_ref(1)}.time;
end

handles = info(handles, 'Computing satisfaction of formula...');
Pphi = SEvalProp(handles.Sys, Pphi, prop, opt.tspan_prop_eval, 1, opt.break_lev);
PplotFormula(handles.Sys, Pphi, prop, 1, opt.break_lev);
handles = info(handles, 'Computing satisfaction of formula... Done.');
guidata(hObject,handles);


% --- Executes on button press in button_break_prop.
function button_break_prop_Callback(hObject, eventdata, handles)
% hObject    handle to button_break_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prop = handles.properties.(handles.current_prop);
props = STL_Break(prop);

for i = 1:numel(props)
    PHI_ = props(i);
    eval([get_id(PHI_) '=PHI_']);
    handles.properties.(get_id(props(i))) = props(i);
    save(handles.properties_file_name, '-append', get_id(props(i)));
end

handles = update_properties_panel(handles);

guidata(hObject, handles);


% --- Executes on button press in button_plot_selected.
function button_plot_selected_Callback(hObject, eventdata, handles)
% hObject    handle to button_plot_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    % getting parameters
    if isfield(handles.Sys, 'time_mult')
        handles.working_sets.(handles.current_set).time_mult = handles.Sys.time_mult;
    end
    
    ipts = find(handles.working_sets.(handles.current_set).selected);
    
    if isfield(handles.working_sets.(handles.current_set), 'plot_args')
        args = handles.working_sets.(handles.current_set).plot_args;
        args = plots_args_gui(handles.working_sets.(handles.current_set), args);
    else
        args = plots_args_gui(handles.working_sets.(handles.current_set), []);
    end
    
    handles.working_sets.(handles.current_set).plot_args = args;
    
    if isempty(args)
        return;
    end
    
    h = figure;
    assignin('base','h_breach_', h);
    
    if(args.phase_portrait == 1)
        SplotTraj(handles.working_sets.(handles.current_set), args.iX ,ipts ,[]);
    else
        
        SplotVar(handles.working_sets.(handles.current_set), args.iX,ipts ,[], args.same_axe);
    end
    
catch
    s = lasterror;
    handles = info(handles,['Problem plotting trajectories: did you run simulation first?'] );
    guidata(hObject, handles);
end

return


% --- Executes on key press with focus on breach and none of its controls.
function breach_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to breach (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


function st = dbl2str(x)
st = num2str(x, '%0.5g');

% --------------------------------------------------------------------
function menu_select_satisfied_Callback(hObject, eventdata, handles)
% hObject    handle to menu_select_satisfied (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    
    iprop = find_prop(handles.current_prop,handles.working_sets.(handles.current_set));
    val_threshold = 0;
    if iprop
        val = cat(1,handles.working_sets.(handles.current_set).props_values(iprop,:).val);
        val = val(:,1);
        handles.working_sets.(handles.current_set).selected = (val>=val_threshold)';
    end
    
    handles = update_modif_panel(handles);
    guidata(hObject,handles);
    
catch
    s = lasterror;
    warndlg(['Problem selection: ' s.message] );
    error(s);
    return
end

function edit_param_name_Callback(hObject, eventdata, handles)
% hObject    handle to edit_param_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit_param_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_param_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function h = info(h,msg)
% INFO write the message into the information panel.
set(h.text_info, 'String', msg);
drawnow();

% --- Executes on button press in autosave_checkbox.
function autosave_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to autosave_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function system_panel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to system_panel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --------------------------------------------------------------------
function create_input_parameter_set_Callback(hObject, eventdata, handles)
% hObject    handle to create_input_parameter_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

idx = handles.BrSys.GetParamsInputIdx();
Pnew = CreateParamSet(handles.Sys, idx);
names = fieldnames(handles.working_sets);
new_name = genvarname('Pin',names);
handles.working_sets = setfield(handles.working_sets, new_name, Pnew);
%set(handles.working_sets_listbox,'Value', numel(names)+1);
handles = update_working_sets_panel(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function create_prop_param_set_Callback(hObject, eventdata, handles)
% hObject    handle to create_prop_param_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prop = handles.properties.(handles.current_prop);
param_prop = fieldnames(get_params(prop))';
Pnew = CreateParamSet(handles.Sys, param_prop);
names = fieldnames(handles.working_sets);
new_name = genvarname(['P_' get_id(prop)],names);
handles.working_sets = setfield(handles.working_sets, new_name, Pnew);
%set(handles.working_sets_listbox,'Value', numel(names)+1);
handles = update_working_sets_panel(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_param_synth_Callback(hObject, eventdata, handles)
% hObject    handle to menu_param_synth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

kn = find(handles.working_sets.(handles.current_set).selected);
if isempty(kn)
    kn = handles.current_pts;
end
Psel = Sselect( handles.working_sets.(handles.current_set), kn);
prop_name = handles.current_prop;
prop = handles.properties.(prop_name);

BrSys = handles.BrSys.copy();
BrSys.SetP(Psel);

handles.param_synth_pb = ParamSynthProblem(BrSys, prop);

handles = info(handles, 'Optimizing...');

handles.param_synth_pb.solve();

BrSynth = handles.param_synth_pb.GetBrSet_Best();
BrLogged = handles.param_synth_pb.GetBrSet_Logged();

% TODO what if no synth param exist?
names = fieldnames(handles.working_sets);
handles = info(handles, 'Done.');
PSynth = BrSynth.P;
PSynth.epsi = 0*PSynth.epsi;
new_name = genvarname(['PSynth_' get_id(prop)],names);
handles.working_sets = setfield(handles.working_sets, new_name, PSynth);

PLog =  BrLogged.P;
PLog.epsi = 0*PLog.epsi;
new_name2 = genvarname(['PLog_' get_id(prop)],names);
handles.working_sets = setfield(handles.working_sets, new_name2, PLog);

handles = update_working_sets_panel(handles);
handles = update_modif_panel(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_reset_param_files_Callback(hObject, eventdata, handles)
% hObject    handle to menu_reset_param_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filename = [handles.Sys.name '_param_sets.mat'];
backup = ['.' handles.Sys.name '_param_sets.mat.bck'];
title = ['Reset param set file'];
answ = questdlg('Are you sure?', title);

if strcmp(answ,'Yes')
    movefile(filename, backup);
    handles.BrSys.RunGUI;
end


% --------------------------------------------------------------------
function menu_reset_prop_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_reset_prop_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


filename = [handles.Sys.Dir filesep handles.Sys.name '_properties.mat'];
backup = [handles.Sys.Dir filesep '.' handles.Sys.name '_properties.mat.bck'];
title = ['Reset prop file'];
answ = questdlg('Are you sure?', title);

if strcmp(answ,'Yes')
    movefile(filename, backup);
    handles.BrSys.RunGUI;
end



% --- Executes on button press in pushbutton_input_gen.
function pushbutton_input_gen_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_input_gen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = [handles.Sys.Dir filesep handles.Sys.name '_param_sets.mat'];
backup = [handles.Sys.Dir filesep '.' handles.Sys.name '_param_sets.mat.bck'];
[~] = movefile(filename, backup);
BrSys = handles.BrSys;
BrSys.SetInputGenGUI;
close(handles.breach);



function edit_pmin_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


val_min = eval(get(hObject,'String'));
val_max = eval(get(handles.edit_pmax,'String'));
epsi = (val_max-val_min)/2;
if epsi<0
    return
end
pts = val_min+ epsi;
ipts = handles.working_sets.(handles.current_set).dim(handles.selected_varying_param);
handles.working_sets.(handles.current_set).pts(ipts,handles.current_pts) = pts;
handles.working_sets.(handles.current_set).epsi(handles.selected_varying_param,handles.current_pts) = epsi;

handles = update_modif_panel(handles);
guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function edit_pmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_pmax_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_pmax as text
%        str2double(get(hObject,'String')) returns contents of edit_pmax as a double

val_min = eval(get(handles.edit_pmin,'String'));
val_max = eval(get(handles.edit_pmax,'String'));
epsi = (val_max-val_min)/2;
if epsi<0
    return
end
pts = val_min+ epsi;
ipts = handles.working_sets.(handles.current_set).dim(handles.selected_varying_param);
handles.working_sets.(handles.current_set).pts(ipts,handles.current_pts) = pts;
handles.working_sets.(handles.current_set).epsi(handles.selected_varying_param,handles.current_pts) = epsi;

handles = update_modif_panel(handles);
guidata(hObject,handles);
uicontrol(handles.listbox_varying_parameters);


% --- Executes during object creation, after setting all properties.
function edit_pmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on listbox_default_parameters and none of its controls.
function listbox_default_parameters_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to listbox_default_parameters (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


if (isa(eventdata, 'matlab.ui.eventdata.UIClientComponentKeyEvent'))
    switch eventdata.Key
        case 'rightarrow'
            handles = add_param(handles);
            handles = update_modif_panel(handles);
            guidata(hObject,handles);
            
            
    end
end




% --- Executes on key press with focus on listbox_varying_parameters and none of its controls.
function listbox_varying_parameters_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to listbox_varying_parameters (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if (isa(eventdata, 'matlab.ui.eventdata.UIClientComponentKeyEvent'))
    switch eventdata.Key
        case 'leftarrow'
            st =    get(handles.listbox_varying_parameters,'String');
            if(numel(st)>1)
                
                handles = rm_param(handles);
                handles = update_modif_panel(handles);
                guidata(hObject,handles);
            end
        case 'return'
        uicontrol(handles.edit_pmin);
    end
    
end


% --- Executes on button press in checkbox_input_only.
function checkbox_input_only_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_input_only (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.BrSys.ResetSimulations();
handles.working_sets.(handles.current_set) = SPurge(handles.working_sets.(handles.current_set));
handles.BrSys.SimInputsOnly = get(hObject,'Value');
guidata(hObject,handles);



% --- Executes on button press in checkbox_sample_locally.
function checkbox_sample_locally_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_sample_locally (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_sample_locally
