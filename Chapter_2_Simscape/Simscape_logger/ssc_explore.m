function ssc_explore(node)
% SSC_EXPLORE Launch graphical tool for navigating and plotting
% Simscape(TM) simulation data.
%
% This file creates an interactive GUI for navigating and plotting Simscape
% simulation data.  You can navigate the simscape.logging.Node object using
% a tree browser, and the data is plotted for you automatically.  This
% makes it easier to plot the different physical quantities in your network
% without using sensors.
%
% To use this file, simply pass the simscape.logging.Node object to the
% function:
%
% >> ssc_explore(simlog)

% Copyright 2010-2012 The MathWorks, Inc.

% create tree
tree = lCreateTree(node);

% create explorer figure window
hFigure = figure('Name', sprintf('Simscape data logging explorer: %s', ...
    node.id), 'NumberTitle', 'off', 'Units', 'Pixels', ...
    'Position',  [400 100 650 650], 'HandleVisibility', 'callback');

% create button and status panels
buttonPanel = lCreateButtonPanel();
statusPanel = lCreateStatusPanel(node);

% create main panel
mainPanel = javax.swing.JPanel;
mainPanel.setLayout(java.awt.BorderLayout);

% add button panel to the top, tree in the middle and status on the bottom
mainPanel.add(buttonPanel, java.awt.BorderLayout.NORTH);
mainPanel.add(tree.getScrollPane, java.awt.BorderLayout.CENTER);
mainPanel.add(statusPanel, java.awt.BorderLayout.SOUTH);

% attach main panel to the figure window on the left
javacomponent(mainPanel,java.awt.BorderLayout.WEST,hFigure);

% get default options
options = lDefaultOptions(node);

% store node, tree and options in a struct on the figure user data
guidata.node = node;
guidata.tree = tree;
guidata.options = options;
guidata.navPanel= mainPanel;
guidata.inputName = inputname(1);
set(hFigure, 'UserData', guidata);

% select the root node as default selection
tree.setSelectedNode(tree.getRoot);
movegui(hFigure);
end

% ============== main GUI functions ==============

function options = lDefaultOptions(node)
% Get default options

% compute start and stop time from series
f = @(nv)(~strcmpi(nv{end}.series.unit, 'invalid'));
nodesWithData = node.find(f);
if ~isempty(nodesWithData)
    time = nodesWithData{1}.series.time;
    tStart = time(1);
    tEnd = time(end);
else
    tStart = nan;
    tEnd = nan;
end

% default options
options.time.limit = false;
options.time.start= tStart;
options.time.stop = tEnd;
options.marker = 1; % None
options.multi = 1; % Separate
options.link.x = true;
options.link.y = false;
options.align = 1; % Vertical
options.unit = 1; % Default
options.legend = 1; % Auto

end

function tree = lCreateTree(node)
% Create java tree from simscape.logging.Node object

% icons
iconDir = [matlabroot, '/toolbox/physmod/logging/resources/icons/'];
if exist(iconDir,'dir')
    icons.nonTerminalNode = [iconDir,'nonterminal_node.png'];
    icons.terminalNode = [iconDir,'signal.png'];
else
    iconDir = [matlabroot, '/toolbox/matlab/icons/'];
    icons.nonTerminalNode = [iconDir,'unknownicon.gif'];
    icons.terminalNode = [iconDir,'greencircleicon.gif'];
end

% create tree root
treeRoot = lCreateTreeNode(node,icons);

% populate tree
lPopulateTree(treeRoot, node, icons);

% create hg tree and set root
tree = javaObjectEDT('com.mathworks.hg.peer.UITreePeer');
tree.setRoot(treeRoot);

% setup tree selection call back
treeHandle = handle(tree, 'callbackproperties');
set(treeHandle, 'NodeSelectedCallBack',...
    {@lHgTreeSelectionCallback, tree, @lTreeSelectionCallback});

% set default view when the GUI is first launched
tree.getTree.expandRow(0);

% allow multi-select
tree.getTree.getSelectionModel.setSelectionMode(...
    javax.swing.tree.TreeSelectionModel.DISCONTIGUOUS_TREE_SELECTION);

end

function buttonPanel = lCreateButtonPanel
% Create button panel

% icons
iconDir = [matlabroot, '/toolbox/physmod/logging/resources/icons/'];
if exist(iconDir,'dir')
    icons.plotOptions = [iconDir,'plot_options.png'];
    icons.extractPlot = [iconDir,'extract_plot.png'];
    icons.reloadData  = [iconDir,'reload_data.png'];
else
    iconDir = [matlabroot, '/toolbox/matlab/icons/'];
    icons.plotOptions = [iconDir,'reficon.gif'];
    icons.extractPlot = [iconDir,'figureicon.gif'];
    icons.reloadData  = [iconDir,'tool_rotate_3d.gif'];
end

% plot options button
optionsButton = lCreateButton(...
    icons.plotOptions, ...
    'Plot options', ...
    @lOptionsButtonCallback);

% plot button
plotButton = lCreateButton(...
    icons.extractPlot, ...
    'Extract current plot into new figure window', ...
    @lPlotButtonCallback);

% reload button
reloadButton = lCreateButton(...
    icons.reloadData, ...
    'Reload logged data', ...
    @lReloadButtonCallback);

% create panel for button and add buttons to the panel
buttonPanel = javax.swing.JPanel;
buttonPanel.setLayout(java.awt.FlowLayout(java.awt.FlowLayout.LEFT));
buttonPanel.setBorder(javax.swing.border.EtchedBorder());
buttonPanel.add(optionsButton);
buttonPanel.add(plotButton);
buttonPanel.add(reloadButton);

end

function statusPanel = lCreateStatusPanel(node)
% Create status panel

% create status text
label = javax.swing.JLabel;
label.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);

% create location text
label1 = javax.swing.JLabel;
label1.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);

% create the status panel and add status/location 
statusPanel = javax.swing.JPanel;
statusPanel.setLayout(java.awt.BorderLayout());
statusPanel.setBorder( ...
    javax.swing.border.CompoundBorder( ...
        javax.swing.border.EtchedBorder(), ...
        javax.swing.border.EmptyBorder(5,5,5,5)));

statusPanel.add(label,java.awt.BorderLayout.NORTH);
statusPanel.add(label1,java.awt.BorderLayout.SOUTH);

% update status panel
lUpdateStatusPanel(statusPanel, node, {node});

end

function lUpdateStatusPanel(statusPanel, rootNode, selectedNodes)
% Display info about selected nodes
if isempty(selectedNodes)  % no nodes were selected
    statusStr = 'No node selected';
    locationStr = '';
    locationTip = '';
    locationCallback = '';
elseif numel(selectedNodes) == 1  % single node was selected
    node = selectedNodes{1};
    printStatusFcn = lGetNodeDisplayOption(node,'PrintStatusFcn',@lPrintStatus);
    statusStr = printStatusFcn(selectedNodes);

    printLocationFcn = lGetNodeDisplayOption(node,'PrintLocationFcn',@lPrintLocation);
    [locationStr,locationTip,locationCallback] = printLocationFcn(node);

else   % multiple nodes selected - use generic print function
    statusStr = lPrintStatus(selectedNodes,rootNode);
    locationStr = '';
    locationTip = '';
    locationCallback = '';
end

