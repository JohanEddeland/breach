function [] = debug_print_io(phi)
global BreachGlobOpt
    phi
    get_in_signal_names(phi)
    get_out_signal_names(phi)
    
    % Propagate recursively the input signals to sub-formulas
    switch(phi.type)
    
        case 'predicate'
        case 'not'
            debug_print_io(phi.phi);
        case 'or'
            debug_print_io(phi.phi1);        
            debug_print_io(phi.phi2);
        case 'and'
            debug_print_io(phi.phi1);        
            debug_print_io(phi.phi2);
        case 'andn'
            n_phi = numel(phi.phin);
            for i=1:n_phi
                debug_print_io(phi.phin(i));
            end
        case '=>'
            debug_print_io(phi.phi1);        
            debug_print_io(phi.phi2);
        case 'always'
            debug_print_io(phi.phi);
        case 'av_eventually'
            debug_print_io(phi.phi);
        case 'eventually'
            debug_print_io(phi.phi);
        case 'until'
            debug_print_io(phi.phi1);        
            debug_print_io(phi.phi2);
    end
    
    % make sure the base formula gets updated with new parameters
    BreachGlobOpt.STLDB(phi.id) = phi;
end