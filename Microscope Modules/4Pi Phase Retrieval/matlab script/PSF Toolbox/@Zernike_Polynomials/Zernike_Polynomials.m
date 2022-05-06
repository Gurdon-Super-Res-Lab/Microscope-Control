classdef Zernike_Polynomials < handle
% (C) Copyright 2015                Lidke Lab, Physcis and Astronomy,
%     All rights reserved           University of New Mexico, Albuquerque,NM, USA      
%
% Author: Michael Wester (7/1/2015)
% 
% This works with either the Wyant or Noll orderings (see Generate_PSF to see
% how each can be invoked).  This code is based on code originally provided by
% Sheng Liu and duplicates the results using the Wyant ordering.  The
% implementations are optimized for speed using purely Matlab code.
% 
% The Noll ordering produces the normalized polynomials defined in Noll's
% paper.
% 
% Robert J. Noll, ``Zernike polynomials and atmospheric turbulence'', Journal
% of the Optical Society of America, Volume 66, Number 3, March 1976.
% 
% James C. Wyant and Katherine Creath, _Applied Optics and Optical Engineering,
% Volume XI_, Academic Press, 1992.
%
% Note that in the Wyant ordering for a particular radial polynomial, the
% azimuthal factors
%    cos(m theta)   correspond to   m > 0
%    sin(m theta)                   m < 0
% with no factor for m = 0.  In the Noll ordering for a particular radial
% polynomial, the order of the azimuthal factors cos(m theta), sin(m theta)
% varies.  However, when computing the Zernike matrix, either directly via
% matrix_Z or implicitly via poly_sum, this technicality is ignored in the
% interest of speed.  Therefore, l_max should be defined so that both azimuthal
% terms (cos and sin) are included for a particular n and m to avoid
% inconsistencies.  Simply setting n_max via setN guarantees that l_max will be
% consistent.
%
% Also, m < 0 is not defined for the ordering in Noll's paper, but for the sake
% of consistency, here the azimuthal factors are defined in the same way as for
% Wyant (i.e., cos(m theta) corresponds to m > 0, sin(m theta) corresponds to
% m < 0).
%
% The functions indices_LtoNM, indices_NMtoL properly convert between l and
% (n, m) numbering schemes for the two orderings.  displayC displays the radial
% coefficients computed up through n_max.  n_Zernikes computes the total number
% of Zernike terms for a given n and the current ordering.
%
% Example usage:
%
%    Z = Zernike_Polynomials();
%
%    for i = 1 : 2
%
%       if i == 1
%          Z.Ordering = 'Wyant';
%       else
%          Z.Ordering = 'Noll';
%       end
%
%       Z.setN(5);
%       Z.initialize();
%       Z
%
%       Z.displayC();
%       fprintf('\n');
%
%       Z.setN(3);
%       nZ_terms = Z.n_Zernikes(3);
%
%       fprintf('%s: %f\n', Z.Ordering, Z.poly_sum(1, 1, 1));
%       fprintf('%s: %f\n', Z.Ordering, Z.poly_sum(2, 2, 1));
%       fprintf('%s: %f\n', Z.Ordering, Z.poly_sum(3, 3, 1));
%       fprintf('%s: %f\n', Z.Ordering, Z.poly_sum(4, 4, 1));
%       Z.poly_sum([1, 2; 3, 4], [1, 2; 3, 4], ones(2, 2), ones(1, nZ_terms))
%       Z.poly_sum([1, 2; 3, 4], [1, 2; 3, 4], ones(2, 2))
%       Z.poly_sum([1, 2; 3, 4], [1, 2; 3, 4])
%
%       ZM = Z.matrix_Z([1, 2; 3, 4], [1, 2; 3, 4]);
%       size(ZM)
%       sum(ZM, 3)
%
%    end
%
%    fprintf('\n');
%    l = Z.indices_WyantNMtoL(3, 2);
%    fprintf('l = %d\n', l);
%    [n, m] = Z.indices_WyantLtoNM(11);
%    fprintf('(n, m) = (%d, %d)\n', n, m);
%    l = Z.indices_WyantNMtoL(3, -2);
%    fprintf('l = %d\n', l);
%    [n, m] = Z.indices_WyantLtoNM(12);
%    fprintf('(n, m) = (%d, %d)\n', n, m);
%    l = Z.indices_WyantNMtoL(3, 0);
%    fprintf('l = %d\n', l);
%    [n, m] = Z.indices_WyantLtoNM(15);
%    fprintf('(n, m) = (%d, %d)\n', n, m);
%
%    fprintf('\n');
%    l = Z.indices_NollNMtoL(3, 3);
%    fprintf('l = %d\n', l);
%    [n, m] = Z.indices_NollLtoNM(10);
%    fprintf('(n, m) = (%d, %d)\n', n, m);
%    l = Z.indices_NollNMtoL(3, -3);
%    fprintf('l = %d\n', l);
%    [n, m] = Z.indices_NollLtoNM(9);
%    fprintf('(n, m) = (%d, %d)\n', n, m);
%    l = Z.indices_NollNMtoL(4, 0);
%    fprintf('l = %d\n', l);
%    [n, m] = Z.indices_NollLtoNM(11);
%    fprintf('(n, m) = (%d, %d)\n', n, m);