statusLabel = statusPanel.getComponent(0);
statusLabel.setText(statusStr);
statusLabel.setToolTipText(statusStr);

locationLabel = statusPanel.getComponent(1);
locationLabel.setText(locationStr);
locationLabel.setToolTipText(locationTip);

labelHandle = handle(locationLabel, 'callbackproperties');
if isempty(locationCallback) 
    set(labelHandle, 'MouseClickedCallback',[]);
else
    set(labelHandle, 'MouseClickedCallback', @(src,evt) feval(locationCallback));
end
end

function str = lPrintStatus(selectedNodes,rootNode)
% String for the status panel
assert( (numel(selectedNodes) == 1) || (nargin > 1));

isMultiSelected = (numel(selectedNodes) > 1);
if isMultiSelected
    node = rootNode;
    statusTitle = 'Statistics for root node:';
else
    node = selectedNodes{1};
    statusTitle = 'Statistics for selected node:';
end

% isVariable = hasValidUnit && ~isZCsignal
% Note: zcSignals are tagged {'ZeroCrossing','SignalCrossings' | 'SignalValues'}
hasValidUnit  = @(n) ~strcmpi(n.series.unit, 'invalid');
isZCSignal = @(n) n.hasTag('ZeroCrossing');

isVariable = @(x)( hasValidUnit(x{end}) && ~isZCSignal(x{end}));

% isZC = tagged: {'SimulationStatistics','ZeroCrossing'}
hasZCTag = @(n) lHasTagValue(n,'SimulationStatistics','ZeroCrossing');
isZC = @(x)( hasZCTag(x{end}));

loggedVariables = node.find(isVariable);
loggedZeroCrossings = node.find(isZC);

if ~isempty(loggedVariables)
    numPoints = loggedVariables{1}.series.points;
elseif ~isempty(loggedZeroCrossings)
    numPoints = loggedZeroCrossings{1}.values.series.points;
else
    numPoints = NaN;
end

str = sprintf(['<html>%s<br/>' ...
    'id: %s<br/>' ...
    'Number of time steps: %d<br/>' ...
    'Number of logged variables: %d<br/>' ...
    'Number of logged zero crossing signals: %d</html>'], ...
    statusTitle, node.id, numPoints, ...
    numel(loggedVariables), ...
    numel(loggedZeroCrossings));
end


function [str,tip,cbck] = lPrintLocation(node) %#ok<INUSD>
% Strings for updating the location section of node status panel
str = ''; tip = ''; cbck = '';
end

% ============== callback functions ==============

function lHgTreeSelectionCallback(src, evd, tree, selfcn) %#ok<INUSL>
% hg callback for tree selection
cbk = selfcn;
hgfeval(cbk, tree, evd);

end

function lTreeSelectionCallback(tree, node) %#ok<INUSD>
% Callback for when tree selection changes

% get figure handle
figureClient = tree.getScrollPane.getParent.getParent.getParent;
hFigure = getfigurefordesktopclient(figureClient);

% call plot
lPlot(hFigure)

end

function lOptionsButtonCallback(src, evt) %#ok<INUSD>
% Callback for when options button is clicked

% get figure handle
figureClient = src.getParent.getParent.getParent.getParent;
hFigure = getfigurefordesktopclient(figureClient);

% create options dialog
lCreateOptionsDialog(hFigure)
end

function lPlotButtonCallback(src,evt) %#ok<INUSD>
% Callback for when plot button is clicked

% get figure handle
figureClient = src.getParent.getParent.getParent.getParent;
hFigure = getfigurefordesktopclient(figureClient);

% create a new figure and call plot
newFigure = figure;
lPlot(hFigure, newFigure);

end

function lReloadButtonCallback(src, evt) %#ok<INUSD>
% Callback for when the reload button is clicked

% get figure handle
figureClient = src.getParent.getParent.getParent.getParent;
hFigure = getfigurefordesktopclient(figureClient);
ud = get(hFigure, 'UserData');

% create input dialog
varName = inputdlg({'Specify variable name containing new logged data:'}, ...
    sprintf('Reload data: %s', ud.node.id), 1, {ud.inputName});
errorDialogTitle = 'Load error';
errorString = 'Unable to reload data:';
if ~isempty(varName)
    varName = varName{1};
    if ~isvarname(varName)
        str = sprintf('%s\n''%s'' is not a valid variable name.', ...
            errorString, varName);
        errordlg(str, errorDialogTitle, 'modal');
        return;
    end
    if ~evalin('base', sprintf('exist(''%s'')', varName))
        str = sprintf('%s\nVariable ''%s'' does not exist in the base workspace.', ...
            errorString, varName);
        errordlg(str, errorDialogTitle, 'modal');
        return;
    end
    logVar = evalin('base', varName);
    if ~isa(logVar, 'simscape.logging.Node')
        str = sprintf('%s\n''%s'' is not a Simscape logged variable.', ...
            errorString, varName);
        errordlg(str, errorDialogTitle, 'modal');
        return;
    else
        loggedNode = ud.node;
        if ~lAreNodesEquivalent(logVar, loggedNode)
            str = sprintf(['%s\nThe current logged node is not equivalent '...
                'to the logged node specified by ''%s'' variable.'], ...
                errorString, varName);
            errordlg(str, errorDialogTitle, 'modal');
            return;
        end
        ud.node = logVar;
        ud.inputName = varName;
        set(hFigure, 'UserData', ud);
        lPlot(hFigure);
    end
end


end

% ============== plotting functions ==============

function lPlot(explorerFigureHandle, plotFigureHandle)
% plot data on plotFigureHandle given explorerFigureHandle

% extract node, tree, options from explorer figure handle
ud = get(explorerFigureHandle, 'UserData');
tree = ud.tree;
loggedNode = ud.node;
options = ud.options;

% get buttons from main panel
panels = ud.navPanel.getComponents;
buttons = panels(1).getComponents;

% disable buttons before plot
lEnableButtons(buttons, false);

% enable buttons after plot using onCleanup
buttonCleanup = onCleanup(@()(lEnableButtons(buttons, true)));

% validate selection - this will change selection if invalid nodes are
% selected.
lValidateTreeSelection(tree, loggedNode);

% get selected nodes after validation since validation may change selected
% nodes
[nodes, paths, labels] = lGetSelectedNodes(tree, loggedNode);

% if figure handle for plotting isn't provided then plot in the explorer
% figure
if nargin == 1
    plotFigureHandle = explorerFigureHandle;
end

% update status panel
statusPanel = ud.navPanel.getComponent(2);
lUpdateStatusPanel(statusPanel, loggedNode, nodes);

% call plot
lPlotOnFigure(plotFigureHandle, nodes, paths, labels, options);

end

function [nodesToPlot,pathsToPlot,labelsToPlot,optionsToPlot] = lProcessSelectedNodes(nodes,paths,labels,options)
% This function is called either for a single node or for several uniform ones.
node = nodes{1};
fcn = lGetNodeDisplayOption(node,'GetNodesToPlotFcn',@lFindNodesToPlot);

[nodesToPlot,pathsToPlot,labelsToPlot,optionsToPlot] = fcn(nodes,paths,labels,options);
end

function fcn = lGetPlotFcn(node)
% function for plotting data associated with node
fcn = lGetNodeDisplayOption(node,'PlotNodeFcn','');

