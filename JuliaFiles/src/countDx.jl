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
temp3 = antijoin(MCI,AD,on=:subject)

psg_MCI_subjects = testType(temp1,"psg");
eeg_MCI_subjects = testType(temp1,"eeg");

psg_AD_subjects = testType(temp2,"psg");
#psg_AD_psg_recordings = unique(filter(:test_type => contains(r"psg"i),dropmissing(AD,:test_type)),:recording;view=true);
eeg_AD_subjects = testType(temp2,"eeg");
#AD_eeg_recordings = unique(filter(:test_type => contains(r"eeg"i),dropmissing(AD,:test_type)),:recording;view=true);

psg_MCInotAD_subjects = testType(temp3,"psg");
#psg_MCInotAD_psg_recordings = unique(filter(:test_type => contains(r"psg"i),dropmissing(MCInotAD,:test_type)),:recording;view=true);
eeg_MCInotAD_subjects = testType(temp1,"psg");
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

temp1 =  searchByICDcode("g40");
eeg_epigen =  testType(temp1,"eeg");

temp1 =  searchByICDcode("g20");
eeg_PD =  testType(temp1,"eeg");

temp1 =  searchByICDcode("f20");
eeg_schiz =  testType(temp1,"eeg");

temp1 =  searchByICDcode(["F28","F29"]);
eeg_psychosis =  testType(temp1,"eeg");

temp1 =  searchByICDcode("f31");
eeg_BP =  testType(temp1,"eeg");

temp1 =  searchByICDcode("f30");
eeg_mania =  testType(temp1,"eeg");

temp1 =  searchByICDcode("f33");
eeg_MDD =  testType(temp1,"eeg");

temp1 =  searchByICDcode(["R52","G89"]);
eeg_pain =  testType(temp1,"eeg");
psg_pain =  testType(temp1,"psg");

temp1 =  searchByICDcode("g43");
eeg_migraine =  testType(temp1,"eeg");
psg_migraine =  testType(temp1,"psg");