% =============================================================================
properties
% =============================================================================

   Ordering = 'Wyant';
   %Ordering = 'Noll';
   Nabserr = 1.0e-01;   Wabserr = 1.0e-01;
   Nrelerr = 1.0e-01;   Wrelerr = 1.0e-01;

   ZM = [];   % Z matrix

% =============================================================================
end % properties

properties(SetAccess = protected)
% =============================================================================

   Nnmax = -1;          Wnmax = -1;
   Nlmax = -1;          Wlmax = -1;
   NZc = [];            WZc = [];

% =============================================================================
end % properties(SetAccess = protected)

methods
% =============================================================================

% Set the Zernike Ordering ('Wyant' or 'Noll') to be used subsequently.
function set.Ordering(obj, Ordering)

   if strcmp(Ordering, 'Wyant') | strcmp(Ordering, 'Noll')
      obj.Ordering = Ordering;
   else
      error('Unknown ordering %s!', Ordering);
   end

end

% -----------------------------------------------------------------------------

% Precompute the Zernike polynomial coefficients for n = 0, ..., n_max.
function initialize(obj)

   if strcmp(obj.Ordering, 'Wyant')
      obj.initialize_Wyant();
   else
      obj.initialize_Noll();
   end

end

% -----------------------------------------------------------------------------

% Precompute the Zernike polynomial coefficients (Wyant ordering) for
%    n = 0, ..., n_max;   m = -n, ..., n
% The polynomials are numbered 0, 1, 2, ...
%
% If n is chosen so that n <= nmax always, this initialization only needs to be
% done exactly once.

function initialize_Wyant(obj)

   if obj.Wlmax == -1
      if obj.Wnmax == -1
         error('initialize_Wyant: Both lmax and nmax have not been defined!');
      else
         obj.Wlmax = (obj.Wnmax + 1)^2 - 1;
      end
   else
      % WARNING: Best that l_max is not defined by the user unless you really
      % know what you are doing---see the comments in poly_sum_Wyant.  If l_max
      % is defined, be sure that BOTH -m (sin factor) and m (cos factor) are
      % included for given n, abs(m).
      if obj.Wnmax == -1
         obj.Wnmax = ceil(sqrt(obj.Wlmax + 1) - 1);
      else
         l_max = (obj.Wnmax + 1)^2 - 1;
         if obj.Wlmax > l_max
            error( ...
      'initialize_Wyant: lmax (%d) too large to be generated by nmax (%d)!',...
                  obj.Wlmax, obj.Wnmax);
         end
      end
   end

   n_max = obj.Wnmax;

   % Zc{n + 1} contains the coefficients for the nth Zernike polynomial.  Note
   % that values of +/- m are the same, so only need to store them once, and
   % later, multiply them, respectively, by cos/sin of m*theta.
   obj.WZc = cell(1, n_max + 1);
   for n = 0 : n_max
      n1 = n + 1;
      obj.WZc{n1} = cell(1, n1);
      for m = 0 : n
         m1 = m + 1;
         % There are n - m + 1 terms in Z_n^m.
         obj.WZc{n1}{m1} = zeros(1, n - m + 1);
         for k = 0 : n - m
            k1 = k + 1;
            %obj.WZc{n1}{m1}(k1) = (-1)^k * factorial(2*n - m - k) / ...
            %   (factorial(k) * factorial(n - k) * factorial(n - m - k));
            obj.WZc{n1}{m1}(k1) = ...
               (-1)^k * prod(n - m - k + 1 : 2*n - m - k) / ...
                        (factorial(k) * factorial(n - k));
         end
      end
   end

end

% -----------------------------------------------------------------------------

% Precompute the Zernike polynomial coefficients (Noll ordering) for
%    n = 0, ..., n_max;   m = n mod 2, ..., n by 2 [floor(n/2) + 1 terms]
% The polynomials are numbered 1, 2, 3, ...
%
% If n is chosen so that n <= nmax always, this initialization only needs to be
% done exactly once.

function initialize_Noll(obj)

   if obj.Nlmax == -1
      if obj.Nnmax == -1
         error('initialize_Noll: Both lmax and nmax have not been defined!');
      else
         obj.Nlmax = (obj.Nnmax + 1) * (obj.Nnmax + 2) / 2;
      end
   else
      % WARNING: Best that l_max is not defined by the user unless you really
      % know what you are doing---see the comments in poly_sum_Noll.  If l_max
      % is defined, be sure that BOTH the sin factor and cos factor are
      % included for given n, m.
      if obj.Nnmax == -1
         obj.Nnmax = ceil((-3 + sqrt(1 + 8*obj.Nlmax)) / 2);
      else
         l_max = (obj.Nnmax + 1) * (obj.Nnmax + 2) / 2;
         if obj.Nlmax > l_max
            error( ...
      'initialize_Noll: lmax (%d) too large to be generated by nmax (%d)!', ...
                  obj.Nlmax, obj.Nnmax);
         end
      end
   end

   n_max = obj.Nnmax;

   sqrt_2 = sqrt(2);
   % Zc{n + 1} contains the coefficients for the nth Zernike polynomial.  Note
   % that for m > 0, there are two identical radial polynomials, so only need
   % to store them once, and later, multiply them, respectively, by cos/sin of
   % m*theta.
   obj.NZc = cell(1, n_max + 1);
   for n = 0 : n_max
      n1 = n + 1;
      obj.NZc{n1} = cell(1, n1);
      sqrt_np1   = sqrt(n + 1);
      sqrt_np1_2 = sqrt((n + 1) * 2);
      for m = mod(n, 2) : 2 : n
         m1 = m + 1;
         % There are (n - m)/2 + 1 terms in Z_n^m.
         obj.NZc{n1}{m1} = zeros(1, (n - m)/2 + 1);
         % Normalized by N as in Noll's paper.
         if m == 0   % N = sqrt(n + 1)
            N = sqrt_np1;
         else        % N = sqrt(n + 1) * sqrt(2)
            N = sqrt_np1_2;
         end
         for k = 0 : (n - m)/2
            k1 = k + 1;
            %obj.NZc{n1}{m1}(k1) = (-1)^k * factorial(n - k) / ...
            %   (factorial(k) * factorial((n + m)/2 - k)
            %                 * factorial((n - m)/2 - k));
            obj.NZc{n1}{m1}(k1) = N * ...
               (-1)^k * prod((n - m)/2 - k + 1 : n - k) / ...
                        (factorial(k) * factorial((n + m)/2 - k));
         end
      end
   end