% resort to the default (for terminal nodes only)
if isempty(fcn) && (node.numChildren == 0)
    fcn = @lPlotNodes;
end
end

function [nodesToPlot,pathsToPlot,labelsToPlot,optionsToPlot] = lFindNodesToPlot(nodes,paths,labels,options)
% if the first node is non-terminal then plot all children that have logged
% data otherwise plot all nodes.
nodesToPlot = {};
pathsToPlot = {};
labelsToPlot = {};
optionsToPlot = options;
if nodes{1}.numChildren > 0
    childIds = sort(nodes{1}.childIds);
    for idx = 1:numel(childIds)
        childNode = nodes{1}.child(childIds{idx});
        isPlotted = (childNode.numChildren == 0);  % always plot terminal nodes
        if lGetNodeDisplayOption(childNode,'IsPlottedByParent',isPlotted);
            nodesToPlot{end+1} = childNode; %#ok<AGROW>
            pathsToPlot{end+1} = sprintf('%s.%s',paths{1},childIds{idx});%#ok<AGROW>
            labelsToPlot{end+1} = childNode.id; %#ok<AGROW>
        end
    end
else
    % Preserve nodes, paths, and labels
    nodesToPlot = nodes;
    pathsToPlot = paths;
    labelsToPlot = labels;
end
end


function [groupIdx,unitsToPlot,fcnsToPlot] = lGroupNodesForPlotting(allNodes)
% groupped by plotFcn, then unit (commensurate to a unique set!)
allPlotFcns = cellfun(@(n) func2str(lGetPlotFcn(n)),allNodes,'UniformOutput', false);

% get raw units for all logged data
allUnits = cellfun(@(n)(n.series.unit),allNodes,'UniformOutput', false);

% handle unitless and unitted nodes differently because unitless
% and angular units are both commensurate but we don't want to plot
% them in the same group
unitless = strcmp(allUnits, '1');
nonterminal = strcmp(allUnits, 'INVALID');

allUnits = strrep(allUnits, 'INVALID', '1');  % valid unit for plotting

% map units to commensurate set
unittedIdx = find(~(unitless | nonterminal));
if ~isempty(unittedIdx)
    unittedUnits = allUnits(unittedIdx);
    baseUnits = lUniqueCommensurateUnits(unittedUnits);
    commensurateMatrix = pm_commensurate(baseUnits, unittedUnits);
    for i = 1:size(commensurateMatrix,2)
        allUnits{unittedIdx(i)} = baseUnits{commensurateMatrix(:,i)};
    end
end

% determine the grouping
uniqueFcns = unique(allPlotFcns);
uniqueUnits = unique(allUnits);
groupIdx = zeros(1,numel(allNodes));
grp = 1;
for i = 1:numel(uniqueFcns)
    for j = 1:numel(uniqueUnits)
        idx = strcmp(allPlotFcns,uniqueFcns{i}) & ...
            strcmp(allUnits,uniqueUnits{j});
        if any(idx)
            groupIdx(idx) = grp;
            grp = grp + 1;
        end
    end
end
unitsToPlot = allUnits;
fcnsToPlot = allPlotFcns;
end

function lPlotOnFigure(hFigure, nodes, paths, labels, options)
% Plot given nodes on the given figure handle

% flush event queue
drawnow;

% delete all figure children (axes)
clf(hFigure);

% flush event queue again
drawnow;

if numel(nodes) == 0
    return;
end

% set handle visibility to 'on' so subplot and gca etc. point to this
% figure
hv = get(hFigure, 'HandleVisibility');
c = onCleanup(@()(set(hFigure, 'HandleVisibility', hv)));
set(hFigure, 'HandleVisibility', 'on');

% determine nodes to be plotted.
[nodesToPlot,pathsToPlot,labelsToPlot,optionsToPlot] = ...
    lProcessSelectedNodes(nodes,paths,labels,options);

numNodesToPlot = numel(nodesToPlot);
[~, multiSelection] = lGetMultiSelectOptions(optionsToPlot.multi);
[~, axisAlignmentSelection] = lGetAlignmentOptions(optionsToPlot.align);
axisAlignmentSelection = lower(axisAlignmentSelection);
switch lower(multiSelection)
    case 'separate'
        
        % number of subplot is the number of nodes to plot
        ax = zeros(1, numNodesToPlot);
        
        % iterate over all nodes to plot and plot them on a separate axis
        for idx = 1:numNodesToPlot
            switch axisAlignmentSelection
                case 'vertical'
                    ax(idx) = subplot(numNodesToPlot, 1, idx);
                case 'horizontal'
                    ax(idx) = subplot(1, numNodesToPlot, idx);
                otherwise
                    error('ssc_explore:InvalidAxisAlignment', ...
                        'Invalid selection for axis alignment option');
            end
            
            % get unit based on unit option
            unit = nodesToPlot{idx}.series.unit;
            if ~strcmp(unit, 'INVALID')
                unit = lGetUnit(unit, optionsToPlot.unit);
            end
            
            plotFcn = lGetPlotFcn(nodesToPlot{idx});
            plotFcn(nodesToPlot{idx}, ax(idx), optionsToPlot, unit, pathsToPlot(idx), labelsToPlot(idx));
        end
        
        % flush event queue
        drawnow;
        
        % link axes
        lLinkAxes(ax, optionsToPlot);
        
        % flush event queue
        drawnow;
        
    case 'overlay'
        
        % group nodes for plotting according to their plotFcn, then unit
        [groupIdx,unitsToPlot,functionsToPlot] = lGroupNodesForPlotting(nodesToPlot);
        
        numPlots = max(groupIdx);
        ax = zeros(1, numPlots);
        
        % iterate over groups of nodes (common plotFcn and unit)
        for idx = 1:numPlots
            switch axisAlignmentSelection
                case 'vertical'
                    ax(idx) = subplot(numPlots, 1, idx);
                case 'horizontal'
                    ax(idx) = subplot(1, numPlots, idx);
                otherwise
                    error('ssc_explore:InvalidAxisAlignment', ...
                        'Invalid selection for axis alignment option');
            end
            
            plotIdx = find(groupIdx == idx);
            nodes = nodesToPlot(plotIdx);
            unit = lGetUnit(unitsToPlot{plotIdx(1)},optionsToPlot.unit);
            plotFcn = str2func(functionsToPlot{plotIdx(1)});
            plotFcn(nodes, ax(idx), optionsToPlot, unit, pathsToPlot(plotIdx), labelsToPlot(plotIdx));
        end
        
        % flush event queue
        drawnow;
        
        % link axes
        lLinkAxes(ax, optionsToPlot);
        
        % flush event queue
        drawnow;
        
    otherwise
        error('ssc_explore:InvalidMultiSelection', ...
            'Invalid selection for multi selection option');
end

end

function lPlotNodes(nodes, ax, options, units, ~, labels)
% Plot the given nodes on the given axis

if ~iscell(nodes)
    nodes = {nodes};
end

time = nodes{1}.series.time;
allValuesToPlot = [];
legendEntries = {};

