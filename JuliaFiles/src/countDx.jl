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

MCI = countByICD("mild cognitive impairment");
AD = countByICD("alzheimer");
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