end

% =============================================================================

% Number of Zernike polynomials up through order n.
function nZ = n_Zernikes(obj, n)

   if strcmp(obj.Ordering, 'Wyant')
      nZ = obj.n_Zernikes_Wyant(n);
   else
      nZ = obj.n_Zernikes_Noll(n);
   end

end

% -----------------------------------------------------------------------------

% Number of Zernike polynomials up through order n (Wyant ordering).
function nZ = n_Zernikes_Wyant(obj, n)

   nZ = (n + 1)^2;

end

% -----------------------------------------------------------------------------

% Number of Zernike polynomials up through order n (Noll ordering).
function nZ = n_Zernikes_Noll(obj, n)

   nZ = (n + 1) * (n + 2) / 2;

end

% =============================================================================

% Set nmax (and lmax).
function setN(obj, n)

   if strcmp(obj.Ordering, 'Wyant')
      obj.setN_Wyant(n);
   else
      obj.setN_Noll(n);
   end

end

% -----------------------------------------------------------------------------

% Set nmax (and lmax) for the Wyant ordering.
function setN_Wyant(obj, n)

   obj.Wnmax = n;
   obj.Wlmax = obj.n_Zernikes_Wyant(n) - 1;

end

% -----------------------------------------------------------------------------

% Set nmax (and lmax) for the Noll ordering.
function setN_Noll(obj, n)

   obj.Nnmax = n;
   obj.Nlmax = obj.n_Zernikes_Noll(n);

end

% =============================================================================

% Set lmax (and nmax).
function setL(obj, l)

   if strcmp(obj.Ordering, 'Wyant')
      obj.setL_Wyant(l);
   else
      obj.setL_Noll(l);
   end

end

% -----------------------------------------------------------------------------

% Set lmax (and nmax) for the Wyant ordering.
function setL_Wyant(obj, l)

   obj.Wlmax = l;
   obj.Wnmax = ceil(sqrt(l + 1) - 1);

end

% -----------------------------------------------------------------------------

% Set lmax (and nmax) for the Noll ordering.
function setL_Noll(obj, l)

   obj.Nlmax = l;
   obj.Nnmax = ceil((-3 + sqrt(1 + 8*l)) / 2);

end

% =============================================================================

% Display the Zernike coefficients up through order n.
function displayC(obj)

   if strcmp(obj.Ordering, 'Wyant')
      obj.displayC_Wyant();
   else
      obj.displayC_Noll();
   end

end

% -----------------------------------------------------------------------------

% Display the Zernike coefficients for the Wyant ordering up through order n.
function displayC_Wyant(obj)

   fprintf('\nWyant\n-----\n');
   l = -1;
   for n = 0 : obj.Wnmax
      fprintf('n = %d\n', n);
      c = obj.WZc{n + 1};
      for m = length(c) - 1 : -1 : 0
         l = l + 1;
         if m == 0
            fprintf('   [ %2d  ] m = %d: ', l, m);
         else
            fprintf('   [%2d-%2d] m = %d: ', l, l + 1, m);
            l = l + 1;
         end
         fprintf(' %d', c{m + 1});
         fprintf('\n');
      end
   end

end

% -----------------------------------------------------------------------------

% Display the Zernike coefficients for the Noll ordering up through order n.
function displayC_Noll(obj)

   fprintf('\nNoll\n----\n');
   l = 0;
   for n = 0 : obj.Nnmax
      fprintf('n = %d\n', n);
      c = obj.NZc{n + 1};
      for m = 0 : length(c) - 1
         if ~isempty(c{m + 1})
            l = l + 1;
            if m == 0
               fprintf('   [ %2d  ] m = %d: ', l, m);
            else
               fprintf('   [%2d-%2d] m = %d: ', l, l + 1, m);
               l = l + 1;
            end
            if m == 0
               f = n + 1;
               fprintf(' sqrt(%d) * (', f);
               fprintf(' %d', round(c{m + 1} / sqrt(f)));
            else
               f = 2*(n + 1);
               fprintf(' sqrt(%d) * (', f);
               fprintf(' %d', round(c{m + 1} / sqrt(f)));
            end
            fprintf(' )');
         else
            fprintf('           m = %d:', m);
         end
         fprintf('\n');
      end
   end

