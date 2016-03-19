function [data,raw] = xensemble (npar,l) 
%   data = XENSEMBLE (npar,latt)  integrates and ensemble averages fields.
%   Input:  'npar' is total ensemble count,'l' is  lattice description.
%   Output: 'data' is average data generated from stochastic integration.
%   and 'raw' is raw data generated from stochastic integration.
%   xSPDE functions are licensed by Peter D. Drummond, (2015) - see License

sequence = length(l);                             %%check length of input
data = cell(sequence);                            %%allocate data sequence
for seq=1:sequence                                %%loop over sequence
    for n=1:l{seq}.averages
        data{seq}{n} = zeros(l{seq}.d.data{n});   %%initialise data cells
    end
end                                               %%end loop over sequence
serial = l{1}.ensembles(2);                       %%serial ensemble number
raw = cell(serial,sequence,l{1}.errorchecks);     %%cell array for raw data

      %%Loop over all the serial ensembles

for ns = 1:serial                                 %%loop over ensembles
  nsp = (npar-1)*serial + ns;                     %%unique ensemble index
  
      %%Loop over the error-checking indices
  
  for  nc  = 1:l{1}.errorchecks                   %%loop over errorchecks 
    rng(l{1}.seed+nsp);                           %%Set unique random seed
    if l{1}.print                                 %%If print switch
        fprintf('Check %d, Ensemble %d\n',nc,nsp);%%print indices
    end;                                          %%end if print switch
    
      %%Loop over the stochastic integration sequence   
    
    for seq = 1:sequence                          %%Loop over sequence
      r=l{seq};
      if r.print > 1                              %%If verbose print
          fprintf('Sequence %d\n',seq);           %%print sequence indices
      end;                                        %%end if verbose  print
      r.dtr=r.dt/nc;                              %%reduced step-size
      r.propagator = r.propfactor(nc,r);          %%get propagator   
      w = r.randomgen(r);                         %%generate random fields
      
      %%Initialise the stochastic fields for sequence
      
      if seq == 1                                 %%check if sequence = 1
          a = r.initial(w,r);                     %%initialize fields
      else                                        %%if sequence > 1
          a = r.transfer(w,r,a,l{seq-1});         %%interface fields
      end                                         %%end check sequence =1
      a = reshape(a,r.d.a);                       %%reshape fields
      r.t=r.origin(1);                            %%initial time
      
      %%Store the averages for the stochastic field path     
      
      [a,o,raw{ns,seq,nc}] = xpath(a,nc,r);       %%simulate path
      
      for n = 1:r.averages    
        if nc == 2 || r.errorchecks == 1          %%if fine check
         data{seq}{n}(1,:,:,:) = data{seq}{n}(1,:,:,:) + o{n}/r.ncopies;          
         data{seq}{n}(3,:,:,:) = data{seq}{n}(3,:,:,:) + o{n}.^2/r.ncopies;                                 
        else                                      %%else coarse calc
         data{seq}{n}(2,:,:,:) = data{seq}{n}(2,:,:,:) + o{n}/r.ncopies;
        end                                       %%end if errorchecks
      end                                         %%end averages loop
    end;                                          %%end sequence loop
  end                                             %%end errorchecks loop 
end;                                              %%end ensemble loop
end                                               %%end function