% iterate over all nodes and extract each dimension separately with the
% given unit
for idx = 1:numel(nodes)
    series = nodes{idx}.series;
    values = series.values(units);
    dim = series.dimension;
    numElements = dim(1)*dim(2);
    
    valuesToPlot = zeros(numel(time),numElements);
    for j = 1:dim(2)
        for i = 1:dim(1)
            idx2 = i+(j-1)*dim(1);
            valuesToPlot(:,idx2) = values(idx2:numElements:end);
            if dim(1)*dim(2) > 1
                legendEntries{end+1} = sprintf('%s(%d,%d)',labels{idx},i,j); %#ok<AGROW>
            else
                legendEntries{end+1} = sprintf('%s',labels{idx}); %#ok<AGROW>
            end
        end
    end
    allValuesToPlot = [allValuesToPlot valuesToPlot]; %#ok<AGROW>
end

% plot all values
plot(ax, time, allValuesToPlot, 'Marker', lMarker(options.marker));

% show legend if there is more than one entry or if the single entry
% contains a dot
[~, legendSelection] = lGetLegendOptions(options.legend);
switch lower(legendSelection)
    case 'auto'
        if numel(legendEntries) > 1
            legend(legendEntries, 'Interpreter', 'none');
        else
            if ~isempty(regexp(legendEntries{1}, '\.', 'once'))
                legend(legendEntries, 'Interpreter', 'none');
            end
        end
    case 'always'
        if ~isempty(legendEntries)
            legend(legendEntries, 'Interpreter', 'none');
        end
    case 'never'
        % nothing to do
end

% decorate
[~, multiSelection] = lGetMultiSelectOptions(options.multi);
switch lower(multiSelection)
    case 'separate'
        yLabelStr = sprintf('%s (%s)', nodes{1}.id, units);
        title(ax, nodes{1}.id, 'Interpreter', 'none');
    case 'overlay'
        if numel(nodes) == 1
            title(ax, nodes{1}.id, 'Interpreter', 'none');
            yLabelStr = sprintf('%s (%s)', nodes{1}.id, units);
        else
            yLabelStr = sprintf('%s', units);
        end
        
end
xlabel(ax, 'Time (s)', 'Interpreter', 'none');
ylabel(ax, yLabelStr, 'Interpreter', 'none');
grid(ax, 'on');

% limit time axis based on user preference
if options.time.limit
    set(ax, 'XLim', [options.time.start options.time.stop]);
end

end

function lLinkAxes(ax, options)
% link axes based on user option

if isempty(ax) || ~all(ishghandle(ax,'axes'))
    return;
end
if options.link.x && options.link.y
    linkaxes(ax, 'xy');
elseif options.link.x
    linkaxes(ax, 'x');
elseif options.link.y
    linkaxes(ax, 'y');
else
    linkaxes(ax, 'off');
end

end

function lEnableButtons(buttons, enable)
% Enable/Disable buttons

for idx = 1:numel(buttons)
    buttons(idx).setEnabled(enable);
end

end

% ============== tree utility functions ==============

function children = lSortChildIds(node)
% Sort Ids of children of simscape.logging.Node for display in java tree
if lHasTagValue(node,'SimulationStatistics','Statistics')
    % Sort ZC names {'zc_1','zc_11','zc_2'} -> {'zc_1','zc_2','zc_11'}
    zcIds = node.childIds;
    [~,idx] = sort(cellfun( @(c) eval(c(4:end)),zcIds));
    children = zcIds(idx);
else
    children = sort(node.childIds);
end
end

function treeLabel = lGetTreeNodeLabel(node,defaultLabel)
% Get label of simscape.logging.Node for display in java tree
defaultTreeLabel = @(n) defaultLabel;
fcn = lGetNodeDisplayOption(node,'TreeNodeLabelFcn',defaultTreeLabel);
treeLabel = fcn(node);
end

function treeIcon = lGetTreeNodeIcon(node,defaultIcon)
% Get icon for simscape.logging.Node for display in java tree
treeIcon = lGetNodeDisplayOption(node,'TreeNodeIcon',defaultIcon);
end

function treeNode = lCreateTreeNode(node,icons)
% Create a node in java tree from simscape.logging.Node object
isTerminal = (node.numChildren == 0);
if isTerminal
    defaultIcon = icons.terminalNode;
else
    defaultIcon = icons.nonTerminalNode;
end
treeIcon = lGetTreeNodeIcon(node,defaultIcon);
defaultLabel = node.id;
treeLabel = lGetTreeNodeLabel(node,defaultLabel);
treeNode = uitreenode('v0', node.id, treeLabel, treeIcon, isTerminal);
end

function lPopulateTree(parentTreeNode, loggingNode, icons)
% Walk the node hierarchy and populate the tree

% recursively walk children and populate the parent
children = lSortChildIds(loggingNode);
for idx = 1:numel(children)
    childNode = loggingNode.child(children{idx});
    treeNode = lCreateTreeNode(childNode,icons);
    if childNode.numChildren > 0
        lPopulateTree(treeNode, childNode, icons);
    end
    parentTreeNode.add(treeNode);
end
end

function name = lGetNameFromTreeNode(n)
% Get node name from tree
name = strtok(char(n.getName));
end

function nodePath = lNodePathFromTreePath(p)
% Get node path from tree
nodePath = '';
for idx = 2:numel(p)-1
    nodePath = [nodePath lGetNameFromTreeNode(p(idx)) '.']; %#ok<AGROW>
end
if numel(p) > 1
    nodePath = [nodePath lGetNameFromTreeNode(p(end))];
end
end

function lValidateTreeSelection(tree, loggedNode)
% Validate tree selection

% get selected nodes
selectedTreeNodes = tree.getSelectedNodes;

% get selected paths
selectionPaths = tree.getTree.getSelectionPaths;

assert(numel(selectedTreeNodes) == numel(selectionPaths), ...
    'Number of selected tree nodes doesn''t match number of selection paths');

numSelected = numel(selectedTreeNodes);
if numSelected == 0
    return;
end
selectedNodes{1} = loggedNode.node(...
    lNodePathFromTreePath(selectedTreeNodes(1).getPath()));

s = tree.getTree().getSelectionModel();

pathsToRemove = selectionPaths;

% don't remove the first node
pathsToRemove(1) = [];

% if the first node is non-terminal, remove all nodes otherwise remove
% nodes that are non-terminal. Basically we don't want to allow multi
% selection for a mix of terminal or non-terminal nodes. Selected nodes
% should be terminal or only a single non-terminal node should be selected.
if (selectedNodes{1}.numChildren == 0)
    for idx = 2:numSelected
        nodePath = lNodePathFromTreePath(selectedTreeNodes(idx).getPath());
        n = loggedNode.node(nodePath);
        if n.numChildren == 0
            pathsToRemove(idx) = [];
        end
    end
end
if numSelected > 1
    javaMethodEDT('removeSelectionPaths', s, pathsToRemove);
end
end

function [selectedNodes, nodePaths, labels] = lGetSelectedNodes(tree, loggedNode)
% get a cell array of selected simscape.logging.Node objects along with
% their dot-delimited paths and legend labels

selectedTreeNodes = tree.getSelectedNodes;
selectionPaths = tree.getTree.getSelectionPaths;
assert(numel(selectedTreeNodes) == numel(selectionPaths), ...
    'Number of selected tree nodes doesn''t match number of selection paths');

numSelected = numel(selectedTreeNodes);
selectedNodes = cell(1, numSelected);
nodePaths = cell(1, numSelected);