end

% =============================================================================

% Compute the Zernike polynomial Z_n^m(rho, theta) using the precomputed
% coefficients Zc.  rho and theta can be matrices.
function p = polyNM(obj, n, m, rho, theta)

   if strcmp(obj.Ordering, 'Wyant')
      obj.poly_WyantNM(n, m, rho, theta);
   else
      obj.poly_NollNM(n, m, rho, theta);
   end

end

% -----------------------------------------------------------------------------

% Compute the Zernike polynomial Z_n^m(rho, theta) using the precomputed
% coefficients Zc (Wyant ordering).  rho and theta can be matrices.
function p = poly_WyantNM(obj, n, m, rho, theta)

   if n >= size(obj.WZc, 2)
      error('Insufficient precomputed Zernike coefficients for n = %d', n);
   end

   mm = abs(m);
   c = obj.WZc{n + 1}{mm + 1};
   p = 0;
   rho2 = rho.^2;
   rhoP = 1;
   for k = n - mm + 1 : -1 : 1
      p = p + c(k) .* rhoP;
      rhoP = rhoP .* rho2;
   end
   p = p .* rho.^mm;
   switch sign(m)
      case  1
         p = p .* cos(mm .* theta);
      case -1
         p = p .* sin(mm .* theta);
   end

end

% -----------------------------------------------------------------------------

% Compute the Zernike polynomial Z_n^m(rho, theta) using the precomputed
% coefficients Zc (Noll ordering).  rho and theta can be matrices.
function p = poly_NollNM(obj, n, m, rho, theta)

   if n >= size(obj.NZc, 2)
      error('Insufficient precomputed Zernike coefficients for n = %d', n);
   end

   mm = abs(m);
   c = obj.NZc{n + 1}{mm + 1};
   p = 0;
   rho2 = rho.^2;
   rhoP = 1;
   for k = length(c) : -1 : 1
      p = p + c(k) .* rhoP;
      rhoP = rhoP .* rho2;
   end
   p = p .* rho.^mm;
   switch sign(m)
      case  1
         p = p .* cos(mm .* theta);
      case -1
         p = p .* sin(mm .* theta);
   end

end

% =============================================================================

% Compute the Zernike polynomial Z_l(rho, theta) using the precomputed
% coefficients Zc.  rho and theta can be matrices.
% Note that m > 0, m < 0 correspond to the cos/sin factors, respectively.
function p = polyL(obj, l, rho, theta)

   if strcmp(obj.Ordering, 'Wyant')
      obj.poly_WyantL(l, rho, theta);
   else
      obj.poly_NollL(l, rho, theta);
   end

end

% -----------------------------------------------------------------------------

% Compute the Zernike polynomial Z_l(rho, theta) using the precomputed
% coefficients Zc (Wyant ordering).  rho and theta can be matrices.
% Note that m > 0, m < 0 correspond to the cos/sin factors, respectively.
function p = poly_WyantL(obj, l, rho, theta)

   [n, m] = indices_WyantLtoNM(obj, l);
   p = poly_WyantNM(obj, n, m, rho, theta);

end

% -----------------------------------------------------------------------------

% Compute the Zernike polynomial Z_l(rho, theta) using the precomputed
% coefficients Zc (Noll ordering).  rho and theta can be matrices.
% Note that m > 0, m < 0 correspond to the cos/sin factors, respectively.
function p = poly_NollL(obj, l, rho, theta)

   [n, m] = indices_NollLtoNM(obj, l);
   p = poly_NollNM(obj, n, m, rho, theta);

end

% =============================================================================

% Convert Zernike index l into (n, m) (Wyant ordering).
function [n, m] = indices_WyantLtoNM(obj, l)

   n = floor(sqrt(l));
   mm = ceil((2*n - (l - n^2)) / 2);
   if mod(l - n^2, 2) == 0
      m =  mm;
   else
      m = -mm;
   end

end

% -----------------------------------------------------------------------------

% Convert Zernike indices (n, m) into l (Wyant ordering).
function l = indices_WyantNMtoL(obj, n, m)

   if m >= 0
      l = n^2 + 2*(n - m);
   else
      l = n^2 + 2*(n + m) + 1;
   end

end

% =============================================================================

% Convert Zernike index l into (n, m) (Noll ordering).
function [n, m] = indices_NollLtoNM(obj, l)

   n = ceil((-3 + sqrt(1 + 8*l)) / 2);
   m = l - n * (n + 1) / 2 - 1;
   if mod(n, 2) ~= mod(m, 2)
      m = m + 1;
   end
   if mod(l, 2) == 1
      m = -m;
   end

end

% -----------------------------------------------------------------------------

% Convert Zernike indices (n, m) into l (Noll ordering).
function l = indices_NollNMtoL(obj, n, m)

   mm = abs(m);
   % l = n * (n + 1) / 2 + 1; if mm >= 2; l = l + mm - 1; end
   l = n * (n + 1) / 2 + 1 + max(0, mm - 1);
   if (m > 0 & mod(n, 4) >= 2) | (m < 0 & mod(n, 4) <= 1)
      l = l + 1;
   end

end

% =============================================================================

