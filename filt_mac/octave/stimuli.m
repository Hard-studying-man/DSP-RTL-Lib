  close all
  clear
  clc  

  nr_samples = 2^10;
  
  gp_coeff_length      = 32;
  gp_coeff_width       = 16;
  gp_data_width        = 2;
  gp_symm              = 0;
   
  fs  = 1000;
  f   = [0 50 110 fs]/fs;
  b   = remez(gp_coeff_length-1, f, [1 1 0 0], [1 1]);
  q_b = quantize(b, gp_coeff_width, "midtread", "signed");
  b   = round( (2^(gp_coeff_width-1)-1) * q_b);
  
  for i = 1 : 9,
    testcase = i;
    printf("### INFO: Running test-case %d\n", testcase);
  switch (testcase)
    case {1}
      nr_samples = 2^(ceil(log2(gp_coeff_length)));
      data = zeros(1, nr_samples);
      data(2)   = 1;
      
    case {2}
      nr_samples = 2^(ceil(log2(gp_coeff_length)));
      data = ones(1, nr_samples); 
      data(1) = 0;
      data(2) = 0;
   
    case {3}
      data = -2^(gp_data_width-1):2^(gp_data_width-1)-1;
    
    case {4}
      data = 2^(gp_data_width-1)-1:-1:-2^(gp_data_width-1);    
      
    case {5}
      fs = 1e3;
      f1 = 1;
      f2 = fs/2;
      t = 1:1/fs:5;
      data = chirp (t, f1, 5, f2, "logarithmic");
      q_data = quantize(data, gp_data_width, "midtread", "signed");
      data = round( 2^(gp_data_width-1) * q_data );
      
    case {6}
      rand ("state", 42);
      r_min = -2^(gp_data_width-1);
      r_max =  2^(gp_data_width-1);
      r     = floor(r_min + (r_max - r_min)*rand(1, nr_samples));
      data = r;
    
    case {7}
      fs    = 1e3;
      fo    = 113;
      A     = 1;
      phi   = 0;
      dc    = 0;
      c     = 10;
      t     = 0:1/fs:c/fo-1/fs;
      data  = round( 2^(gp_data_width-1) * (A * sin(2*pi*fo*t + phi) + dc) );
      data(data==2^(gp_data_width-1)) = 2^(gp_data_width-1)-1;
  
    case {8}
      fs    = 1e3;
      fo    = 113;
      A     = 1;
      phi   = 0;
      dc    = 0;
      c     = 31;
      t     = 0:1/fs:c/fo-1/fs;
      data  = A * sin(2*pi*fo*t + phi) + dc;
      rand ("state", 72);
      r_min = -1;
      r_max =  1;
      An = 0.2;
      r     = An * ( r_min + (r_max - r_min)*rand(1, length(data)) );
      q_data = quantize(data+r, gp_data_width, "midtread", "signed");
      data = round( 2^(gp_data_width-1) * q_data );      
      data(data==2^(gp_data_width-1)) = 2^(gp_data_width-1)-1;

    case {9}
      %nr_samples = 2^12;
      fs    = 1e3;
      fo    = 173.38943;
      A     = 1;
      phi   = pi/3;
      dc    = 0.1;
      c     = 53;
      t     = 0:1/fs:c/fo-1/fs;
      data  = A * sin(2*pi*fo*t + phi) + dc;
      rand ("state", 1732);
      r_min = -1;
      r_max =  1;
      An = 0.25;
      r     = An * ( r_min + (r_max - r_min)*rand(1, length(data)) );
      q_data = quantize(data+r, gp_data_width, "midtread", "signed");
      data = round( 2^(gp_data_width-1) * q_data );      
      data(data==2^(gp_data_width-1)) = 2^(gp_data_width-1)-1;
      
  endswitch

  %% INPUT STRUCT
  disp("### INFO: Generating defines files.");
  defines.gp_data_width        = gp_data_width;
  defines.gp_coeff_length      = gp_coeff_length;
  defines.gp_coeff_width       = gp_coeff_width;
  defines.gp_symm              = gp_symm;
  defines.testcase             = testcase;
  gen_defines(defines);
  %% COEFFICIENT GENERATION
  gen_coeffs(b,gp_coeff_width, gp_symm);
  %% RESPONSE GENERATION
  octave_data=data;
  yy= filter(b,1,octave_data);
  disp("### INFO: Generating response files.");
  filename_oup = strcat("response_tc_",num2str(testcase,"%d"),"_mat.dat");
  dlmwrite(filename_oup,yy,"\n");
  %% STIMULI GENERATION  
  disp("### INFO: Generating stimuli files.");
  filename_inp = strcat("stimuli_tc_",num2str(testcase,"%d"),"_mat.dat");
  dlmwrite(filename_inp,data,"\n");
end
disp("### INFO: Moving stimuli and response files.");
system("mv stimuli_tc_*.dat ../sim/testcases/stimuli/");
system("mv response_tc_*.dat ../sim/testcases/response/");
system("mv filt_coeff.v ../rtl/");
%% EOF