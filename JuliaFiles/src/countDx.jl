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


MCI = searchByICD("mild cognitive impairment");
AD = searchByICD("alzheimer");
MCInotAD = antijoin(MCI,AD,on=:subject)

MCI_psg_subjects = unique(filter(:test_type => contains(r"psg"i),dropmissing(MCI,:test_type)),:subject;view=true);
MCI_psg_recordings = unique(filter(:test_type => contains(r"psg"i),dropmissing(MCI,:test_type)),:recording;view=true);
MCI_eeg_subjects = unique(filter(:test_type => contains(r"eeg"i),dropmissing(MCI,:test_type)),:subject;view=true);
MCI_eeg_recordings = unique(filter(:test_type => contains(r"eeg"i),dropmissing(MCI,:test_type)),:recording;view=true);

AD_psg_subjects = unique(filter(:test_type => contains(r"psg"i),dropmissing(AD,:test_type)),:subject;view=true);
AD_psg_recordings = unique(filter(:test_type => contains(r"psg"i),dropmissing(AD,:test_type)),:recording;view=true);
AD_eeg_subjects = unique(filter(:test_type => contains(r"eeg"i),dropmissing(AD,:test_type)),:subject;view=true);
AD_eeg_recordings = unique(filter(:test_type => contains(r"eeg"i),dropmissing(AD,:test_type)),:recording;view=true);

MCInotAD_psg_subjects = unique(filter(:test_type => contains(r"psg"i),dropmissing(MCInotAD,:test_type)),:subject;view=true);
MCInotAD_psg_recordings = unique(filter(:test_type => contains(r"psg"i),dropmissing(MCInotAD,:test_type)),:recording;view=true);
MCInotAD_eeg_subjects = unique(filter(:test_type => contains(r"eeg"i),dropmissing(MCInotAD,:test_type)),:subject;view=true);
MCInotAD_eeg_recordings = unique(filter(:test_type => contains(r"eeg"i),dropmissing(MCInotAD,:test_type)),:recording;view=true);

NT1 = searchByICDcode("g47.411")
NT2 = searchByICDcode("g47.419")

epilepsy_focal =  searchByICDcode(["g40.1","g40.2"]);
epilepsy_gen =  searchByICDcode("g40.3");
epilepsy_all =  searchByICDcode("g40");

parkinsons =  searchByICDcode("g20");
schizophrenia =  searchByICDcode("F20");
psychosis = searchByICDcode(["F28","F29"]);
bipolar =  searchByICDcode("F31");
mania =  searchByICDcode("F30");
depression =  searchByICDcode("F33");
pain = searchByICDcode(["R52","G89"]);
migraine = searchByICDcode("G43");