for idx = 1:numSelected
    nodePaths{idx} = ...
        lNodePathFromTreePath(selectedTreeNodes(idx).getPath());
    selectedNodes{idx} = loggedNode.node(nodePaths{idx});
end

[~, sortIdx] = sort(nodePaths);
selectedNodes = selectedNodes(sortIdx);
nodePaths = nodePaths(sortIdx);
ids = cellfun(@(x)(x.id), selectedNodes, 'UniformOutput', false);
labels = ids;
uniqueIds = unique(ids);
if numel(uniqueIds) ~= numel(ids)
    for idx = 1:numel(uniqueIds)
        i = strcmp(ids, uniqueIds{idx});
        if numel(find(i)) > 1
            labels(i) = nodePaths(i);
        end
    end
    
end
end

function units = lUniqueCommensurateUnits(units)
% Find unique set of commensurate units

if ~iscell(units)
    units = {units};
end
c = pm_commensurate(units, units);
c = triu(c);
keep = false(1, numel(units));
for idx = 1:numel(units)
    col = c(:,idx);
    keep(idx) = ~any(find(col)<idx);
end
units = units(keep);
end

% ============== Node utility functions ==============

function res = lHasTagValue(node,name,value)
% Return true if node has the given tag set to the value
res = node.hasTag(name) && all(strcmp(node.getTag(name),{name,value}));
end

function result = lAreNodesEquivalent(n1, n2)
% Return true if two nodes are equivalent.

% Two nodes are considered equivalent if and only if
% 1. their series are equivalent and
% 2. they have same set of children and
% 3. their children are equivalent

% not equivalent by default
result = false;

% check if series are equivalent
if ~lAreSeriesEquivalent(n1.series, n2.series)
    return;
end

% check if the two nodes have same set of children
node1Children = sort(n1.childIds);
node2Children = sort(n2.childIds);
if ~isequal(node1Children, node2Children)
    return;
end

% for each child, call this function on <child1, child2> 2-tuple where
% child1 is the child for the first node and child2 is the child for second
% node
for idx = 1:numel(node1Children)
    child1 = n1.child(node1Children{idx});
    child2 = n2.child(node2Children{idx});
    if ~lAreNodesEquivalent(child1,child2);
        return;
    end
end
% no early return; n1 and n2 must be equivalent.
result = true;
end

function result = lAreSeriesEquivalent(s1, s2)
% Return true if two series are equivalent.

% Two series are equivalent if and only if
% 1. they have commensurate units and
% 2. they have same dimension
% or
% 3. they are empty

unit1 = s1.unit;
unit2 = s2.unit;

if strcmp(unit1, 'INVALID');
    result = strcmp(unit2, unit1);
else
    dim1 = s1.dimension;
    dim2 = s2.dimension;
    result = pm_commensurate(unit1,unit2) && isequal(dim1,dim2);
end

end

% ============== GUI functions ==============

function button = lCreateButton(iconFile, tooltip, cbFcn)
% Create a JButton given icon file, tool tip and callback function
icon = javax.swing.ImageIcon(iconFile);
button = javaObjectEDT('javax.swing.JButton');
button.setIcon(icon);
button.setToolTipText(tooltip);
button.setPreferredSize(java.awt.Dimension(25, 25));
buttonHandle = handle(button, 'callbackproperties');
set(buttonHandle, 'ActionPerformedCallback', cbFcn);
end

function lCreateOptionsDialog(hFigure)
% Create options dialog
ud = get(hFigure, 'UserData');
options = ud.options;

[~, marker] = lMarker(1);
multiSelectionStrings =  lGetMultiSelectOptions();
alignmentStrings = lGetAlignmentOptions();
legendStrings = lGetLegendOptions();
unitStrings = lGetUnitOptions();

% create a empty frame and get the color so that we render HG GUI in the
% same color scheme as java.
jframe = javax.swing.JFrame();
jframeColor = jframe.getBackground();
backgroundColor = ...
    [jframeColor.getRed(), jframeColor.getGreen(), jframeColor.getBlue()]/255;

explorerPosition = get(hFigure, 'Position');

% create options dialog
guiHandle = figure('Name', sprintf('Options: %s', ud.node.id),...
    'NumberTitle', 'off', ...
    'Resize', 'on', ...
    'MenuBar', 'none', ...
    'Position', explorerPosition, ...
    'Toolbar','none', 'Color', backgroundColor , ...
    'Visible', 'off', 'units', 'pixels', ...
    'WindowStyle', 'modal');

% set position
set(guiHandle, 'units', 'characters');
position = get(guiHandle, 'position');
set(guiHandle, 'Position', [position(1) position(2)+10 40 26]);

% set explorer window as user data
set(guiHandle, 'UserData', hFigure);

% add widgets
axisOptionsPanel = uipanel('parent', guiHandle, 'visible', 'on', ...
    'units', 'characters', 'Position' ,[1 26-9.25 38 9], ...
    'Title', 'Axes control', 'backgroundcolor', backgroundColor);

timeCheck = uicontrol(axisOptionsPanel, 'Style', 'checkbox', ...
    'String', 'Limit time axis', ...
    'Value', options.time.limit, 'units', 'characters', ...
    'Position', [1 6.5 20 1], 'BackgroundColor', backgroundColor);

timeStartText = uicontrol('parent', axisOptionsPanel, 'Style', 'text', ...
    'String', 'Start time:', 'BackgroundColor', backgroundColor, ...
    'HorizontalAlignment', 'Left', ...
    'units', 'characters', 'Position', [5 5 11 1],...
    'Enable', lEnableString(options.time.limit));
timeStartEdit = uicontrol('parent', axisOptionsPanel, 'Style', 'edit', ...
    'String', num2str(options.time.start), 'BackgroundColor', 'white', ...
    'units', 'characters', 'Position', [17 4.75 19 1.5],...
    'HorizontalAlignment', 'right', ...
    'Enable', lEnableString(options.time.limit));
timeStopText = uicontrol('parent', axisOptionsPanel, 'Style', 'text', ...
    'String', 'Stop time:', 'BackgroundColor', backgroundColor, ...
    'HorizontalAlignment', 'Left', ...
    'units', 'characters', 'Position', [5 3 11 1],...
    'Enable', lEnableString(options.time.limit));
timeStopEdit = uicontrol('parent', axisOptionsPanel, 'Style', 'edit', ...
    'String', num2str(options.time.stop), 'BackgroundColor', 'white', ...
    'units', 'characters', 'Position', [17 2.75 19 1.5],...
    'HorizontalAlignment', 'right', ...
    'Enable', lEnableString(options.time.limit));

linkXAxes = uicontrol(axisOptionsPanel, 'Style', 'checkbox', ...
    'String', 'Link x-axes', ...
    'Value', options.link.x, 'units', 'characters', ...
    'Position', [1 1.25 20 1], 'BackgroundColor', backgroundColor);

plotOptionsPanel = uipanel('parent', guiHandle, 'visible', 'on', ...
    'units', 'characters', 'Position' ,[1 26-22 38 12], ...
    'Title', 'Plot options', 'backgroundcolor', backgroundColor);

markerText = uicontrol(plotOptionsPanel, 'Style', 'text', ...
    'String', 'Marker type:', 'BackgroundColor', backgroundColor, ...
    'HorizontalAlignment', 'Left', ...
    'units', 'characters', 'Position', [1 9 15 1]); %#ok<NASGU>

