#Direct Interpreted from https://github.com/loftytopping/PyBox/blob/master/Aerosol/Property_calculation.py
using PyCall
using LightXML
unshift!(PyVector(pyimport("sys")["path"]),"../UManSysProp_public")
@pyimport umansysprop.boiling_points as boiling_points
@pyimport umansysprop.vapour_pressures as vapour_pressures
@pyimport umansysprop.critical_properties as critical_properties
@pyimport umansysprop.liquid_densities as liquid_densities
@pyimport umansysprop.partition_models as partition_models
@pyimport umansysprop.groups as groups
@pyimport umansysprop.activity_coefficient_models_dev as aiomfac
@pyimport umansysprop.forms as forms #need forms.CoreAbundanceField (class)
CoreAbundanceField=forms.CoreAbundanceField

function readSMILESdict()
    species2SMILESdict=Dict{String,String}()
    mcmdoc=parse_file("MCM.xml")
    root=find_element(root(mcmdoc),"species_defs")
    for species in child_nodes(root)
        name=attribute(species,"species_name")
        if has_children(name)
            SMILES=content(species)
            species2SMILESdict[name,SMILES]
        end
    end
    return species2SMILESdict
end

function SMILES2Pybel(smi_str)
    nothing
end

function compoudProperty(compound_str)
    nothing
end