% Compute the weighted sum, s, of Zernike polynomials Z_n^m(rho, theta) for
% n = 0, ..., n_max using the precomputed coefficients Zc.
% rho and theta can be matrices.  Stop iterations when results are within
% proscribed error tolerances.
function s = poly_sum(obj, rho, theta, init, w)

   if strcmp(obj.Ordering, 'Wyant')
      if nargin == 3
         s = obj.poly_sum_Wyant(rho, theta);
      elseif nargin == 4
         s = obj.poly_sum_Wyant(rho, theta, init);
      else % if nargin == 5
         s = obj.poly_sum_Wyant(rho, theta, init, w);
      end
   else
      if nargin == 3
         s = obj.poly_sum_Noll(rho, theta);
      elseif nargin == 4
         s = obj.poly_sum_Noll(rho, theta, init);
      else % if nargin == 5
         s = obj.poly_sum_Noll(rho, theta, init, w);
      end
   end

end

% -----------------------------------------------------------------------------

% Compute the weighted sum, s, of Zernike polynomials Z_n^m(rho, theta) for
% n = 0, ..., n_max using the precomputed coefficients Zc (Wyant ordering).
% rho and theta can be matrices.  Stop iterations when results are within
% proscribed error tolerances.
%
% Note: n = 0, ..., n_max;   m = -n, ..., n
%       w are weights and init are the nonzero pixels
%
% s = I .* sum(Z_n^m(rho, theta) .* w(l), l = 1, ..., l_max)
%     where l_max = sum(sum(m, m = -n, ..., n), n = 0, ..., n_max)
%                 = sum(2 n + 1, n = 0, ..., n_max)
%                 = n_max (n_max + 1) + (n_max + 1) = (n_max + 1)^2
%
% IMPORTANT: In the Wyant ordering for a particular radial polynomial, the
% azimuthal factors
%    cos(m theta)   correspond to   m > 0
%    sin(m theta)                   m < 0
% with no factor for m = 0.  For the weighted sum, this technicality is ignored
% in the interest of speed.  Therefore, l_max should be defined so that both
% azimuthal terms (cos and sin) are included for a particular n and m to avoid
% inconsistencies.

function s = poly_sum_Wyant(obj, rho, theta, init, w)

   n_max = obj.Wnmax;

   if n_max >= size(obj.WZc, 2)
      error( ...
'poly_sum_Wyant: Insufficient precomputed Zernike coefficients for n = %d', n);
   end

   [mm, nn] = size(rho);

   rhos = zeros([size(rho), 2*n_max + 1]);
   rhos(:, :, 1) = 1;
   for i = 2 : 2*n_max + 1
      rhos(:, :, i) = rhos(:, :, i - 1) .* rho;
   end

   thetas = zeros([size(theta), n_max]);
   %c_thetas = zeros([size(theta), n_max]);
   %s_thetas = zeros([size(theta), n_max]);
   thetas(:, :, 1) = theta;
   %c_thetas(:, :, 1) = cos(theta);
   %s_thetas(:, :, 1) = sin(theta);
   for i = 2 : n_max
      thetas(:, :, i) = thetas(:, :, i - 1) + theta;
      %c_thetas(:, :, i) = cos(thetas(:, :, i));
      %s_thetas(:, :, i) = sin(thetas(:, :, i));
   end

   if exist('init', 'var')
      I = init;
   else
      I = ones(mm, nn);
   end

   if exist('w', 'var')
      l = 1;   s = I .* w(l);
      for n = 1 : n_max
         s_prev = s;
         for m = n : -1 : 0
            c = obj.WZc{n + 1}{m + 1};
            nc = length(c);
            cc = ones(mm, nn, nc);
            for i = 1 : nc
               cc(:, :, i) = c(i);
            end
            p = I .* sum(cc .* rhos(:, :, 2*n - m + 1 : -2 : m), 3);
            if m == 0
               l = l + 1;   s = s + p .* w(l);
            else
               l = l + 1;   s = s + p .* cos(thetas(:, :, m)) .* w(l);
               l = l + 1;   s = s + p .* sin(thetas(:, :, m)) .* w(l);
               %l = l + 1;   s = s + p .* c_thetas(:, :, m) .* w(l);
               %l = l + 1;   s = s + p .* s_thetas(:, :, m) .* w(l);
            end
            if l > obj.Wlmax   % note that l_Matlab = l_Wyant + 1
               break;
            end
         end
         delta = norm(s - s_prev, 1);
         if delta < obj.Wabserr | delta/norm(s_prev, 1) < obj.Wrelerr
            break;
         else
            s_prev = s;
         end
      end
   else
      l = 1;   s = I;
      for n = 1 : n_max
         s_prev = s;
         for m = n : -1 : 0
            c = obj.WZc{n + 1}{m + 1};
            nc = length(c);
            cc = ones(mm, nn, nc);
            for i = 1 : nc
               cc(:, :, i) = c(i);
            end
            p = I .* sum(cc .* rhos(:, :, 2*n - m + 1 : -2 : m), 3);
            if m == 0
               l = l + 1;   s = s + p;
            else
               l = l + 1;   s = s + p .* cos(thetas(:, :, m));
               l = l + 1;   s = s + p .* sin(thetas(:, :, m));
               %l = l + 1;   s = s + p .* c_thetas(:, :, m);
               %l = l + 1;   s = s + p .* s_thetas(:, :, m);
            end
            if l > obj.Wlmax   % note that l_Matlab = l_Wyant + 1
               break;
            end
         end
         delta = norm(s - s_prev, 1);
         if delta < obj.Wabserr | delta/norm(s_prev, 1) < obj.Wrelerr
            break;
         else
            s_prev = s;
         end
      end
   end

