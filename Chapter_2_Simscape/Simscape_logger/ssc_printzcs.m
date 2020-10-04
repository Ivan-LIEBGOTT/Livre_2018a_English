function ssc_printzcs(node,verbose)
%SSC_PRINTZCS  Display ZeroCrossings info logged by Simscape logger   
%   SSC_PRINTZCS(simlog) prints summary of ZeroCrossing events detected 
%   during simulation. SIMLOG is an object produced by the Simscape logger. 
%   Logging ZeroCrossing information requires setting the model parameter 
%   'SimscapeLogSimulationStatistics' to 'on'.
%   SSC_PRINTZCS(simlog,VERBOSE) controls the level of details displayed.
%   Supported values of VERBOSE:
%   -- 0 (default) -- block-level information 
%   -- 1 -- signal-level information
%   -- 2 -- signal-level information, including location information
%    
%   Example:
%       load_system(model);
%       set_param(model,'SimscapeLogType','all',...
%                       'SimscapeLogName','simlog',...
%                       'SimscapeLogSimulationStatistics','on');
%       sim(model);  % produces 'simlog' in base workspace
%       ssc_printzcs(simlog);
%     or     
%       ssc_printzcs(simlog,1);
%     or     
%       ssc_printzcs(simlog,2);
        
%   SSC_PRINTZCS expects the following data format:
%     model
%       subsystem
%         block
%           SimulationStatistics   (tag {'SimulationStatistics','Statistics'})
%             zc_0                 (tag {'SimulationStatistics','ZeroCrossing'}, 
%                                   tag {'ZeroCrossingLocationMessage','between line...'})
%               crossings (series) (tag {'ZeroCrossing','SignalCrossings'})
%               values    (series) (tag {'ZeroCrossing','SignalValues'})  
    
%   Copyright 2012 The MathWorks, Inc.
       
    if nargin < 1
        error('Unspecified argument NODE in ssc_printzcs(NODE)');
    elseif ~isa(node,'simscape.logging.Node')
        error('In ssc_printzcs(NODE), NODE must be a simscape.logging.Node');
    elseif nargin < 2
        verbose = 0;
    end
    
    switch verbose
      case 0
        visitor = @local_serialize_block_crossings;
      case 1
        visitor = @local_serialize_signal_crossings;        
      case 2
        visitor = @local_serialize_signal_crossings_locations;        
      otherwise
        error(['Unsupported value of VERBOSE (%d) ',...
               'in ssc_printzcs(node,VERBOSE)'],verbose);
    end

    % extract tree of nodes with SimulationStatistics
    tree = node.select(@(n) n{end}.hasTag('SimulationStatistics'));
    
    indent = ''; subIndent = '  ';
    str = local_visit_stats(tree,visitor,indent,subIndent);    
    fprintf('\n%s\n',str);
    
end

% ==============================================================================

function [str,num,numsig] = local_visit_stats(node,visitor,...
                                              indent,subindent)
% Depth-first traversal. Call VISITOR on SimulationStatistics nodes. 
% Bubble-up information from this node and all subnodes (recursively).

    num = 0; numsig = 0; str = '';
    ids = node.childIds();

    newind = [indent,subindent]; 
    newsubind = '| ';

    for i = 1:node.numChildren() 
        subnode = node.(ids{i});
        
        if subnode.hasTag('SimulationStatistics')   
            
            [s,n,nsig] = visitor(subnode,newind);            
        else        
            
            if i == node.numChildren()
                newsubind = '  ';
            end
                    
            [s,n,nsig] = local_visit_stats(subnode,visitor,newind,newsubind);     
        end                        
        
        num = num + n;
        numsig = numsig + nsig;        
        str = sprintf('%s%s',str,s);                    

    end

    if isempty(indent)
        label = sprintf('%s',node.id());
    else
        label = sprintf('%s+-%s',indent,node.id());
    end
    str = sprintf('%s (%d signals, %d crossings)\n%s',...
                  label,numsig,num,str);                  
end

% ------------------------------------------------------------------------------

function [s,n,nsig] = local_serialize_block_crossings(node,~)
% Serialize SimulationStatistics node - summary information only.
    s = ''; n = 0; nsig = node.numChildren();
    for zcs = node.childIds()
        zcid = zcs{1};
        nzc = sum(node.(zcid).crossings.series.values());
        n = n + nzc;
    end
end

% ------------------------------------------------------------------------------

function [s,n,nsig] = local_serialize_signal_crossings(node,indent)
% Serialize SimulationStatistics node - detailed signal information.    
    s = ''; n = 0; nsig = node.numChildren();  
    for zcs = local_sort_zc_ids(node.childIds())
        zcid = zcs{1};
        nzc = sum(node.(zcid).crossings.series.values());
        s = sprintf('%s%s-%s\t%3d\n',...
                    s,indent,local_norm_zcid(zcid),nzc);
        n = n + nzc;
    end
end

% ------------------------------------------------------------------------------

function [s,n,nsig] = local_serialize_signal_crossings_locations(node,indent)
% Serialize SimulationStatistics node - detailed signal information.    
    s = ''; n = 0; nsig = node.numChildren();  
    for zcs = local_sort_zc_ids(node.childIds())
        zcid = zcs{1};
        nzc = sum(node.(zcid).crossings.series.values());
        
        locations = local_zc_locations(node.(zcid));
        
        head_line  = sprintf('%s-%s\t%3d\tLocation:',...
                             indent,local_norm_zcid(zcid),nzc);        
        blank_head = sprintf('%s %s\t   \t   and   ',...
                             indent,local_norm_zcid(''));
        
        s = sprintf('%s%s%s\n',...
                    s,head_line,locations{1});                
        for i = 2:length(locations)
            s = sprintf('%s%s%s\n',...
                        s,blank_head,locations{i});        
        end
        
        n = n + nzc;
    end
end

% ------------------------------------------------------------------------------

function sortedIds = local_sort_zc_ids(zcIds)
% Sort ZC names {'zc_1','zc_11','zc_2'} -> {'zc_1','zc_2','zc_11'}    
    [~,idx] = sort(cellfun( @(c) eval(c(4:end)),zcIds));
    sortedIds = zcIds(idx);
end

% ------------------------------------------------------------------------------

function norm_zcid = local_norm_zcid(zcid)
% Append string with empty spaces to normalize its length to 5
% 'zc_1'  --> 'zc_1  ',
% 'zc_10' --> 'zc_10 '  
    req_length = 5;
    norm_zcid = [zcid,blanks(req_length-length(zcid))];
end

% ------------------------------------------------------------------------------

function locations = local_zc_locations(zcNode)
% Extract location from the 'ZeroCrossingLocationMessage' tag
    key = 'ZeroCrossingLocationMessage';
    assert( zcNode.hasTag(key));
    tag = zcNode.getTag(key);
    val = tag{2};
    str = strrep(val,matlabroot,'$MATLABROOT');    
    locations = textscan(str,'%s','Delimiter','|','Whitespace','');
    locations = locations{1};
end

% ==============================================================================
