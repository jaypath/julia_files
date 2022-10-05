ageMax = 100;
ageMin = 40;
durMin = 0.33;
durMax = 2;

#run grantsandpapers.jl first.
if !(@isdefined isLoadedBizopsUtils)
  println("Running MGHUtils Scripts, this will take a while.")
  include("/home/ubuntu/julia_files/GrantsAndPapers/GrantsAndPapers.jl")
  println("MGHUtils scripts done. Now analyzing demographics.")
end
  
using CSV, TimeSpans

cd("/home/ubuntu/julia_files/BMS")

#1. subjects with any AD code and age
println("Find subjects with main dx.")
AD = sort(select(unique(listDXandICD("alzheimer",""),[:diagnosis,:code]),:code,:diagnosis),:code);
CSV.write("ICD_AD.csv",AD); #review this CSV!

#records meeting the first criteria, at the specified age
println("Find recordings with main dx.")
AD_data = dropmissing(unique(recordsWithDXandICD("",unique(AD,:code).code),:recording),:age_in_years); #drop records with missing demographic data
AD_data = subset(AD_data,:age_in_years=>ByRow(a->a>ageMin && a<ageMax);skipmissing=true); #by recording, and min age

#exclude 
println("Eliminate exclusion codes from dataset.")
exclusionDXs = ["CNS lymphoma","cocaine dependence","cocaine use","opiate dependence","opiate use","Pick's disease","fronto-temporal dementia","frontotemporal dementia","hydrocephalus","lewy body","multiple systems atrophy","ALS","amyotrophic lateral sclerosis","encephalomalacia","muscular dystrophe","trisomy","mitochondrial","vascular dementia","stroke","alcohol","substance","encephalitis","Creutzfeldt","multiple sclerosis","brain tumor","neoplasm of brain","schizophrenia","glioblastoma","glioma","astrocytoma","cirrhosis","renal failure"];
exclusionICDs = ["C71.9","C71.90","C71.91","C71.92","191.9","192.1","198.3","200.50"]; #want to convert code to text? use listDXandICD("",codes,"")
AD_x = sort(select(unique(listDXandICD(exclusionDXs,exclusionICDs,AD_data),[:diagnosis,:code]),:code,:diagnosis),:code);
CSV.write("ICD_exclude.csv",AD_x); #review this CSV!

AD_data = recordsWithDXandICD(exclusionDXs,exclusionICDs,AD_data,true,true);

#just the EEGs
println("Select EEGs.")
AD_EEG = testType(AD_data,"EEG");

#limit by recording parameters
println("Eliminate recordings outside specified parameters.")
AD_EEG = subset(AD_EEG,:span=>ByRow(a->duration(a)/Nanosecond(Hour(1))>durMin);skipmissing=true); #by recording min dur
AD_EEG = subset(AD_EEG,:span=>ByRow(a->duration(a)/Nanosecond(Hour(1))<durMax);skipmissing=true); #by recording max dur

#not included here... exclude critically ill, exclude sedated, exclude ICU

#meds here...


#Bin the EEGs by subject
AD_EEG_bin = binThisDF(AD_EEG,:subject)
CSV.write("EEGbin.csv",AD_EEG_bin); #review this CSV!

AD_EEG_ICD = sort(select(unique(searchRecICD(AD_EEG),[:diagnosis,:code,:subject]),:code,:diagnosis,:subject),:code);
CSV.write("EEGICD.csv",sort(unique(select(AD_EEG_ICD,:code,:diagnosis),[:diagnosis,:code]),:code)); #review this CSV!

AD_EEG_ICD_bin = sort(binThisDF(unique(AD_EEG_ICD,[:code, :subject]),:code),:code);
CSV.write("EEGICD_bysubject.csv",AD_EEG_ICD_bin); #review this CSV!