markerPopup = uicontrol(plotOptionsPanel, 'Style', 'popupmenu', ...
    'String', marker, ...
    'Value', options.marker, ...
    'BackgroundColor','white', ...
    'units', 'characters', 'Position', [17 8.75 19 1.5]);

multiSelectText = uicontrol(plotOptionsPanel, 'Style', 'text', ...
    'String', 'Plot signals:', 'BackgroundColor',backgroundColor, ...
    'HorizontalAlignment', 'Left', ...
    'units', 'characters', 'Position', [1 7 15 1]); %#ok<NASGU>

multiSelectPopup = uicontrol(plotOptionsPanel, 'Style', 'popupmenu', ...
    'String', multiSelectionStrings, ...
    'Value', options.multi, ...
    'BackgroundColor', 'white', ...
    'units', 'characters', 'Position', [17 6.75 19 1.5]);

axisAlignmentText = uicontrol(plotOptionsPanel, 'Style', 'text', ...
    'String', 'Arrange plots:', 'BackgroundColor',backgroundColor, ...
    'HorizontalAlignment', 'Left', ...
    'units', 'characters', 'Position', [1 5 15 1]); %#ok<NASGU>

axisAlignmentPopup = uicontrol(plotOptionsPanel, 'Style', 'popupmenu', ...
    'String', alignmentStrings, ...
    'Value', options.align, ...
    'BackgroundColor', 'white', ...
    'units', 'characters', 'Position', [17 4.75 19 1.5]);

legendText = uicontrol(plotOptionsPanel, 'Style', 'text', ...
    'String', 'Show legend:', 'BackgroundColor',backgroundColor, ...
    'HorizontalAlignment', 'Left', ...
    'units', 'characters', 'Position', [1 3 15 1]); %#ok<NASGU>

legendPopup = uicontrol(plotOptionsPanel, 'Style', 'popupmenu', ...
    'String', legendStrings, ...
    'Value', options.legend, ...
    'BackgroundColor', 'white', ...
    'units', 'characters', 'Position', [17 2.75 19 1.5]);

unitsText = uicontrol(plotOptionsPanel, 'Style', 'text', ...
    'String', 'Units:', 'BackgroundColor',backgroundColor, ...
    'HorizontalAlignment', 'Left', ...
    'units', 'characters', 'Position', [1 1 15 1]); %#ok<NASGU>

unitsPopup = uicontrol(plotOptionsPanel, 'Style', 'popupmenu', ...
    'String', unitStrings, ...
    'Value', options.unit, ...
    'BackgroundColor', 'white', ...
    'units', 'characters', 'Position', [17 0.75 19 1.5]);

okButton = uicontrol(guiHandle, 'Style', 'pushbutton', ...
    'String', 'OK', ...
    'units', 'characters', 'Position', [8 1.25 10 1.5]);

