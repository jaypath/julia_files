#count schizophrenia subjects in MGH with PSG data
#n
#sex
#age (distribution)
#comorbidities (counts)


using DataFrames, DataMapUtils, Mgh2019Utils, AWSS3, BOME, Dates, AWS, Scratch

recordings = Mgh2019Utils.load(; schema="bome.recording@1");
persons = Mgh2019Utils.load(; schema="bome.person@1");

#signals
const MGH_ROOT = S3Path("s3://beacon-curated-datasets/onda/mgh-2019/")
read_with(reader, path::S3Path) = DataFrame(reader(path); copycols=true)
read_with(reader, file::AbstractString) = read_with(reader, joinpath(MGH_ROOT, file))
  
#ICD table
function useICD()
  return Mgh2019Utils.load(; schema="bome.icd-code@1");
  
end

function searchByICD(searchstring)
  icd_term = filter(:diagnosis => d -> contains(lowercase(d),lowercase(searchstring)), icds)
  matches = semijoin(augmented_signals, icd_term; on=:subject)
  return matches;
end

#medications info
const MEDICATIONS_ARROW_TABLE_ORIGIN = "s3://project-jasper-sandbox/eph-sandbox/all_meds_data.arrow"

const MEDICATIONS_ARROW_TABLE_PATH = joinpath(@get_scratch!("MGH2019-medications"), "jasper-eph-sandbox-all-meds-data.arrow")

function load_in_meds()
    # File is pretty large. I had trouble loading it directly from S3
    # Copying it to local disk seems to work better
    if !isfile(MEDICATIONS_ARROW_TABLE_PATH)
        run(addenv(`aws s3 cp $(MEDICATIONS_ARROW_TABLE_ORIGIN) $(MEDICATIONS_ARROW_TABLE_PATH)`,
                   "AWS_PROFILE" => "bizops-clinops"))
    end
    return MEDICATIONS_ARROW_TABLE_PATH
end

function get_subjects_matching_meds(meds_string::AbstractString)
    check_medication = x -> occursin(uppercase(meds_string), x)
    df = subset(medications, :MedicationDSC => ByRow(check_medication))

    df = innerjoin(df, augmented_signals; on= [:pMRN => :pseudomrn],
                   matchmissing=:notequal)

    return unique(df.subject)
end

function get_meds_matching_subjects(df)
  #df is be the dataframe of selected pts
    df = innerjoin(medications,df, on= [:pMRN => :pseudomrn], matchmissing=:notequal)
    return df
end

#signals and recordings union

function searchAugmentedSignalsBySubject(subID)
    return filter(:subject => contains(subID),dropmissing(augmented_signals,:subject));
end

# MGH-2019 augmented signals table
# Prepares a `augmented_signals` that contains matches the signals with ages and subjects
function prepare_augmented_signals()
    p = select(persons, :id => :subject,
               :birth => ByRow(passmissing(d -> d.date)) => :birth)
    r = select(recordings, :subject, :mgh_pseudo_medical_record_number => :pseudomrn, :id => :recording, :subject_age => :age, :mgh_test_type => :test_type,
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



#----- end of functions, data processing below here
signals = read_with(read_bome_table, "all.mgh-2019.onda.signals.arrow")

# Tables derived from MGH 2019
augmented_signals = prepare_augmented_signals();

medications = let
    # Medications is very large table. `copycols=false` helps to reduce memory usage
    df = DataFrame(Arrow.Table(load_in_meds()); copycols=false)
    select!(df, :OrderInstantDTS, :MedicationDSC, :pMRN)
    clean_df = dropmissing(df, [:MedicationDSC, :pMRN]) # Bare-minimum columns
    # Set `:MedicationDSC` column to uppercase to help with matching descriptions
    # Note: this is out-of-place so that `medications` can be used properly
    transform(clean_df, :MedicationDSC => ByRow(uppercase) => :MedicationDSC)
end

icds = useICD();

#search schizophrenia by text
schiz = unique(searchByICD("schizophrenia"),:subject);
schiz_with_meds = get_meds_matching_subjects(schiz)
