function x = propogate_state_linear(model, x, n, dn)

    coeff = model.state; 

    if length(coeff) == 2 % 1st order
        a = coeff(1); 
        b = coeff(2); 
        m = dn; 
        x = x + a.*m; 
    elseif length(coeff) == 3 % 2nd order
        a = coeff(1); 
        b = coeff(2); 
        c = coeff(3); 
        m = dn; 
        % % https://www.symbolab.com/solver/step-by-step/expand%20%20a%5Cleft(n%2Bm%5Cright)%5E%7B2%7D%2Bb%5Cleft(n%2Bm%5Cright)%2Bc%20-%5Cleft(a%5Ccdot%5Cleft(n%5Cright)%5E%7B2%7D%2Bb%5Cleft(n%5Cright)%2B%2Bc%5Cright)%20?or=input
         x = x + a.*m.^2 + b.*m + 2.*n.*m.*a; 
        % x = x + m * (2*a*m + b); 
    elseif length(coeff) == 4 % 3rd order
        a = coeff(1); 
        b = coeff(2); 
        c = coeff(3); 
        d = coeff(4); 
        m = dn; 
        % https://www.symbolab.com/solver/step-by-step/expand%20%20a%5Ccdot%5Cleft(n%2Bm%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%2Bm%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%2Bm%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%2Bm%5Cright)%2Be%20-%5Cleft(a%5Ccdot%20%5Cleft(n%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%5Cright)%2Be%5Cright)%20?or=input
        x = x + ...
            a.*m.^3 + b.*m.^2 + c.*m + 3.*m.*a.*n.^2 + 3.*n.*a.*m.^2 + 2.*n.*m.*b; 
    elseif length(coeff) == 5 % 4th order
        a = coeff(1); 
        b = coeff(2); 
        c = coeff(3); 
        d = coeff(4); 
        e = coeff(5);
        m = dn; 
        % https://www.symbolab.com/solver/step-by-step/expand%20%20a%5Ccdot%5Cleft(n%2Bm%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%2Bm%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%2Bm%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%2Bm%5Cright)%2Be%20-%5Cleft(a%5Ccdot%20%5Cleft(n%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%5Cright)%2Be%5Cright)%20?or=input
        x = x + ...
            a.*m.^4 + b.*m.^3 + 4.*a.*n.*m.^3 + ...
            c.*m.^2 + 6.*a.*n.^2.*m.^2 + 3.*b.*n.*m.^2 + ...
            d.*m + 4.*a.*n.^3.*m + 3.*b.*n.^2.*m + ...
            2.*c.*n.*m; 


        % 5th order: 
        % https://www.symbolab.com/solver/step-by-step/expand%20a%5Ccdot%20%5Cleft(n%2Bm%5Cright)%5E%7B5%7D%2Bb%5Cleft(n%2Bm%5Cright)%5E%7B4%7D%2B%2Bc%5Cleft(n%2Bm%5Cright)%5E%7B3%7D%2Bd%5Cleft(n%2Bm%5Cright)%5E%7B2%7D%2Be%5Cleft(n%2Bm%5Cright)%2Bf%20-%5Cleft(a%5Ccdot%20%5Cleft(n%5Cright)%5E%7B5%7D%2Bb%5Cleft(n%5Cright)%5E%7B4%7D%2B%2Bc%5Cleft(n%5Cright)%5E%7B3%7D%2Bd%5Cleft(n%5Cright)%5E%7B2%7D%2Be%5Cleft(n%5Cright)%2Bf%5Cright)%20?or=input
    end

end