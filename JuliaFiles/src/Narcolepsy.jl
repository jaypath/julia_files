#count narcolepsy by type

#G47.411 -> nt1
#G47.419 -> nt2

#use bizops utils to load icds and augmented_signals, available in this repo as well

#icds = useICD();

icd_narcolepsy_1 = filter(:code => contains(r"g47.411"i), icds)
icd_narcolepsy_2 = filter(:code => contains(r"g47.419"i), icds)

recs_narco_1 = semijoin(augmented_signals,icd_narcolepsy_1; on=:subject)
recs_narco_2 = semijoin(augmented_signals,icd_narcolepsy_2; on=:subject)

recs_narco_1 = unique(filter(:test_type => d -> contains(lowercase(d),"psg"),dropmissing(recs_narco_1,:test_type)),:recording)
recs_narco_2 = unique(filter(:test_type => d -> contains(lowercase(d),"psg"),dropmissing(recs_narco_2,:test_type)),:recording)

subj_narco_1 = unique(recs_narco_1,:subject)
subj_narco_2 = unique(recs_narco_2,:subject)

#who has epstein sleepiness?
hasESS = [];

for NT1row in eachrow(subj_narco_1)
  tempESS = false;
  NT1reps = filter(:mgh_pseudo_medical_record_number=>d->isequal(d, NT1row.pMRN),dropmissing(reports,:mgh_pseudo_medical_record_number));
  if nrow(NT1reps) >0
    for row in eachrow(NT1reps)
      if ismissing(row.epworth_sleepiness_scale)==false 
        tempESS=true
      end    
    end
  else
    tempESS=false
  end
  hasESS = [hasESS tempESS];
end

subj_narco_1.ESS = hasESS;
