#This uses the saved version of IEDDA table with demographics added
using Arrow, AWSS3, DataFrames

path = S3Path("s3://beacon-sandbox/bizops-clinops/IEDDA/summer_2022_demographic_paper/iedda_subjects_with_demographics.arrow")

IEDDA = DataFrame(Arrow.Table(path); copycols=true);

# count the unique racial types
#note: there are some duplicate subjects in the IEDDA table. the results below are study level.


function countDF(df::DataFrame)
  return size(df)[1]
end

#counts for the spikes dataset
races = unique(dropmissing(IEDDA,:race),:race);
raceCounts_MGHSPIKES = ["race" "count"];
for r in eachrow(races)
  temp = countDF(subset(filter(:race=>d->d==r.race,dropmissing(IEDDA,:race)),:dataset=>ByRow(isequal(:mgh_spikes))));
  raceCounts_MGHSPIKES = vcat(raceCounts_MGHSPIKES,[r.race temp]);
end

#counts for the controls dataset
raceCounts_MGHCONTROLS = ["race" "count"];
for r in eachrow(races)
  temp = countDF(subset(filter(:race=>d->d==r.race,dropmissing(IEDDA,:race)),:dataset=>ByRow(isequal(:mgh_controls))));
  raceCounts_MGHCONTROLS = vcat(raceCounts_MGHCONTROLS,[r.race temp]);
end

#counts for the test split
raceCounts_TEST = ["race" "count"];
for r in eachrow(races)
  temp = countDF(subset(filter(:race=>d->d==r.race,dropmissing(IEDDA,:race)),:split=>ByRow(isequal(:test))));
  raceCounts_TEST = vcat(raceCounts_TEST,[r.race temp]);
end


#
#write back to S3
#path = S3Path("s3://beacon-sandbox/bizops-clinops/IEDDA/summer_2022_demographic_paper/iedda_subjects_with_demographics.arrow")
#Arrow.write(path, IEDDA)