end

% -----------------------------------------------------------------------------

% Compute the weighted sum, s, of the Zernike polynomials Z_n^m(rho, theta) for
% the Noll indices l = 1, ..., l_max using the precomputed coefficients Zc.
% rho and theta can be matrices.  Stop iterations when results are within
% proscribed error tolerances.
%
% Note: n = 0, ..., n_max;   m = n mod 2, ..., n by 2
%       w are weights and init are the nonzero pixels
%
% s = I .* sum(Z_n^m(rho, theta) .* w(l), l = 1, ..., l_max)
%     where n and m depend on l
%
% IMPORTANT: In the Noll ordering for a particular radial polynomial, the order
% of the azimuthal factors cos(m theta), sin(m theta) varies, but in the
% matrix, this technicality is ignored in the interest of speed.
% Therefore, l_max should be defined so that both azimuthal terms (cos and sin)
% are included for a particular n and m to avoid inconsistencies.

function s = poly_sum_Noll(obj, rho, theta, init, w)

   % This formula comes from observing that the Noll indices
   % l = 1     corresponds to n = 0
   % l = 2 - 3 correspond  to n = 1
   % l = 4 - 6 correspond  to n = 2, etc.
   % and using the fact that s = sum(i, i = 1 .. l) = l (l + 1) / 2
   % => l^2 + l - 2 s = 0, the substituting l by n_max and s by l_max.
   n_max = ceil((-3 + sqrt(1 + 8*obj.Nlmax)) / 2);

   if n_max >= size(obj.NZc, 2)
      error( ...
'poly_sum_Noll: Insufficient precomputed Zernike coefficients for n = %d', n);
   end

   [mm, nn] = size(rho);

   rhos = zeros([size(rho), n_max + 1]);
   rhos(:, :, 1) = 1;
   for i = 2 : n_max + 1
      rhos(:, :, i) = rhos(:, :, i - 1) .* rho;
   end

   thetas = zeros([size(theta), n_max]);
   %c_thetas = zeros([size(theta), n_max]);
   %s_thetas = zeros([size(theta), n_max]);
   thetas(:, :, 1) = theta;
   %c_thetas(:, :, 1) = cos(theta);
   %s_thetas(:, :, 1) = sin(theta);
   for i = 2 : n_max
      thetas(:, :, i) = thetas(:, :, i - 1) + theta;
      %c_thetas(:, :, i) = cos(thetas(:, :, i));
      %s_thetas(:, :, i) = sin(thetas(:, :, i));
   end

   if exist('init', 'var')
      I = init;
   else
      I = ones(mm, nn);
   end

   if exist('w', 'var')
      l = 1;   s = I .* w(l);
      for n = 1 : n_max
         s_prev = s;
         for m = mod(n, 2) : 2 : n
            c = obj.NZc{n + 1}{m + 1};
            nc = length(c);
            cc = ones(mm, nn, nc);
            for i = 1 : nc
               cc(:, :, i) = c(i);
            end
            p = I .* sum(cc .* rhos(:, :, n + 1 : -2 : m + 1), 3);
            if m == 0
               l = l + 1;   s = s + p .* w(l);
            else
               l = l + 1;   s = s + p .* cos(thetas(:, :, m)) .* w(l);
               l = l + 1;   s = s + p .* sin(thetas(:, :, m)) .* w(l);
               %l = l + 1;   s = s + p .* c_thetas(:, :, m) .* w(l);
               %l = l + 1;   s = s + p .* s_thetas(:, :, m) .* w(l);
            end
            if l >= obj.Nlmax   % note that l_Matlab = l_Noll
               break;
            end
         end
         delta = norm(s - s_prev, 1);
         if delta < obj.Nabserr | delta/norm(s_prev, 1) < obj.Nrelerr
            break;
         else
            s_prev = s;
         end
      end
   else
      l = 1;   s = I;
      for n = 1 : n_max
         s_prev = s;
         for m = mod(n, 2) : 2 : n
            c = obj.NZc{n + 1}{m + 1};
            nc = length(c);
            cc = ones(mm, nn, nc);
            for i = 1 : nc
               cc(:, :, i) = c(i);
            end
            p = I .* sum(cc .* rhos(:, :, n + 1 : -2 : m + 1), 3);
            if m == 0
               l = l + 1;   s = s + p;
            else
               l = l + 1;   s = s + p .* cos(thetas(:, :, m));
               l = l + 1;   s = s + p .* sin(thetas(:, :, m));
               %l = l + 1;   s = s + p .* c_thetas(:, :, m);
               %l = l + 1;   s = s + p .* s_thetas(:, :, m);
            end
            if l >= obj.Nlmax   % note that l_Matlab = l_Noll
               break;
            end
         end
         delta = norm(s - s_prev, 1);
         if delta < obj.Nabserr | delta/norm(s_prev, 1) < obj.Nrelerr
            break;
         else
            s_prev = s;
         end
      end
   end

end

% =============================================================================

