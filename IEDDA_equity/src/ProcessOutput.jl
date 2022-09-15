#I have downloaded the files from aws s3 ls s3://beacon-sandbox/bizops-clinops/IEDDA/summer_2022_demographic_paper/predictions/ to my pet at julia_files/IEDDA_demographics
#load each arrow table, with fields as described here: https://github.com/beacon-biosignals/SpikeNet.jl/issues/1176#issuecomment-1248356980
#elected is human rating (as per the thresholding) - 1=spike 0 =no spike,  and predicted is the model rating
#characterize FP, FN, TP, TN for each case (test -> non-caucasian, validation -> caucasian)


using Arrow
function calc_stats(t1, tablein,modname)
tp=0
fp=0
tn=0
fn = 0

for i in 1:length(t1.predicted_IED)
  if t1.predicted_IED[i] == t1.elected_IED[i]
    if t1.predicted_IED[i] == 0
      tn=tn+1;
    else
      tp=tp+1;
    end
  else
    if t1.predicted_IED[i] > t1.elected_IED[i]
      fp=fp+1;
    else
      fn=fn+1;
    end
  end
  
end

Spec = tn / (tn+ fp)
Sens = tp/(tp+fn)
Accu = (tp + tn) / ((tp + fn) + (tn + fp)) #(TP + TN) / (P + N)
PPV = tp / (tp + fp)
NPV = tn / (fn + tn)
return [tablein;[Spec Sens Accu PPV NPV modname]];
end

stat_table = ["Sp" "Sn" "Acc" "PPV" "NPV" "label"];

t1 = Arrow.Table("/home/ubuntu/julia_files/IEDDA_demographics/experimental_test_predictions.arrow") #experimental model, test group
stat_table = calc_stats(t1,stat_table,"exp_test");

t1 = Arrow.Table("/home/ubuntu/julia_files/IEDDA_demographics/release_test_predictions.arrow") #release model, test group
stat_table = calc_stats(t1,stat_table,"release_test");

t1 = Arrow.Table("/home/ubuntu/julia_files/IEDDA_demographics/experimental_valid_predictions.arrow") #exp model, validation group (caucasian)
stat_table = calc_stats(t1,stat_table,"exp_valid");

t1 = Arrow.Table("/home/ubuntu/julia_files/IEDDA_demographics/release_valid_predictions.arrow") #release model, val group
stat_table = calc_stats(t1,stat_table,"release_valid");



