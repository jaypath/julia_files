##### 
##### Compute periodograms and spectral power for 
##### CAR-T SpotLite data and save
#####

using AWSS3
using BOME
using DataFrames
using Dates
using EEGFeatures
using Legolas
using Montages
using Onda
using OndaDSP
using Statistics
using TimeSpans
using UUIDs

PGRAM_DUR = Minute(1)
SAMPLE_RATE_HZ = 200
mt_config = MTConfig{Float64}(PGRAM_DUR; fs=SAMPLE_RATE_HZ)

include("utils.jl")

function preprocess(samples; sample_rate_hz = SAMPLE_RATE_HZ)
    samples = OndaDSP.downsample(samples, sample_rate_hz)
    samples = notch_filter(samples, 60Hz)
    samples = highpass_filter(samples, 0.5Hz)
    return average_montage(samples)
end

# compute periodograms for all channels, and left / right channels
function pgrams(samples, mt_config)
    pgram = mt_pgram(samples, mt_config)
    average_pgram = mean(pgram; dims=:channel)
    left_pgram = mean(pgram(channel=left_average_spotlite().montage); dims=:channel)
    right_pgram = mean(pgram(channel=right_average_spotlite().montage); dims=:channel)
    return (; average_pgram, left_pgram, right_pgram)
end

function get_subject_id(file_path)
    file_name = split(split(file_path, "/")[end], "_")
    id = (file_name[1] == "CART" && length(file_name[2]) == 3) ? file_name[2] :
         !isnothing(match(r"CART\d\d\d", file_name[1])) ? file_name[1][5:7] :
         missing
    return id 
end

function get_date(file_path)
    file_name = split(split(file_path, "/")[end], "_")
    date = file_name[end-1]
    return Date(date, DateFormat("yyyymmdd"))
end

function read_cart_signals()
    # subjects and recordings of interest defined by Jay:
    # https://github.com/beacon-biosignals/GrantsAndPapers/blob/main/CAR-T/TrialData.md
    control_ids = ["001", "002", "104"]
    enceph_ids = ["004", "005", "103"]
    useful_recs_005 = [UUID("2985da88-acac-4eae-9f02-665a202f1c93"),
                    UUID("4fd957ff-088e-4e11-889c-f9003fbf9730")]
    # Michelle found that this recording was all noise after reviewing in the portal
    unusable_recs_002 = [UUID("3d44d6bc-4cf6-4cba-a01a-d8557c374f65")] 
    signals = read_dataframe(joinpath(CART_PATH,
                                  "MGH-CART-trial-data-signals.arrow"))
    transform!(signals, :file_path => ByRow(get_subject_id) => :subject)
    dropmissing!(signals, :subject)
    subset!(signals, :subject => ByRow(s -> in(s, control_ids) || in(s, enceph_ids)))
    subset!(signals, [:recording, :subject] => ByRow((r, s) -> 
                                                     ((s != "005") || (in(r, useful_recs_005)))))
    subset!(signals, :recording => ByRow(r -> !in(r, unusable_recs_002)))
    transform!(signals, :file_path => ByRow(get_date) => :date)
    transform!(signals, :span => ByRow(x -> Dates.value(duration(x)) / 1e9 / 60) => :duration_minutes)
    # require at least 10 minutes of recording 
    subset!(signals, :duration_minutes => ByRow(>=(10)))
    transform!(signals, :file_path => ByRow(S3Path) => :file_path)
    return signals
end

function main()
    band_names=string.(keys(EEGFeatures.bands()))
    power_df = DataFrame(:recording => UUID[],
                        :span => TimeSpan[],
                        :band => String[],
                        :region => String[],
                        :value => Float64[])
    signals = read_cart_signals()
    Legolas.write_arrow(joinpath(SAVE_PATH, "cart.signals.arrow"), signals)
    for subject_signals in groupby(signals, :subject)
        @info "subject $(subject_signals[1,:subject])"
        # get at most first 3 and last 3 recordings per subject
        subj_signals = sort(subject_signals, :date)
        s_signals = subj_signals[first(subj_signals, 3), :] 
        if nrow(subj_signals) > 3
            append!(s_signals, last(subj_signals, 3))
        end
        unique!(s_signals)
        for (ax, s) in enumerate(eachrow(s_signals))
            @info "recording $ax of $(nrow(s_signals))"
            samples = preprocess(load(s))
            windows = EEGFeatures.chunk_into_timespans(duration(s.span), PGRAM_DUR, PGRAM_DUR)
            windows = map(x -> x, windows)
            windows = first(windows, 180) # max number of windows
            for w in windows
                avg_power, l_power, r_power = pgrams(view(samples, :, w), mt_config)
                a_vec = average_power_per_band(avg_power, EEGFeatures.bands())
                l_vec = average_power_per_band(l_power, EEGFeatures.bands())
                r_vec = average_power_per_band(r_power, EEGFeatures.bands())
                for r in 1:length(EEGFeatures.bands())
                    push!(power_df, (; s.recording, span=w, band=band_names[r], region="total",
                                    value=a_vec[r]))
                    push!(power_df, (; s.recording, span=w, band=band_names[r], region="left",
                                    value=l_vec[r]))
                    push!(power_df, (; s.recording, span=w, band=band_names[r], region="right",
                                    value=r_vec[r]))
                end
            end
        end
    end
    power_save_name = joinpath(SAVE_PATH, "cart.power.arrow")
    Legolas.write_arrow(power_save_name, power_df)
end