% Compute the matrix, Z(R, S, L), of Zernike polynomials Z_l(rho, theta) for
% each pixel of an R x S image, where
%    L = 0, ..., l_max (Wyant ordering) or
%    L = 1, ..., l_max (Noll  ordering).
% The 3rd dimension of Z indexes the Zernike polynomials in the given ordering,
% noting that Matlab will start the index at 1.  Note that for efficiency
% reasons, the order of the coefficients for a given (n, |m|) will be the cos
% term followed by the sin term, so l should be chosen so that BOTH terms are
% included to avoid inconsistencies.

function Z = matrix_Z(obj, rho, theta, init, w)

   if strcmp(obj.Ordering, 'Wyant')
      if nargin == 3
         Z = obj.matrix_Z_Wyant(rho, theta);
      else % if nargin == 4
         Z = obj.matrix_Z_Wyant(rho, theta, init);
      end
   else
      if nargin == 3
         Z = obj.matrix_Z_Noll(rho, theta);
      else % if nargin == 4
         Z = obj.matrix_Z_Noll(rho, theta, init);
      end
   end

   obj.ZM = Z;

end

% -----------------------------------------------------------------------------

% Compute the matrix, Z, of the Zernike polynomials Z_n^m(rho, theta) for
% the Wyant indices l = 0, ..., l_max using the precomputed coefficients Zc.
% rho and theta can be matrices.
%
% Note: n = 0, ..., n_max;   m = -n, ..., n
%       init are the nonzero pixels
%
% IMPORTANT: In the Wyant ordering for a particular radial polynomial, the
% azimuthal factors
%    cos(m theta)   correspond to   m > 0
%    sin(m theta)                   m < 0
% with no factor for m = 0.  For the matrix, this technicality is ignored
% in the interest of speed.  Therefore, l_max should be defined so that both
% azimuthal terms (cos and sin) are included for a particular n and m to avoid
% inconsistencies.

function Z = matrix_Z_Wyant(obj, rho, theta, init)

   n_max = obj.Wnmax;

   if n_max >= size(obj.WZc, 2)
      error( ...
'matrix_Z_Wyant: Insufficient precomputed Zernike coefficients for n = %d', n);
   end

   [mm, nn] = size(rho);

   rhos = zeros([size(rho), 2*n_max + 1]);
   rhos(:, :, 1) = 1;
   for i = 2 : 2*n_max + 1
      rhos(:, :, i) = rhos(:, :, i - 1) .* rho;
   end

   thetas = zeros([size(theta), n_max]);
   %c_thetas = zeros([size(theta), n_max]);
   %s_thetas = zeros([size(theta), n_max]);
   thetas(:, :, 1) = theta;
   %c_thetas(:, :, 1) = cos(theta);
   %s_thetas(:, :, 1) = sin(theta);
   for i = 2 : n_max
      thetas(:, :, i) = thetas(:, :, i - 1) + theta;
      %c_thetas(:, :, i) = cos(thetas(:, :, i));
      %s_thetas(:, :, i) = sin(thetas(:, :, i));
   end

   if exist('init', 'var')
      I = init;
   else
      I = ones(mm, nn);
   end

   nZ = 1 + obj.Wlmax;
   Z = ones(mm, nn, nZ);
   l = 1;   Z(:, :, l) = I;
   for n = 1 : n_max
      for m = n : -1 : 0
         c = obj.WZc{n + 1}{m + 1};
         nc = length(c);
         cc = ones(mm, nn, nc);
         for i = 1 : nc
            cc(:, :, i) = c(i);
         end
         p = I .* sum(cc .* rhos(:, :, 2*n - m + 1 : -2 : m), 3);
         if m == 0
            l = l + 1;   Z(:, :, l) = p;
         else
            l = l + 1;   Z(:, :, l) = p .* cos(thetas(:, :, m));
            l = l + 1;   Z(:, :, l) = p .* sin(thetas(:, :, m));
            %l = l + 1;   Z(:, :, l) = p .* c_thetas(:, :, m);
            %l = l + 1;   Z(:, :, l) = p .* s_thetas(:, :, m);
         end
         if l > obj.Wlmax   % note that l_Matlab = l_Wyant + 1
            break;
         end
      end
   end

end

% -----------------------------------------------------------------------------

% Compute the matrix, Z, of the Zernike polynomials Z_n^m(rho, theta) for
% the Noll indices l = 1, ..., l_max using the precomputed coefficients Zc.
% rho and theta can be matrices.
%
% Note: n = 0, ..., n_max;   m = n mod 2, ..., n by 2
%       init are the nonzero pixels
%
% IMPORTANT: In the Noll ordering for a particular radial polynomial, the order
% of the azimuthal factors cos(m theta), sin(m theta) varies, but in the
% weighted sum, this technicality is ignored in the interest of speed.
% Therefore, l_max should be defined so that both azimuthal terms (cos and sin)
% are included for a particular n and m to avoid inconsistencies.

