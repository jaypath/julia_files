#this file loads subjects, recordings, ICDs (optional), and signals tables

using DataFrames, DataMapUtils, Mgh2019Utils, AWSS3, BOME, Dates

recordings = Mgh2019Utils.load(; schema="bome.recording@1");
persons = Mgh2019Utils.load(; schema="bome.person@1");

#old method, looks for annotations that indicate a recording is a PSG
#psg_annots = Mgh2019Utils.load(; name="all.mgh-2019.psg.bome.onda.annotations")
#psg_recs = semijoin(recordings, psg_annots; on=:id => :recording)

#this method uses MGH_TEST_TYPE
#recs_psg = filter(:mgh_test_type => contains(r"psg"i), dropmissing(recordings,:mgh_test_type));
#recs_eeg = filter(:mgh_test_type => contains(r"eeg"i),dropmissing(recordings,:mgh_test_type));


#this section is to load signals table... note to self, ask someone if there is a utils function for this instead
const MGH_ROOT = S3Path("s3://beacon-curated-datasets/onda/mgh-2019/")
read_with(reader, path::S3Path) = DataFrame(reader(path); copycols=true)
read_with(reader, file::AbstractString) = read_with(reader, joinpath(MGH_ROOT, file))


#function to count recordings by ICD term
function useICD()
  return Mgh2019Utils.load(; schema="bome.icd-code@1");
  
end

function useReports()
  return Mgh2019Utils.load(; schema="bome.report@1");
end

  function countByICD(searchstring)
           icd_term = filter(:diagnosis => d -> contains(lowercase(d),lowercase(searchstring)), icds)
           matches = semijoin(augmented_signals, icd_term; on=:subject)
           return matches;
  end

function searchReports(searchstring)
    return filter(:report_text => contains(searchstring),dropmissing(reports,:report_text));
end

function reportBySubject(subject)
      return filter(:subject_id => d -> d == subject,dropmissing(reports,:subject_id));
end

function searchAugmentedSignalsBySubject(subID)
    return filter(:subject => contains(subID),dropmissing(augmented_signals,:subject));
end

# MGH-2019 augmented signals table
# Prepares a `augmented_signals` that contains matches the signals with ages and subjects
function prepare_augmented_signals()
    p = select(persons, :id => :subject,
               :birth => ByRow(passmissing(d -> d.date)) => :birth)
    r = select(recordings, :subject, :id => :recording, :subject_age => :age, :mgh_test_type => :test_type,
               :start => ByRow(passmissing(d -> d.date)) => :start)

    # Only contains signals that have been ingested onto S3
    # If the recording's signals are not ingested, then it won't have associated signals in the signals table
    # Thus that recording will not be present in `all_info_df` after the innerjoin
    augmented_signals = innerjoin(p, r; on=:subject)
    augmented_signals = innerjoin(augmented_signals, signals; on=:recording)

    # Prepare ages
    # Credit to Alex Arslan: https://github.com/beacon-biosignals/braingler/pull/332/files
    transform!(augmented_signals,
               [:age, :birth, :start] => ByRow() do age, birth, start
                   # Trust existing age over computing based on dates
                   if !ismissing(age)
                       h = coalesce(age.hours, 0)
                       d = coalesce(age.days, 0)
                       y = coalesce(age.years, 0)
                       return y * 365 + d + round(Int, h / 24)
                   elseif ismissing(birth) || ismissing(start)
                       return missing
                   else
                       return Dates.value(start - birth)
                   end
               end => :age_in_days)
    transform!(augmented_signals,
               :age_in_days => ByRow(passmissing(d -> d / 365.25)) => :age_in_years)
    select!(augmented_signals, Symbol.(names(signals))..., :subject, :age_in_years, :birth,
            :start, :age, :test_type)

    return augmented_signals
end

signals = read_with(read_bome_table, "all.mgh-2019.onda.signals.arrow")

# Tables derived from MGH 2019
augmented_signals = prepare_augmented_signals();
