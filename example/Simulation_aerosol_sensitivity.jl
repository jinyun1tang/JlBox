using JlBox
using DataFrames
using Sundials
using OrdinaryDiffEq
#using CSV

function configure_aerosol()
    file="../data/MCM_APINENE.eqn.txt"#"MCM_test.eqn.txt"MCM_APINENE.eqn.txt
    temp=288.15 # Kelvin
    RH=0.5 # RH/100% [0 - 0.99]
    hour_of_day=12.0 # Define a start time  24 hr format
    start_time=hour_of_day*60*60 # seconds, used as t0 in solver
    simulation_time= 3600.0 # seconds
    batch_step=300.0 # seconds
    temp_celsius=temp-273.15
    Psat_w=610.78*exp((temp_celsius/(temp_celsius+238.3))*17.2694)# Saturation VP of water vapour, to get concentration of H20
    Pw=RH*Psat_w
    Wconc=0.002166*(Pw/(temp_celsius+273.16))*1.0e-6 #kg/cm3
    H2O=Wconc*(1.0/(18.0e-3))*6.0221409e+23#Convert from kg to molecules/cc
    tspan=(0.,simulation_time)
    Cfactor= 2.55e+10 #ppb-to-molecules/cc
    reactants_initial_dict=Dict(["O3"=>18.0,"APINENE"=>30.0,"H2O"=>H2O/Cfactor])#ppb BUT1ENE APINENE
    constantdict=Dict([(:temp,temp)])
    num_bins=16

    #Lognormal Distribution
    total_conc=100 #Total particles per cc
    size_std=2.2 #Standard Deviation
    lowersize=0.01 #microns
    uppersize=1.0 #microns
    meansize=0.2 #microns

    # - Specify the core material. 
    # This code is currently setup to consider *ammonium sulphate* as the core
    y_core_init=1.0e-3.+zeros(Float64,num_bins) #Will hold concentration of core material, only initialise here [molecules/cc] 
    core_density_array=1770.0.+zeros(Float64,num_bins) #[kg/m3] - need to make sure this matches core definition above
    core_mw=132.14.+zeros(Float64,num_bins) #[g/mol]
    core_dissociation=3.0 #Define this according to choice of core type. Please note this value might change

    vp_cutoff=-6.0
    R_gas=8.3144598 #Ideal gas constant [kg m2 s-2 K-1 mol-1]
    NA=6.0221409e+23 #Avogadros number
    sigma=72.0e-3 # Assume surface tension of water (mN/m) ???
    property_methods=Dict("bp"=>"joback_and_reid","vp"=>"nannoolal","critical"=>"nannoolal","density"=>"girolami")
    reltol=1e-4
    abstol=1.0e-2
    positiveness=true
    aerosolconfig=JlBox.AerosolConfigure(file,temp,RH,hour_of_day,start_time,simulation_time,batch_step,
                           H2O,tspan,Cfactor,reactants_initial_dict,constantdict,num_bins,
                           total_conc,size_std,lowersize,uppersize,meansize,y_core_init,
                           core_density_array,core_mw,core_dissociation,vp_cutoff,R_gas,
                           NA,sigma,property_methods,TRBDF2(),reltol,abstol,positiveness)
    use_cache=true
    diff_method="fine_seeding"
    adjoint_solver=TRBDF2(autodiff=false)
    reltol=1e-8
    abstol=1e-6
    adjointconfig=JlBox.AdjointConfigure(use_cache,diff_method,adjoint_solver)
    aerosolconfig,adjointconfig
end

aerosolconfig,adjointconfig=configure_aerosol()
@time dSOA_mass_drate,dSOA_mass_percentk=JlBox.run_simulation_aerosol_adjoint(aerosolconfig,adjointconfig)
df=DataFrames.DataFrame(dSOA_mass_drate)
df2=DataFrames.DataFrame(dSOA_mass_percentk)
#CSV.write("/data/jlbox_sensitivity_dSOAdrate_results.csv",df)
#CSV.write("/data/jlbox_sensitivity_dSOApercentk_results.csv",df2)
df2
