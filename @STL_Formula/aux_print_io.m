function phi = aux_print_io(phi)
global BreachGlobOpt
    phi
    get_in_signal_names(phi)
    get_out_signal_names(phi)
    
    % Propagate recursively the input signals to sub-formulas
    switch(phi.type)
    
        case 'predicate'
        case 'not'
            phi.phi = aux_print_io(phi.phi);
        case 'or'
            phi.phi1 = aux_print_io(phi.phi1);        
            phi.phi2 = aux_print_io(phi.phi2);
        case 'and'
            phi.phi1 = aux_print_io(phi.phi1);        
            phi.phi2 = aux_print_io(phi.phi2);
        case 'andn'
            n_phi = numel(phi.phin);
            for i=1:n_phi
                phi.phin(i) = aux_print_io(phi.phin(i));
            end
        case '=>'
            phi.phi1 = aux_print_io(phi.phi1);        
            phi.phi2 = aux_print_io(phi.phi2);
        case 'always'
            phi.phi = aux_print_io(phi.phi);
        case 'av_eventually'
            phi.phi = aux_print_io(phi.phi);
        case 'eventually'
            phi.phi = aux_print_io(phi.phi);
        case 'until'
            phi.phi1 = aux_print_io(phi.phi1);        
            phi.phi2 = aux_print_io(phi.phi2);
    end
    
    % make sure the base formula gets updated with new parameters
    BreachGlobOpt.STLDB(phi.id) = phi;
end