function Z = matrix_Z_Noll(obj, rho, theta, init)

   % This formula comes from observing that the Noll indices
   % l = 1     corresponds to n = 0
   % l = 2 - 3 correspond  to n = 1
   % l = 4 - 6 correspond  to n = 2, etc.
   % and using the fact that s = sum(i, i = 1 .. l) = l (l + 1) / 2
   % => l^2 + l - 2 s = 0, the substituting l by n_max and s by l_max.
   n_max = ceil((-3 + sqrt(1 + 8*obj.Nlmax))/2);

   if n_max >= size(obj.NZc, 2)
      error( ...
'matrix_Z_Noll: Insufficient precomputed Zernike coefficients for n = %d', n);
   end

   [mm, nn] = size(rho);

   rhos = zeros([size(rho), n_max + 1]);
   rhos(:, :, 1) = 1;
   for i = 2 : n_max + 1
      rhos(:, :, i) = rhos(:, :, i - 1) .* rho;
   end

   thetas = zeros([size(theta), n_max]);
   %c_thetas = zeros([size(theta), n_max]);
   %s_thetas = zeros([size(theta), n_max]);
   thetas(:, :, 1) = theta;
   %c_thetas(:, :, 1) = cos(theta);
   %s_thetas(:, :, 1) = sin(theta);
   for i = 2 : n_max
      thetas(:, :, i) = thetas(:, :, i - 1) + theta;
      %c_thetas(:, :, i) = cos(thetas(:, :, i));
      %s_thetas(:, :, i) = sin(thetas(:, :, i));
   end

   if exist('init', 'var')
      I = init;
   else
      I = ones(mm, nn);
   end

   nZ = obj.Nlmax;
   Z = ones(mm, nn, nZ);
   l = 1;   Z(:, :, l) = I;
   for n = 1 : n_max
      for m = mod(n, 2) : 2 : n
         c = obj.NZc{n + 1}{m + 1};
         nc = length(c);
         cc = ones(mm, nn, nc);
         for i = 1 : nc
            cc(:, :, i) = c(i);
         end
         p = I .* sum(cc .* rhos(:, :, n + 1 : -2 : m + 1), 3);
         if mod(n,2) == 0
             p = -1.*p;
         end
         if m == 0
            l = l + 1;   Z(:, :, l) = p;
         else
             switch mod(l,2)
                 case 0
                     l = l + 1;   Z(:, :, l) = p .* sin(-1.*thetas(:, :, m));
                     l = l + 1;   Z(:, :, l) = p .* cos(thetas(:, :, m));
                 case 1
                     l = l + 1;   Z(:, :, l) = p .* cos(thetas(:, :, m));
                     l = l + 1;   Z(:, :, l) = p .* sin(-1.*thetas(:, :, m));
                     %l = l + 1;   Z(:, :, l) = p .* c_thetas(:, :, m);
                     %l = l + 1;   Z(:, :, l) = p .* s_thetas(:, :, m);
             end
         end
         if l >= obj.Nlmax   % note that l_Matlab = l_Noll
            break;
         end
      end
   end

end

% =============================================================================

% Inputs:
%    pupil    
%    type     'mag' or 'phase'
%    N        Zernike order
%    R        PSF size
%    obj.ZM   previously computed Zernike matrix
% Outputs:
%    Ceffnorm
%    pupil_fitnorm
function [Ceffnorm, pupil_fitnorm] = fitzernike(obj, pupil, type, N, R)

   Zterms = obj.n_Zernikes(N);
   Ceff = zeros(1, Zterms);
   for k = 1 : Zterms
      Ceff(k) = sum(sum(pupil .* obj.ZM(:, :, k))) / ...
                sum(sum(obj.ZM(:, :, k) .* obj.ZM(:, :, k)));
   end

   % Generate fitted complex magnitude.
   pupil_fit = zeros(R, R);
   for k = 1 : Zterms
      pupil_fit = pupil_fit + obj.ZM(:, :, k) .* Ceff(k);
   end

   % Normalize Zernike coefficients.
   switch type
   case 'mag'
      tmp = pupil_fit .* (1/R);
   case 'phase'
      tmp = exp(pupil_fit .* 1i) .* (1/R);
   end
   normF = sqrt(sum(sum(tmp .* conj(tmp))));
   Ceffnorm = Ceff ./ normF;

   pupil_fitnorm = zeros(R, R);
   for k = 1 : Zterms
      pupil_fitnorm = pupil_fitnorm + obj.ZM(:, :, k) .* Ceffnorm(k);
  end

end

% =============================================================================
end % methods

methods(Static)
% =============================================================================

% Compute parameters associated with the Zernike polynomials.
function [rho, theta, NA_constraint, k_r] = ...
   params4_Zernike(R, pixel_size, Maglateral, NA, lambda)

   [X, Y] = meshgrid(-(-R/2 : R/2 - 1), -R/2 : R/2 - 1);
   Z = sqrt(X.^2 + Y.^2);
   PHI = atan2(Y, X);

   scale = R * pixel_size / Maglateral;
   Freq_max = NA / lambda;
   k_r = Z ./ scale;
   NA_constraint = k_r < Freq_max;

   rho = k_r .* NA_constraint ./ Freq_max;
   theta = PHI .* NA_constraint;

end

% -----------------------------------------------------------------------------

% Compute parameters associated with the Zernike polynomials.
function [rho, theta, NA_constraint] = ...
   params3_Zernike(PHI, k_r, NA, lambda)

   Freq_max = NA / lambda;
   NA_constraint = k_r < Freq_max;

   rho = k_r .* NA_constraint ./ Freq_max;
   theta = PHI .* NA_constraint;

end

% =============================================================================
end % methods(Static)
% =============================================================================
end % classdef
