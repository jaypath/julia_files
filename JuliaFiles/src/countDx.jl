#REV 6/27/2022
#count the following conditions:
# MCI
# AD studies
# narcolepsy type 1
#narcolepsy type 2
#epilepsy, focal G40.1*, G40.2*
#epilepsy, generalized G40.3*
#epilepsy, all G40.*
#parkinsons g20.*
#schizophrenia F20.*
# psychosis F28.* F29.*
# bipolar F31.*
# mania F30.*
# depression F33.*
# migraine G43.*
# FTD G31.*
# chronic pain G89.* and gen pain R52

icds = useICD();


function testType(dataset,ttype)
  return unique(filter(:test_type => d -> contains(lowercase(ttype),lowercase(d)),dropmissing(dataset,:test_type)),:subject);
end

temp1 = searchByICD("mild cognitive impairment");

temp2 = searchByICD("alzheimer");
temp3 = antijoin(temp1,temp2,on=:subject)

psg_MCI = testType(temp1,"psg");
eeg_MCI = testType(temp1,"eeg");

psg_AD = testType(temp2,"psg");
#psg_AD_psg_recordings = unique(filter(:test_type => contains(r"psg"i),dropmissing(AD,:test_type)),:recording;view=true);
eeg_AD = testType(temp2,"eeg");
#AD_eeg_recordings = unique(filter(:test_type => contains(r"eeg"i),dropmissing(AD,:test_type)),:recording;view=true);

psg_MCInotAD = testType(temp3,"psg");
#psg_MCInotAD_psg_recordings = unique(filter(:test_type => contains(r"psg"i),dropmissing(MCInotAD,:test_type)),:recording;view=true);
eeg_MCInotAD = testType(temp1,"psg");
#MCInotAD_eeg_recordings = unique(filter(:test_type => contains(r"eeg"i),dropmissing(MCInotAD,:test_type)),:recording;view=true);

#NT1
temp1 = searchByICDcode("g47.411")
psg_NT1 = testType(temp1,"psg");

#NT2
temp1 = searchByICDcode("g47.419")
psg_NT2 = testType(temp1,"psg");


temp1 =  searchByICDcode(["g40.1","g40.2"]);
eeg_epifocal  = testType(temp1,"eeg");

temp1 =  searchByICDcode("g40.3");
eeg_epigen =  testType(temp1,"eeg");

temp1 =  searchByICD("epilepsy");
eeg_epiall =  testType(temp1,"eeg");

temp1 =  searchByICD("Parkinson");
eeg_PD =  testType(temp1,"eeg");
psg_PD =  testType(temp1,"psg");

temp1 =  searchByICD("schizophrenia");
eeg_schiz =  testType(temp1,"eeg");
psg_schiz =  testType(temp1,"psg");

temp1 =  searchByICD("psychosis");
eeg_psychosis =  testType(temp1,"eeg");
psg_psychosis =  testType(temp1,"psg");

temp1 =  searchByICD("bipolar");
eeg_BP =  testType(temp1,"eeg");
psg_BP =  testType(temp1,"psg");

temp1 =  searchByICD("mania");
eeg_mania =  testType(temp1,"eeg");
psg_mania =  testType(temp1,"psg");

temp1 =  searchByICD("major depress");
eeg_MDD =  testType(temp1,"eeg");
psg_MDD =  testType(temp1,"psg");

temp1 =  searchByICD(["chronic pain"]);
eeg_pain =  testType(temp1,"eeg");
psg_pain =  testType(temp1,"psg");

temp1 =  searchByICD("migraine");
eeg_migraine =  testType(temp1,"eeg");
psg_migraine =  testType(temp1,"psg");

counts=  ["eeg_MCInotAD" nrow(eeg_MCInotAD)];
counts = [counts; ["psg_MCInotAD" nrow(psg_MCInotAD)]];
counts = [counts; ["eeg_MCI" nrow(eeg_MCI)]];
counts = [counts; ["psg_MCI" nrow(psg_MCI)]];
counts = [counts; ["eeg_AD" nrow(eeg_AD)]];
counts = [counts; ["psg_AD" nrow(psg_AD)]];
counts = [counts; ["eeg_epifocal" nrow(eeg_epifocal)]];
counts = [counts; ["eeg_epigen" nrow(eeg_epigen)]];
counts = [counts; ["eeg_epiall" nrow(eeg_epiall)]];
counts = [counts; ["psg_NT1" nrow(psg_NT1)]];
counts = [counts; ["psg_NT2" nrow(psg_NT2)]];
counts = [counts; ["eeg_PD" nrow(eeg_PD)]];
counts = [counts; ["psg_PD" nrow(psg_PD)]];
counts = [counts; ["eeg_schiz" nrow(eeg_schiz)]];
counts = [counts; ["psg_schiz" nrow(psg_schiz)]];
counts = [counts; ["eeg_psychos" nrow(eeg_psychosis)]];
counts = [counts; ["psg_psychosis" nrow(psg_psychosis)]];
counts = [counts; ["eeg_mania" nrow(eeg_mania)]];
counts = [counts; ["psg_mania" nrow(psg_mania)]];
counts = [counts; ["eeg_BP" nrow(eeg_BP)]];
counts = [counts; ["psg_BP" nrow(psg_BP)]];
counts = [counts; ["eeg_MDD" nrow(eeg_MDD)]];
counts = [counts; ["psg_MDD" nrow(psg_MDD)]];
counts = [counts; ["eeg_pain" nrow(eeg_pain)]];
counts = [counts; ["psg_pain" nrow(psg_pain)]];
counts = [counts; ["eeg_migraine" nrow(eeg_migraine)]];
counts = [counts; ["psg_migraine" nrow(psg_migraine)]];