cancelButton = uicontrol(guiHandle, 'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'units', 'characters', 'Position', [21 1.25 10 1.5]);

% set callbacks
set(okButton, 'Callback', @lOkCallback);
set(cancelButton, 'Callback', @lCancelCallback);
set(timeCheck, 'Callback', @lTimeCheckCallback);

% make gui visible
set(guiHandle, 'Visible', 'on');
set(axisOptionsPanel, 'visible', 'on');
set(plotOptionsPanel, 'visible', 'on');
movegui(guiHandle);

    function lTimeCheckCallback(hObject, evtData) %#ok<INUSD>
        % Callback to restrict time axes
        
        isEnabled = get(hObject,'Value') == get(hObject,'Max');
        set(timeStartText, 'Enable', lEnableString(isEnabled));
        set(timeStartEdit, 'Enable', lEnableString(isEnabled));
        set(timeStopText, 'Enable', lEnableString(isEnabled));
        set(timeStopEdit, 'Enable', lEnableString(isEnabled));
    end

    function lOkCallback(hObject, evtData) %#ok<INUSD>
        % Callback for OK button
        
        % get data from the options GUI
        options.time.limit = get(timeCheck, 'Value');
        options.time.start = str2double(get(timeStartEdit, 'String'));
        options.time.stop = str2double(get(timeStopEdit, 'String'));
        
        options.link.x = get(linkXAxes, 'Value');
        
        options.marker = get(markerPopup, 'Value');
        options.multi = get(multiSelectPopup, 'Value');
        options.align = get(axisAlignmentPopup, 'Value');
        options.legend = get(legendPopup, 'Value');
        options.unit = get(unitsPopup, 'Value');
        if ~isnumeric(options.time.start) || ...
                isempty(options.time.start) || isnan(options.time.start)
            errordlg('Start time must be numeric and not NaN', ...
                'Options error');
            return;
        end
        
        if ~isnumeric(options.time.stop) || ...
                isempty(options.time.stop) || isnan(options.time.stop)
            errordlg('Stop time must be numeric and not NaN', ...
                'Options error');
            return;
        end
        
        if options.time.stop <= options.time.start
            errordlg('Stop time must be greater than Start time', ...
                'Options error');
            return;
        end
        
        % set data on the explorer user data
        hf = get(guiHandle, 'UserData');
        ud = get(hf, 'UserData');
        ud.options = options;
        set(hf, 'UserData', ud);
        
        % close options dialog
        close(guiHandle);
        
        % call plot
        lPlot(hFigure);
        
    end

    function lCancelCallback(hObject, evtData) %#ok<INUSD>
        % Callback for Cancel button
        
        % do nothing and close options dialog
        close(guiHandle);
    end

end

function [m, markers] = lMarker(idx)
% Get marker based on user choice

markers = {'None', '.', '*', 'o', '+', '^'};
m = markers{idx};
end

function [multiSelectOptions, selection] = lGetMultiSelectOptions(idx)
% Get options for multi selection

multiSelectOptions =  {'Separate', 'Overlay'};
if nargin == 0
    idx = 1;
end
selection = multiSelectOptions{idx};
end

function [alignmentOptions, selection] = lGetAlignmentOptions(idx)
% Get options for axis alignment

alignmentOptions = {'Vertical', 'Horizontal'};
if nargin == 0
    idx = 1;
end
selection = alignmentOptions{idx};
end

function [legendOptions, selection] = lGetLegendOptions(idx)
% Get options for legend

legendOptions = {'Auto', 'Always', 'Never'};
if nargin == 0
    idx = 1;
end
selection = legendOptions{idx};
end

function [unitOptions, selection] = lGetUnitOptions(idx)
% Get options for units

unitOptions = {'Default', 'SI', 'US Customary', 'Custom'};
if nargin == 0
    idx = 1;
end
selection = unitOptions{idx};
end

function s = lEnableString(v)
% Function to convert boolean to 'on'/'off' string

if v || strcmpi(v, 'on')
    s = 'on';
else
    s = 'off';
end
end

function u = lGetUnit(unit, option)
% Get unit from SI, US customary units, or custom units based on user
% selection

u = unit;
[~, unitSelection] = lGetUnitOptions(option);

if ~strcmpi(unitSelection, 'default')
    [siUnits, usUnits, customUnits] = lUnitDefinitions;
    switch lower(unitSelection)
        case 'si'
            units = siUnits;
        case 'us customary'
            units = usUnits;
        case 'custom'
            units = customUnits;
        otherwise
    end
    units = lGetValidUnits(units, unitSelection);
    unitIdx = pm_commensurate(unit, units);
    if any(unitIdx)
        u = units{unitIdx};
    end
end
end

function validUnits = lGetValidUnits(u, name)
% Remove invalid units, issue warning and get valid units

valid = pm_isunit(u);
invalidUnits = u(~valid);
validUnits = u(valid);
if ~isempty(invalidUnits)
    str = sprintf('''%s''', invalidUnits{1});
    for idx = 2:numel(invalidUnits)
        str = sprintf('%s, ''%s''', str, invalidUnits{idx});
    end
    w = warning('query', 'backtrace');
    warning('off', 'backtrace');
    c = onCleanup(@()(warning(w)));
    warning('ssc_explore:InvalidUnits', ...
        'The following %s units are not valid unit expressions: \n%s\n', ...
        name, str);
end
end

% ============== custom display options =========================

function label = lSimulationStatisticsTreeLabel(~)
% Node label for Java tree
label = 'SimulationStatistics (ZeroCrossings)';
end

function label = lZeroCrossingTreeLabel(node)
% Node label for Java tree
numCrossings = sum(node.crossings.series.values);
switch numCrossings
    case 0
        label = sprintf('%s - no crossings',node.id);
    case 1
        label = sprintf('%s - 1 crossing',node.id);
    otherwise
        label = sprintf('%s - %d crossings',node.id,numCrossings);
end
end

function str = lSimulationStatisticsPrintStatus(simulationStatisticsNode)
% String for the status panel
node = simulationStatisticsNode{1};
statusTitle = 'Statistics for selected node:';

% isZC = tagged: {'SimulationStatistics','ZeroCrossing'}
hasZCTag = @(n) lHasTagValue(n,'SimulationStatistics','ZeroCrossing');
isZC = @(x)( hasZCTag(x{end}));

loggedZeroCrossings = node.find(isZC);

if ~isempty(loggedZeroCrossings)
    numPoints = loggedZeroCrossings{1}.values.series.points;
    
    countCrossings = @(n) sum(n.crossings.series.values());
    numCrossings = sum(cellfun(countCrossings,loggedZeroCrossings));
    
else
    numPoints = NaN;
    numCrossings = NaN;
end

str = sprintf(['<html>%s<br/>' ...
    'id: %s<br/>' ...
    'Number of time steps: %d<br/>' ...
    'Number of logged zero crossing signals: %d<br/>' ...
    'Number of detected zero crossings: %d</html>'], ...
    statusTitle, node.id, numPoints, ...
    numel(loggedZeroCrossings), numCrossings);
end

function str = lZeroCrossingPrintStatus(zcNode)
% String for the status panel
str = lSimulationStatisticsPrintStatus(zcNode);
end

function str = lZeroCrossingCrossingsPrintStatus(zcCrossingsNode)
% String for the status panel
node = zcCrossingsNode{1};
statusTitle = 'Statistics for selected node:';
numPoints = node.series.points;
numCrossings = sum(node.series.values());

str = sprintf(['<html>%s<br/>' ...
    'id: %s<br/>' ...
    'Number of time steps: %d<br/>' ...
    'Number of detected zero crossings: %d</html>'], ...
    statusTitle, node.id, numPoints, numCrossings);
end

function str = lZeroCrossingValuesPrintStatus(zcValuesNode)
% String for the status panel
node = zcValuesNode{1};
statusTitle = 'Statistics for selected node:';
numPoints = node.series.points;

str = sprintf(['<html>%s<br/>' ...
    'id: %s<br/>' ...
    'Number of time steps: %d</html>'], ...
    statusTitle, node.id, numPoints);
end

function [str,tip,cbck] = lZeroCrossingPrintLocation(node)
% Strings for updating the location section of node status panel
    str = '';
    tip = '';
    cbck = '';

    key = 'ZeroCrossingLocation';
    if node.hasTag(key)

        tag = node.getTag(key);        
        fileLocation = tag{2}; % Encoded as 'module.package.fcn, line, col' or empty
        if ~isempty(fileLocation) 
            tokens =  textscan(fileLocation,'%s%d%d','Delimiter',','); 
            fileName = tokens{1}{1};
            fileRow = tokens{2};
            fileCol = tokens{3};
            
            if exist(which(fileName),'file')                
                str = sprintf('<html>Location: <a href="%s">%s</a></html>',fileName,fileName); 
                cbck = @() opentoline(which(fileName),fileRow,fileCol); 
            else
                str = sprintf('<html>Location: %s</html>',fileName); 
                cbck = '';    
            end
                
        else
            str = sprintf('<html>Location: %s</html>','(not available)');             
            cbck = '';                
        end        
        
        key = 'ZeroCrossingLocationMessage';
        if node.hasTag(key)
            tag = node.getTag(key);
            fullLocation = strrep(tag{2},'|','<br/>');
            tip = sprintf('<html>%s</html>',fullLocation);  
        end     
    end                
end

function [nodesToPlot,pathsToPlot,labelsToPlot,optionsToPlot] = lSimulationStatisticsNodesToPlot(nodes,paths,labels,options)
% Select 'SimulationStatistics' => send 'SimulationStatistics' to plot function
assert( numel(nodes) == 1 );

nodesToPlot = nodes;
pathsToPlot = paths;
labelsToPlot = labels;

optionsToPlot = options;

optionsToPlot.multi  = 1; % force separate
optionsToPlot.legend = 3; % suppress legend

end

function [nodesToPlot,pathsToPlot,labelsToPlot,optionsToPlot] = lZeroCrossingNodesToPlot(nodes,~,~,options)
% Select 'SimulationStatistics | zc_1' => send {zc_1.crossings,zc_1.values} to plot function
assert( numel(nodes) == 1 );
node = nodes{1};

nodesToPlot = {node.crossings,node.values};
pathsToPlot = {node.id,node.id};
labelsToPlot = {'crossings','values'};

optionsToPlot = options;

optionsToPlot.multi  = 1;  % force separate
optionsToPlot.legend = 3;  % suppress legend

end

function [tt,vv] = lPrepareCrossingDataForCummulativePlot(t,v)
% Compute cummulative sums, introduce extra points to get sharp corners, etc.
idx = find(v>0);
tstep = [t(1);(1-eps)*t(idx);t(idx)];
vstep = [v(1);zeros(size(idx));v(idx)];
[tt,idx] = sort(tstep);
vv = cumsum(vstep(idx));
vv = [vv(:); vv(end)]';
tt = [tt(:); t(end)]';
end

function lPlotSimulationStatistics(nodes, ax, options, ~, ~, ~)
% Plot OR-ed data from children zc_xx.crossings series
if ~iscell(nodes)
    nodes = {nodes};
end
assert(numel(nodes) == 1);
statisticsNode = nodes{1};

zcNodeIds = lSortChildIds(statisticsNode);

time = []; values = [];
for i = 1:numel(zcNodeIds)
    zcNode = statisticsNode.child(zcNodeIds{i});
    crossingNode = zcNode.crossings;
    if isempty(time)
        time = crossingNode.series.time;
    end
    if isempty(values)
        values = crossingNode.series.values;
    else
        values = values | crossingNode.series.values;
    end
end

% data for cummulative plot
[t,v] = lPrepareCrossingDataForCummulativePlot(time,values);

% plot all values
plot(ax, t, v, 'Marker', 'x');

% decorate
title(ax,'SimulationStatistics (ZeroCrossings)', 'Interpreter','none');
xlabel(ax, 'Time (s)', 'Interpreter', 'none');
ylabel(ax, 'all crossings (cummulative)', 'Interpreter', 'none');
grid(ax, 'on');

% limit time axis based on user preference
if options.time.limit
    set(ax, 'XLim', [options.time.start options.time.stop]);
end

end


function lPlotZCSignal(ax,nodes,paths,labels,options,marker,ylab,dataFcn)
% Plot data from {zc_xx}.crossings or {zc_xx}.values nodes; separate lines
if ~iscell(nodes)
    nodes = {nodes};
end

colors = get(gca,'ColorOrder');
numColors = size(colors,1);
for i = 1:numel(nodes)
    node = nodes{i};
    [t,v] = dataFcn(node.series.time,node.series.values);
    colorIdx = 1 + mod(i-1,numColors);
    plot(ax, t, v, 'Marker', marker, 'Color', colors(colorIdx,:));
    hold(ax,'on');
end
hold(ax,'off');

% legend
[~, legendSelection] = lGetLegendOptions(options.legend);
if numel(labels) == 1 && isempty(regexp(labels{1}, '\.', 'once'))
    legendEntries = paths;
else
    legendEntries = labels;
end
legendEntries = strrep(strrep(strrep(legendEntries,...
    '.SimulationStatistics',''),...
    '.values',''),...
    '.crossings','');

switch lower(legendSelection)
    case {'auto','always'}
        if ~isempty(legendEntries)
            legend(legendEntries, 'Interpreter', 'none');
        end
    case 'never'
        % nothing to do
end

% decorate
title(ax,'SimulationStatistics (ZeroCrossings)', 'Interpreter','none');
xlabel(ax, 'Time (s)', 'Interpreter', 'none');
ylabel(ax, ylab, 'Interpreter', 'none');
grid(ax, 'on');

% limit time axis based on user preference
if options.time.limit
    set(ax, 'XLim', [options.time.start options.time.stop]);
end

end


function lPlotSignalCrossings(nodes, ax, options, ~, paths, labels)
% Plot data from {zc_xx}.crossings nodes; separate lines
marker = lMarker(options.marker);
if strcmpi(marker,'none')
    marker = 'x';
end
lPlotZCSignal(ax,nodes,paths,labels,options,marker,'crossings (cummulative)',...
    @lPrepareCrossingDataForCummulativePlot);
end

function lPlotSignalValues(nodes, ax, options, ~, paths, labels)
% Plot data from {zc_xx}.values nodes; separate lines
marker = lMarker(options.marker);
lPlotZCSignal(ax,nodes,paths,labels,options,marker,'values',@deal);
end


function res = lGetNodeDisplayOption(node,name,default)
% Custom display options for tagged nodes
persistent DATA_MAP
if isempty(DATA_MAP)
    % Validate icons
    iconDir = [matlabroot, '/toolbox/physmod/logging/resources/icons/'];
    if exist(iconDir,'dir');
        icons.statistics = [iconDir,'statistics.png'];
        icons.zeroCrossing = [iconDir,'zero_crossing.png'];
        icons.signalCrossings = [iconDir,'zc_crossings.png'];
        icons.signalValues = [iconDir,'zc_values.png'];
    else
        iconDir = [matlabroot, '/toolbox/matlab/icons/'];
        icons.statistics = [iconDir,'profiler.gif'];
        icons.zeroCrossing = [iconDir,'pageicon.gif'];
        icons.signalCrossings = [iconDir,'greenarrowicon.gif'];
        icons.signalValues = [iconDir,'greenarrowicon.gif'];
    end
    
    % Initialize structure { { tagName, tagValue, struct(serviceName,value) }, ...}
    DATA_MAP = { ...
        {'SimulationStatistics', 'Statistics',...
        struct('TreeNodeIcon',      icons.statistics,...
        'TreeNodeLabelFcn',  @lSimulationStatisticsTreeLabel,...
        'PrintStatusFcn',    @lSimulationStatisticsPrintStatus,...
        'PrintLocationFcn',  '',...
        'IsPlottedByParent', true,...
        'GetNodesToPlotFcn', @lSimulationStatisticsNodesToPlot,...
        'PlotNodeFcn',       @lPlotSimulationStatistics)
        }, ...
        {'SimulationStatistics', 'ZeroCrossing',...
        struct('TreeNodeIcon',      icons.zeroCrossing,...
        'TreeNodeLabelFcn',  @lZeroCrossingTreeLabel,...
        'PrintStatusFcn',    @lZeroCrossingPrintStatus,...
        'PrintLocationFcn',  @lZeroCrossingPrintLocation,...
        'IsPlottedByParent', false,...
        'GetNodesToPlotFcn', @lZeroCrossingNodesToPlot,...
        'PlotNodeFcn',       '')
        }, ...
        {'ZeroCrossing', 'SignalCrossings',...
        struct('TreeNodeIcon',      icons.signalCrossings,...
        'TreeNodeLabelFcn',  '',...
        'PrintStatusFcn',    @lZeroCrossingCrossingsPrintStatus,...
        'PrintLocationFcn',  '',...
        'IsPlottedByParent', true,...
        'GetNodesToPlotFcn', '',...
        'PlotNodeFcn',       @lPlotSignalCrossings)
        }, ...
        {'ZeroCrossing', 'SignalValues',...
        struct('TreeNodeIcon',      icons.signalValues,...
        'TreeNodeLabelFcn',  '',...
        'PrintStatusFcn',    @lZeroCrossingValuesPrintStatus,...
        'PrintLocationFcn',  '',...
         'IsPlottedByParent', true,...
        'GetNodesToPlotFcn', '',...
        'PlotNodeFcn',       @lPlotSignalValues)
        }
        };
end

res = default;
for i = 1:numel(DATA_MAP)
    mapEntry = DATA_MAP{i};
    if lHasTagValue(node,mapEntry{1},mapEntry{2})
        res = mapEntry{3}.(name);
        if isempty(res)  % revert to default
            res = default;
        end
        break;
    end
end

end

% ============== user customizable functions ==============

function [siUnits, usUnits, customUnits] = lUnitDefinitions()

% SI units
siUnits = {'m/s', 'N', 'm', 'rad/s', 'rad', 'N*m', 'Pa', 'm^3/s', 'kg/s', ...
    'm^3', 'm^2/s', 'K', 'J', 'W', 'J/kg', 'J/(kg*K)', 'W/(m*K)', ...
    'W/(m^2*K)', 'kg/m^3', '1/K', 'rad/s^2', 'm^2', 'm/s^2'};

% US customary units
usUnits = {'ft/s', 'lbf', 'ft', 'rpm', 'rev', 'lbf*ft', 'psi', 'gpm', 'lbm/s', ...
    'gal', 'cSt', 'Fh', 'Btu', 'Btu/hr', 'Btu/lbm', 'Btu/(lbm*R)', 'Btu/(hr*ft*R)', ...
    'Btu/(hr*ft^2*R)', 'lbm/ft^3', '1/R', 'rev/s^2', 'in^2', 'ft/s^2'};

% Custom units
customUnits = {};

end

