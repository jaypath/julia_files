#run datautils first to generate augmented_signals

using Arrow, AWSS3, DataFrames

path = S3Path("s3://beacon-sandbox/bizops-clinops/IEDDA/summer_2022_demographic_paper/iedda_subjects.arrow")

IEDDA = DataFrame(Arrow.Table(path); copycols=true);

temp = [];

function countDF(df::DataFrame)
  return size(df)[1]
end

for r in eachrow(IEDDA)
  pMRN = searchAugmentedSignalsBySubject(r.subject);
  if countDF(pMRN) == 0
    temp = vcat(temp,missing);  
  else
    temp = vcat(temp,pMRN.pMRN[1]);
  end
end

IEDDA.pMRN = temp;


#now add demographics to IEDDA table
temp = [];
for r in eachrow(IEDDA)
  if ismissing(r.pMRN)
    temp = vcat(temp,missing);
  else
    pMRN = filter(:pMRN => d -> d==r.pMRN,demographics);
    if countDF(pMRN) == 0
      temp = vcat(temp,missing);
    else
      temp = vcat(temp,pMRN.PatientRaceDSC[1]);
    end
  end 
end
IEDDA.race = temp;

#now count the unique racial types
#note: there are some duplicate subjects in the IEDDA table. the results below are study level.
races = unique(dropmissing(IEDDA,:race),:race);
raceCounts = ["race" "count"];
for r in eachrow(races)
  temp = countDF(filter(:race=>d->d==r.race,dropmissing(IEDDA,:race)));
  raceCounts = vcat(raceCounts,[r.race temp]);
end


#
#write back to S3
#path = S3Path("s3://beacon-sandbox/bizops-clinops/IEDDA/summer_2022_demographic_paper/iedda_subjects_with_demographics.arrow")
#Arrow.write(path, IEDDA)
