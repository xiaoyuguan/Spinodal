[Mesh]
  type = GeneratedMesh
  dim = 2
  xmax = 200
  ymax = 200
  nx = 100
  ny = 100
[]

[Modules]
  [./PhaseField]
    [./Conserved]
      [./c]
        free_energy = f_loc
        kappa = kappa_c
        mobility = M
        solve_type = REVERSE_SPLIT
      [../]
    [../]
  [../]
[]

[ICs]
  [./concentrationIC]
    type = FunctionIC
    function = cIC
    variable = c
  [../]
[]

[Functions]
  [./cIC]
    type = ParsedFunction
    vars = 'c0 epsl'
    vals = '0.5 0.01'
    value = 'c0+epsl*(cos(0.105*x)*cos(0.11*y)+(cos(0.13*x)*cos(0.087*y))^2+cos(0.025*x-0.15*y)*cos(0.07*x-0.02*y))'
  [../]
[]

[AuxVariables]
  [./f_density]   # Local energy density (eV/mol)
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./precipitate_indicator]
  [../]
[]

[AuxKernels]
  # Calculates the energy density by combining the local and gradient energies
  [./f_density]   # (eV/mol/nm^2)
    type = TotalFreeEnergy
    variable = f_density
    f_name = 'f_loc'
    kappa_names = 'kappa_c'
    interfacial_vars = c
    execute_on = 'initial TIMESTEP_END'
  [../]
  [./precipitate_indicator]
    type = ParsedAux
    variable = precipitate_indicator
    args = c
    function = if(c>0.4,1.0,0)
    execute_on = 'initial TIMESTEP_END'
  [../]
[]

[Materials]
  [./kappa]                  # Gradient energy coefficient (eV nm^2/mol)
    type = GenericFunctionMaterial
    prop_names = 'kappa_c'
    #prop_values = '5e-16*6.24150934e+18*1e-9/7.1e-6'
                  # kappa_c *eV_J*nm_m^2* d
    prop_values = '2'
  [../]
  [./mobility]
    type = GenericConstantMaterial
    prop_names = M
    #prop_values = 2.2e-5
    prop_values = 5
  [../]
  [./local_energy]           # Local free energy function (eV/mol)
    type = DerivativeParsedMaterial
    f_name = f_loc
    args = c
    #constant_names = 'A   B   C   D   E   F   G  length_scale  eVpJ  Vm'
    #constant_expressions = '-2.45e+04 -2.83e+04 4.17e+03 7.05e+03
    #                        1.21e+04 2.57e+03 -2.35e+03
    #                        1e-9 6.24150934e+18 7.1e-6'
    #function = 'eVpJ/Vm*length_scale^3*(A*c+B*(1-c)+C*c*log(c)+D*(1-c)*log(1-c)+
    #            E*c*(1-c)+F*c*(1-c)*(2*c-1)+G*c*(1-c)*(2*c-1)^2)'
    constant_names = 'rohs ca cb'
    constant_expressions = '5 0.3 0.7'
    function = 'rohs*(c-ca)^2*(cb-c)^2'
    derivative_order = 2
  [../]
[]

[Postprocessors]
  [./total_energy]          # Total free energy at each timestep
    type = ElementIntegralVariablePostprocessor
    variable = f_density
    execute_on = 'initial timestep_end'
  [../]
  [./volume_fraction]      # Fraction of surface devoted to precipitates
    type = ElementAverageValue
    variable = precipitate_indicator
    execute_on = 'initial timestep_end'
  [../]
  [./max_concentration]
    type = ElementExtremeValue
    variable = c
    value_type = max
    execute_on = 'initial timestep_end'
  [../]
  [./min_concentration]
    type = ElementExtremeValue
    variable = c
    value_type = min
    execute_on = 'initial timestep_end'
  [../]
  [./dt]
    type = TimestepSize
  [../]
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  nl_abs_tol = 1e-11
  nl_rel_tol = 1e-08
  end_time = 1e+6
  #petsc_options_iname = '-pc_type -ksp_type'
  #petsc_options_value = 'bjacobi  gmres'
  # petsc_options_iname = '-pc_type -pc_hypre_type'
  # petsc_options_value = 'hypre  boomeramg'
   petsc_options_iname = '-pc_type -sub_pc_type'
   petsc_options_value = 'asm lu'
  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1
    cutback_factor = 0.7
    growth_factor = 1.1
    optimal_iterations = 6
  [../]
[]

[Outputs]
  exodus = true
  csv = true
  perf_graph = true
[]
