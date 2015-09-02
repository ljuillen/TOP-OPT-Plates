import FEM.*
import opt.*
import plot.*

%% PROBLEM SELECTION
problem = 'a';

%% INITIALIZE GEOMETRY, MATERIAL, DESIGN VARIABLE
nelx = 40; nely = 10;       % number of plate elements 
dims.width = 1; dims.height = 1; dims.thickness = 1; % element's dimensions
element = FE('ACM', dims);  % build the finite element
material.E = 1000; material.v = 0.3;   % material properties
FrVol = 0.3;                % volume fraction at the optimum condition
x = ones(nely, nelx)*FrVol; % set uniform intial density

%% INITIALIZE NUMERICAL VARIABLES
CoPen = 3;                  % penalization coefficient used in the SIMP model
RaFil = 2;                  % filter radius

%% OPTIMIZATION CYCLE
tol = 1e-3;                 % tolerance for convergence criteria
change = 1;                 % density change in the plates (convergence)
changes = [];               % history of the density change (plot)
Cs = [];                    % history of the compliance (plot)
maxiter = 5;                % maximum number of iterations (convergence)
iter = 0;                   % iteration counter
[Kf, Ks] = getK(element, material); Ke = Kf + Ks;
while change > tol && iter < maxiter
    %% optimize
    U = FEM(problem, nelx, nely, element, material, x, CoPen); % solve FEM
    [dC, C] = getSensitivity(nelx, nely, element, x, CoPen, Ke, U);  % sensitivity analysis
    dC = filterSensitivity(nelx, nely, x, dC, RaFil);       % apply sensitivity filter
    xnew = OC(nelx, nely, x, FrVol, dC);                    % get new densities
    change = max(max(abs(xnew-x)));
    x = xnew;               % update densities
    iter = iter + 1;
    %% display results
    disp(['Iter: ' sprintf('%i', iter) ', Obj: ' sprintf('%.3f', C)...
        ', Vol. frac.: ' sprintf('%.3f', sum(sum(x))/(nelx*nely))]);
    Cs = cat(2, Cs, C);
    changes = cat(2, changes, change);
    plotConvergence(1:iter, Cs, 'c');
    plotConvergence(1:iter, changes, 'x');
    plotDesign(x);
end

%% DISPLAY DEFORMED CONFIGURATION
plotDeformed(nelx, nely, element, U);
